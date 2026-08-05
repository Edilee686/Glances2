import 'package:flutter/widgets.dart';

import '../data/mock_people.dart';
import '../models/person.dart';
import '../services/api.dart';

enum SightMode { inSight, pickOne }

class AppState extends ChangeNotifier {
  AppState(this.api);

  final GlancesApi api;

  // Profile being created / edited.
  String name = 'Kathrine';
  String gender = 'Woman';
  String interestedIn = 'Men';
  RangeValues ageRange = const RangeValues(22, 40);
  DateTime birthday = DateTime(1988, 11, 2);

  // Session.
  SightMode mode = SightMode.inSight;
  int rangeMeters = 20;
  int withinMinutes = 20;
  int cursor = 0;
  bool visible = true;
  bool invisibility = false;
  bool showProfileInfo = true;
  int planIndex = 1;
  int introSlide = 0;

  List<Person> people = mockPeople;

  Person get current => people[cursor % people.length];
  Person get previous => people[(cursor + people.length - 1) % people.length];
  Person get next => people[(cursor + 1) % people.length];
  Person get pairA => people[cursor % people.length];
  Person get pairB => people[(cursor + 1) % people.length];

  int get inSightCount => people.where((p) => p.distanceMeters <= rangeMeters).length;

  void setMode(SightMode value) {
    mode = value;
    notifyListeners();
  }

  void setRange(int meters) {
    rangeMeters = meters.clamp(5, 20);
    notifyListeners();
  }

  void setMinutes(int minutes) {
    withinMinutes = minutes.clamp(0, 30);
    notifyListeners();
  }

  void advance([int by = 1]) {
    cursor = (cursor + by) % people.length;
    notifyListeners();
  }

  void rewind([int by = 1]) {
    cursor = (cursor - by + people.length * 2) % people.length;
    notifyListeners();
  }

  void focusPerson(String id) {
    final i = people.indexWhere((p) => p.id == id);
    if (i >= 0) {
      cursor = i;
      notifyListeners();
    }
  }

  void toggleVisible() {
    visible = !visible;
    api.setVisible(visible);
    notifyListeners();
  }

  void set<T>(void Function() mutate) {
    mutate();
    notifyListeners();
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
