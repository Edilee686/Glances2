class Person {
  const Person({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.distanceMeters,
    required this.secondsAgo,
    this.photoUrl,
  });

  final String id;
  final String name;
  final int age;
  final String city;
  final int distanceMeters;
  final int secondsAgo;
  final String? photoUrl;

  String get distanceLabel =>
      distanceMeters >= 1000 ? (distanceMeters / 1000).toStringAsFixed(1) + ' km' : distanceMeters.toString() + ' m';

  String get seenLabel {
    if (secondsAgo < 60) return 'here now';
    final mins = secondsAgo ~/ 60;
    return 'seen ' + mins.toString() + ' min ago';
  }
}
