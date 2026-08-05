import '../models/activity_item.dart';
import '../models/chat_message.dart';
import '../models/person.dart';

/// The single seam between the UI and any backend.
/// Implement this against your service and swap it in main.dart.
abstract class GlancesApi {
  /// People currently within [rangeMeters] line of sight.
  Future<List<Person>> peopleInSight({required int rangeMeters});

  /// Two candidates for the pick-one-of-two round.
  Future<List<Person>> pickPair({required int withinMinutes});

  /// Returns true when the like is mutual.
  Future<bool> like(String personId);

  Future<void> pass(String personId);

  Future<List<ActivityItem>> activity();

  Future<List<ChatMessage>> messages(String personId);

  Future<void> send(String personId, String text);

  Future<void> setVisible(bool visible);
}

class MockApi implements GlancesApi {
  MockApi(this._people);

  final List<Person> _people;
  final Map<String, List<ChatMessage>> _threads = {};

  @override
  Future<List<Person>> peopleInSight({required int rangeMeters}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _people.where((p) => p.distanceMeters <= rangeMeters * 40).toList();
  }

  @override
  Future<List<Person>> pickPair({required int withinMinutes}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _people.take(2).toList();
  }

  @override
  Future<bool> like(String personId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return true; // mock: always mutual, so the match screen is reachable
  }

  @override
  Future<void> pass(String personId) async {}

  @override
  Future<List<ActivityItem>> activity() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const [
      ActivityItem(
        personId: 'sima',
        kind: ActivityKind.likedYou,
        title: 'Sima liked you back',
        subtitle: 'Say something - she is 800 m away',
        timeLabel: '2 m',
        unread: true,
      ),
      ActivityItem(
        personId: 'loren',
        kind: ActivityKind.message,
        title: 'New message from Loren',
        subtitle: 'So that was you at the counter?',
        timeLabel: '18 m',
        unread: true,
      ),
      ActivityItem(
        personId: 'maria',
        kind: ActivityKind.youLiked,
        title: 'You liked Maria',
        subtitle: 'Waiting to see if she looks back',
        timeLabel: '1 h',
        unread: false,
      ),
      ActivityItem(
        personId: 'dana',
        kind: ActivityKind.likedYou,
        title: 'Dana liked you back',
        subtitle: 'Chat expires in 5 days',
        timeLabel: 'Mon',
        unread: false,
      ),
    ];
  }

  @override
  Future<List<ChatMessage>> messages(String personId) async {
    return _threads.putIfAbsent(personId, () {
      final now = DateTime.now();
      return [
        ChatMessage(text: 'So that was you at the counter?', mine: false, sentAt: now),
        ChatMessage(text: 'Guilty. I looked twice.', mine: true, sentAt: now),
        ChatMessage(text: 'I am still here for ten more minutes', mine: false, sentAt: now),
      ];
    });
  }

  @override
  Future<void> send(String personId, String text) async {
    final thread = await messages(personId);
    thread.add(ChatMessage(text: text, mine: true, sentAt: DateTime.now()));
  }

  @override
  Future<void> setVisible(bool visible) async {}
}
