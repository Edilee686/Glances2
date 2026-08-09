import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/activity_item.dart';
import '../models/chat_message.dart';
import '../models/person.dart';
import 'api.dart';
import 'store.dart';

/// A real, working backend that happens to run on the phone.
/// Likes, matches, threads and activity all persist across restarts.
/// Swap this for a network implementation of [GlancesApi] when the server exists.
class LocalApi extends ChangeNotifier implements GlancesApi {
  LocalApi(this._store, this._people) {
    liked = _store.readList('liked').toSet();
    passed = _store.readList('passed').toSet();
    matched = _store.readList('matched').toSet();
    blocked = _store.readList('blocked').toSet();
    _visible = _store.read<bool>('visible') ?? true;

    final threads = _store.readMap('threads');
    for (final entry in threads.entries) {
      _threads[entry.key] = (entry.value as List<dynamic>)
          .map((m) => ChatMessage(
                text: m['text'] as String,
                mine: m['mine'] as bool,
                sentAt: DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
              ))
          .toList();
    }
    _events = _store
        .readMap('events')
        .entries
        .map((e) => _Event.fromJson(Map<String, dynamic>.from(e.value as Map)))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
  }

  final Store _store;
  final List<Person> _people;

  late Set<String> liked;
  late Set<String> passed;
  late Set<String> matched;
  late Set<String> blocked;
  bool _visible = true;

  final Map<String, List<ChatMessage>> _threads = {};
  List<_Event> _events = [];
  final Map<String, Timer> _pendingReplies = {};

  bool get visible => _visible;
  int get unreadCount => _events.where((e) => e.unread).length;
  List<String> get matchIds => matched.toList();

  Person? person(String id) => _people.where((p) => p.id == id).firstOrNull;

  /// Deterministic per person, so a like never flips its answer between runs.
  bool _wouldLikeBack(String id) => id.hashCode.abs() % 100 < 58;

