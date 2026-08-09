import 'package:flutter/material.dart';

import '../data/mock_people.dart';
import '../models/activity_item.dart';
import '../models/person.dart';
import '../services/local_api.dart';
import '../services/store.dart';

enum SightMode { inSight, pickOne }

class AppState extends ChangeNotifier {
  AppState(this.api, this.store) {
    name = store.read<String>('name') ?? 'Kathrine';
    gender = store.read<String>('gender') ?? 'Woman';
    interestedIn = store.read<String>('interestedIn') ?? 'Men';
    ageRange = RangeValues(
      (store.read<num>('ageMin') ?? 22).toDouble(),
      (store.read<num>('ageMax') ?? 40).toDouble(),
    );
    final birthMs = store.read<num>('birthday');
    birthday = birthMs != null
        ? DateTime.fromMillisecondsSinceEpoch(birthMs.toInt())
        : DateTime(1988, 11, 2);
    rangeMeters = (store.read<num>('rangeMeters') ?? 20).toInt();
    withinMinutes = (store.read<num>('withinMinutes') ?? 20).toInt();
    invisibility = store.read<bool>('invisibility') ?? false;
    showProfileInfo = store.read<bool>('showProfileInfo') ?? true;
    onboarded = store.read<bool>('onboarded') ?? false;
    visible = api.visible;

    api.addListener(_onApiChanged);
    refreshActivity();
  }

  final LocalApi api;
  final Store store;

  // Profile.
  late String name;
  late String gender;
  late String interestedIn;
  late RangeValues ageRange;
  late DateTime birthday;

  // Session.
  SightMode mode = SightMode.inSight;
  late int rangeMeters;
  late int withinMinutes;
  late bool invisibility;
  late bool showProfileInfo;
  late bool onboarded;
  bool visible = true;
  int cursor = 0;
  int planIndex = 1;
  int introSlide = 0;

  String? activeId;
  List<ActivityItem> activity = [];

  final List<Person> allPeople = List.of(mockPeople);

  int get age {
    final now = DateTime.now();
    var years = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) years--;
    return years;
  }

  /// Everyone still in play: in range, not passed, not blocked.
  List<Person> get people {
    final list = allPeople
        .where((p) =>
            p.distanceMeters <= rangeMeters &&
            !api.passed.contains(p.id) &&
            !api.blocked.contains(p.id))
        .toList();
    return list;
  }

  List<Person> get recent => allPeople
      .where((p) =>
          p.secondsAgo <= withinMinutes * 60 &&
          !api.passed.contains(p.id) &&
          !api.liked.contains(p.id) &&
          !api.blocked.contains(p.id))
      .toList();

  bool get isEmpty => people.isEmpty;
  int get inSightCount => people.length;
  int get unread => api.unreadCount;

  Person? get current {
    final list = people;
    if (list.isEmpty) return null;
    return list[cursor % list.length];
  }

  Person? get previous {
    final list = people;
    if (list.length < 2) return null;
    return list[(cursor + list.length - 1) % list.length];
  }

  Person? get next {
    final list = people;
    if (list.length < 2) return null;
    return list[(cursor + 1) % list.length];
  }

  Person? get pairA => recent.isNotEmpty ? recent[cursor % recent.length] : null;
  Person? get pairB => recent.length > 1 ? recent[(cursor + 1) % recent.length] : null;

  /// The person a detail screen, match screen or chat is about.
  Person? get activePerson {
    if (activeId != null) {
      final match = allPeople.where((p) => p.id == activeId);
      if (match.isNotEmpty) return match.first;
    }
    return current;
  }

  Person? personById(String id) {
    final match = allPeople.where((p) => p.id == id);
    return match.isEmpty ? null : match.first;
  }

  List<Person> get matches =>
      allPeople.where((p) => api.matched.contains(p.id)).toList();

  void openPerson(String id) {
    activeId = id;
    final i = people.indexWhere((p) => p.id == id);
    if (i >= 0) cursor = i;
    notifyListeners();
  }

  Future<bool> likeActive() async {
    final person = activePerson;
    if (person == null) return false;
    final mutual = await api.like(person.id);
    activeId = person.id;
    if (!mutual) advance();
    return mutual;
  }

  Future<void> passActive() async {
    final person = activePerson;
    if (person == null) return;
    await api.pass(person.id);
    activeId = null;
    notifyListeners();
  }

  Future<void> refreshActivity() async {
    activity = await api.activity();
    notifyListeners();
  }

  void setMode(SightMode value) {
    mode = value;
    notifyListeners();
  }

  void setRange(int meters) {
    rangeMeters = meters.clamp(5, 20);
    store.write('rangeMeters', rangeMeters);
    notifyListeners();
  }

  void setMinutes(int minutes) {
    withinMinutes = minutes.clamp(0, 30);
    store.write('withinMinutes', withinMinutes);
    notifyListeners();
  }

  void setCursor(int index) {
    if (cursor == index) return;
    cursor = index;
    activeId = null;
    notifyListeners();
  }

  void advance([int by = 1]) {
    final len = people.length;
    if (len == 0) return;
    cursor = (cursor + by) % len;
    activeId = null;
    notifyListeners();
  }

  void rewind([int by = 1]) {
    final len = people.length;
    if (len == 0) return;
    cursor = (cursor - by + len * 2) % len;
    activeId = null;
    notifyListeners();
  }

  void toggleVisible() {
    visible = !visible;
    api.setVisible(visible);
    notifyListeners();
  }

  void markOnboarded() {
    if (onboarded) return;
    onboarded = true;
    store.write('onboarded', true);
  }

  Future<void> resetEverything() async {
    await store.wipe();
    notifyListeners();
  }

  /// Mutate any field and have it saved.
  void set(void Function() mutate) {
    mutate();
    store.writeAll({
      'name': name,
      'gender': gender,
      'interestedIn': interestedIn,
      'ageMin': ageRange.start,
      'ageMax': ageRange.end,
      'birthday': birthday.millisecondsSinceEpoch,
      'invisibility': invisibility,
      'showProfileInfo': showProfileInfo,
    });
    notifyListeners();
  }

  void _onApiChanged() {
    api.activity().then((value) {
      activity = value;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    api.removeListener(_onApiChanged);
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this widget');
    return scope!.notifier!;
  }
}
