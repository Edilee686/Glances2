import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth.dart';
import '../services/db.dart';

enum SightMode { inSight, likesAndMessages }

/// Single source of truth. Reads and writes go to the database; the UI listens.
class AppState extends ChangeNotifier {
  AppState({required this.db, required this.auth});

  final GlancesDb db;
  final Auth auth;

  Profile? me;
  List<Profile> nearby = [];
  List<Profile> recent = [];
  List<Profile> matches = [];
  List<LikeRow> likeFeed = [];
  int unread = 0;

  SightMode mode = SightMode.inSight;
  int rangeMeters = 20;
  int withinMinutes = 30;
  int carouselIndex = 0;
  String? activeId;
  bool loading = true;
  bool plus = false;

  Timer? _ticker;

  Profile? get active {
    final id = activeId;
    if (id == null) return null;
    for (final p in [...nearby, ...recent, ...matches]) {
      if (p.id == id) return p;
    }
    return null;
  }

  Profile? get focused {
    if (nearby.isEmpty) return null;
    return nearby[carouselIndex.clamp(0, nearby.length - 1)];
  }

  Future<void> boot() async {
    final accountId = auth.accountId;
    if (accountId == null) {
      loading = false;
      notifyListeners();
      return;
    }
    me = await db.selfProfile(accountId);
    plus = (await db.setting('plus')) == '1';
    rangeMeters = int.tryParse(await db.setting('range') ?? '') ?? 20;
    withinMinutes = int.tryParse(await db.setting('minutes') ?? '') ?? 30;
    await refresh();
    _ticker ??= Timer.periodic(const Duration(seconds: 20), (_) => _tick());
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final self = me;
    if (self == null) return;
    nearby = await db.inSight(viewerId: self.id, rangeMeters: rangeMeters);
    recent = await db.recentlySeen(viewerId: self.id, withinMinutes: withinMinutes);
    matches = await db.matchesFor(self.id);
    likeFeed = await db.likeFeed(self.id);
    unread = await db.unreadCount(self.id);
    if (carouselIndex >= nearby.length) carouselIndex = nearby.isEmpty ? 0 : nearby.length - 1;
    notifyListeners();
  }

  /// The world moves on its own: unanswered likes get answered, and people
  /// you have matched with occasionally write first.
  Future<void> _tick() async {
    final self = me;
    if (self == null) return;
    var changed = false;

    for (final row in likeFeed.where((l) => l.outgoing)) {
      if (DateTime.now().difference(row.at) < const Duration(seconds: 25)) continue;
      if (await db.isMatched(self.id, row.otherId)) continue;
      if (!_likesBack(row.otherId)) continue;
      await db.setLike(row.otherId, self.id, 'liked_you');
      await db.createMatch(self.id, row.otherId, window: const Duration(hours: 24));
      changed = true;
    }

    for (final other in matches) {
      final last = await db.lastMessage(self.id, other.id);
      if (last == null) {
        await db.addMessage(self.id, other.id, other.id, _opener(other.id));
        changed = true;
      } else if (last.authorId == self.id &&
          DateTime.now().difference(last.sentAt) > const Duration(seconds: 4)) {
        await db.addMessage(self.id, other.id, other.id, _reply(other.id, last.id));
        changed = true;
      }
    }

    if (changed) await refresh();
  }

  bool _likesBack(String id) => id.hashCode.abs() % 100 < 62;

  String _opener(String id) => _openers[id.hashCode.abs() % _openers.length];

  String _reply(String id, int salt) => _replies[(id.hashCode.abs() + salt) % _replies.length];

  // ---- actions ------------------------------------------------------------

  /// Returns true when the like was mutual.
  Future<bool> like(String otherId) async {
    final self = me;
    if (self == null) return false;
    await db.setLike(self.id, otherId, 'like');
    final mutual = _likesBack(otherId);
    if (mutual) {
      await db.setLike(otherId, self.id, 'liked_you');
      await db.createMatch(self.id, otherId, window: const Duration(hours: 24));
    }
    activeId = otherId;
    await refresh();
    return mutual;
  }

  Future<void> pass(String otherId) async {
    final self = me;
    if (self == null) return;
    await db.setLike(self.id, otherId, 'pass');
    await refresh();
  }

  Future<void> block(String otherId) async {
    final self = me;
    if (self == null) return;
    await db.setLike(self.id, otherId, 'block');
    await db.removeMatch(self.id, otherId);
    await refresh();
  }

  Future<void> send(String otherId, String body) async {
    final self = me;
    if (self == null || body.trim().isEmpty) return;
    await db.addMessage(self.id, otherId, self.id, body.trim());
    await refresh();
    Future<void>.delayed(Duration(milliseconds: 1200 + Random().nextInt(1600)), () async {
      final last = await db.lastMessage(self.id, otherId);
      if (last == null || last.authorId != self.id) return;
      await db.addMessage(self.id, otherId, otherId, _reply(otherId, last.id));
      await refresh();
    });
  }

  Future<void> markRead(String otherId) async {
    final self = me;
    if (self == null) return;
    await db.markThreadRead(self.id, otherId, self.id);
    await refresh();
  }

  Future<void> updateMe(Map<String, Object?> values) async {
    final self = me;
    if (self == null) return;
    await db.updateProfile(self.id, values);
    me = await db.profile(self.id);
    notifyListeners();
  }

  Future<void> reloadMe() async {
    final accountId = auth.accountId;
    if (accountId == null) return;
    me = await db.selfProfile(accountId);
    notifyListeners();
  }

  void setMode(SightMode value) {
    mode = value;
    notifyListeners();
  }

  Future<void> setRange(int meters) async {
    rangeMeters = meters.clamp(5, 20);
    await db.putSetting('range', rangeMeters.toString());
    await refresh();
  }

  Future<void> setMinutes(int minutes) async {
    withinMinutes = minutes.clamp(1, 30);
    await db.putSetting('minutes', withinMinutes.toString());
    await refresh();
  }

  void setCarousel(int index) {
    if (carouselIndex == index) return;
    carouselIndex = index;
    notifyListeners();
  }

  void open(String id) {
    activeId = id;
    notifyListeners();
  }

  Future<void> buyPlus() async {
    plus = true;
    await db.putSetting('plus', '1');
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _reset();
  }

  Future<void> deleteAccount() async {
    await auth.deleteAccount();
    _reset();
  }

  void _reset() {
    me = null;
    nearby = [];
    recent = [];
    matches = [];
    likeFeed = [];
    unread = 0;
    activeId = null;
    carouselIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static const _openers = [
    'Hey, how are you? :)',
    'So that was you by the window?',
    'You looked. I looked. Here we are.',
    'Caught you looking..',
    'Hi - still around the corner if you are.',
  ];

  static const _replies = [
    'Oh, it\'s very flattering..\nYou\'re cute too!',
    'Great idea.. :)',
    'Guilty. I looked twice.',
    'I am still here for another ten minutes.',
    'Coffee is on you then.',
    'Tell me something true.',
  ];
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }

  /// Same lookup without registering a dependency - safe inside initState.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }
}