  @override
  Future<List<Person>> peopleInSight({required int rangeMeters}) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    return _people
        .where((p) =>
            p.distanceMeters <= rangeMeters && !passed.contains(p.id) && !blocked.contains(p.id))
        .toList();
  }

  @override
  Future<List<Person>> pickPair({required int withinMinutes}) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    final pool = _people
        .where((p) =>
            p.secondsAgo <= withinMinutes * 60 &&
            !passed.contains(p.id) &&
            !liked.contains(p.id) &&
            !blocked.contains(p.id))
        .toList();
    return pool.take(2).toList();
  }

  @override
  Future<bool> like(String personId) async {
    await Future<void>.delayed(const Duration(milliseconds: 90));
    liked.add(personId);
    final name = person(personId)?.name ?? 'They';
    final mutual = _wouldLikeBack(personId);

    if (mutual) {
      matched.add(personId);
      _addEvent(_Event(
        personId: personId,
        kind: ActivityKind.likedYou,
        title: name + ' liked you back',
        subtitle: 'Say something while you are both still nearby',
        at: DateTime.now(),
        unread: true,
      ));
    } else {
      _addEvent(_Event(
        personId: personId,
        kind: ActivityKind.youLiked,
        title: 'You liked ' + name,
        subtitle: 'Waiting to see if they look back',
        at: DateTime.now(),
        unread: false,
      ));
    }
    _persist();
    notifyListeners();
    return mutual;
  }

  @override
  Future<void> pass(String personId) async {
    passed.add(personId);
    _events.removeWhere((e) => e.personId == personId && e.kind == ActivityKind.youLiked);
    _persist();
    notifyListeners();
  }

  void block(String personId) {
    blocked.add(personId);
    matched.remove(personId);
    liked.remove(personId);
    _threads.remove(personId);
    _events.removeWhere((e) => e.personId == personId);
    _persist();
    notifyListeners();
  }

  void dismissEvent(String personId, ActivityKind kind) {
    _events.removeWhere((e) => e.personId == personId && e.kind == kind);
    _persist();
    notifyListeners();
  }

  void markRead(String personId) {
    var changed = false;
    for (var i = 0; i < _events.length; i++) {
      if (_events[i].personId == personId && _events[i].unread) {
        _events[i] = _events[i].copyWith(unread: false);
        changed = true;
      }
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  @override
  Future<List<ActivityItem>> activity() async {
    _promotePendingLikes();
    return _events
        .map((e) => ActivityItem(
              personId: e.personId,
              kind: e.kind,
              title: e.title,
              subtitle: e.subtitle,
              timeLabel: _ago(e.at),
              unread: e.unread,
            ))
        .toList();
  }

  /// A like with no answer turns into a match — or quietly expires — after a while.
  /// This is what makes the app feel like something is happening on the other side.
  void _promotePendingLikes() {
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < _events.length; i++) {
      final e = _events[i];
      if (e.kind != ActivityKind.youLiked) continue;
      if (now.difference(e.at).inSeconds < 30) continue;
      if (!_wouldLikeBack(e.personId + 'delayed')) continue;
      final name = person(e.personId)?.name ?? 'They';
      matched.add(e.personId);
      _events[i] = _Event(
        personId: e.personId,
        kind: ActivityKind.likedYou,
        title: name + ' liked you back',
        subtitle: 'Mutual glance - say something',
        at: now,
        unread: true,
      );
      changed = true;
    }
    if (changed) {
      _events.sort((a, b) => b.at.compareTo(a.at));
      _persist();
      Future.microtask(notifyListeners);
    }
  }

  @override
  Future<List<ChatMessage>> messages(String personId) async {
    return _threads.putIfAbsent(personId, () {
      final opener = _openers[personId.hashCode.abs() % _openers.length];
      final thread = [
        ChatMessage(text: opener, mine: false, sentAt: DateTime.now()),
      ];
      _persist();
      return thread;
    });
  }

  @override
  Future<void> send(String personId, String text) async {
    final thread = await messages(personId);
    thread.add(ChatMessage(text: text, mine: true, sentAt: DateTime.now()));
    _persist();
    notifyListeners();
    _scheduleReply(personId);
  }

  void _scheduleReply(String personId) {
    _pendingReplies[personId]?.cancel();
    final delay = Duration(milliseconds: 1400 + Random().nextInt(2200));
    _pendingReplies[personId] = Timer(delay, () {
      final thread = _threads[personId];
      if (thread == null) return;
      final reply = _replies[thread.length % _replies.length];
      thread.add(ChatMessage(text: reply, mine: false, sentAt: DateTime.now()));
      final name = person(personId)?.name ?? 'They';
      _addEvent(_Event(
        personId: personId,
        kind: ActivityKind.message,
        title: 'New message from ' + name,
        subtitle: reply,
        at: DateTime.now(),
        unread: true,
      ));
      _persist();
      notifyListeners();
    });
  }

  @override
  Future<void> setVisible(bool visible) async {
    _visible = visible;
    _store.write('visible', visible);
  }

  void _addEvent(_Event event) {
    _events.removeWhere((e) => e.personId == event.personId && e.kind == event.kind);
    _events.insert(0, event);
    if (_events.length > 40) _events.removeRange(40, _events.length);
  }

  void _persist() {
    _store.writeAll({
      'liked': liked.toList(),
      'passed': passed.toList(),
      'matched': matched.toList(),
      'blocked': blocked.toList(),
      'threads': {
        for (final entry in _threads.entries)
          entry.key: entry.value
              .map((m) => {'text': m.text, 'mine': m.mine, 'at': m.sentAt.millisecondsSinceEpoch})
              .toList(),
      },
      'events': {
        for (var i = 0; i < _events.length; i++) i.toString(): _events[i].toJson(),
      },
    });
  }

  @override
  void dispose() {
    for (final timer in _pendingReplies.values) {
      timer.cancel();
    }
    super.dispose();
  }

  static String _ago(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 60) return 'now';
    if (d.inMinutes < 60) return d.inMinutes.toString() + ' m';
    if (d.inHours < 24) return d.inHours.toString() + ' h';
    return d.inDays.toString() + ' d';
  }

  static const _openers = [
    'So that was you at the counter?',
    'You looked. I looked. Here we are.',
    'Was that you by the window just now?',
    'Bold of us both, honestly.',
    'Hi - still around the corner if you are.',
    'Caught you looking.',
  ];

  static const _replies = [
    'Guilty. I looked twice.',
    'I am still here for another ten minutes.',
    'Ha - what gave me away?',
    'Coffee is on you then.',
    'You are closer than I thought.',
    'Tell me something true.',
  ];
}

class _Event {
  _Event({
    required this.personId,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
    required this.unread,
  });

  factory _Event.fromJson(Map<String, dynamic> j) => _Event(
        personId: j['personId'] as String,
        kind: ActivityKind.values[j['kind'] as int],
        title: j['title'] as String,
        subtitle: j['subtitle'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        unread: j['unread'] as bool,
      );

  final String personId;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final DateTime at;
  final bool unread;

  _Event copyWith({bool? unread}) => _Event(
        personId: personId,
        kind: kind,
        title: title,
        subtitle: subtitle,
        at: at,
        unread: unread ?? this.unread,
      );

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'kind': kind.index,
        'title': title,
        'subtitle': subtitle,
        'at': at.millisecondsSinceEpoch,
        'unread': unread,
      };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
