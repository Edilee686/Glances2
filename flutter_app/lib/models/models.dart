class Profile {
  Profile({
    required this.id,
    required this.accountId,
    required this.name,
    required this.gender,
    required this.seeking,
    required this.birthday,
    required this.city,
    required this.about,
    required this.heightCm,
    required this.photoPath,
    required this.isSelf,
    required this.distanceM,
    required this.seenSecsAgo,
    required this.onboarded,
  });

  factory Profile.fromRow(Map<String, Object?> row) => Profile(
        id: row['id'] as String,
        accountId: row['account_id'] as String?,
        name: (row['name'] as String?) ?? '',
        gender: (row['gender'] as String?) ?? '',
        seeking: (row['seeking'] as String?) ?? '',
        birthday: row['birthday'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['birthday'] as int),
        city: (row['city'] as String?) ?? '',
        about: (row['about'] as String?) ?? '',
        heightCm: row['height_cm'] as int?,
        photoPath: row['photo_path'] as String?,
        isSelf: (row['is_self'] as int? ?? 0) == 1,
        distanceM: row['distance_m'] as int? ?? 0,
        seenSecsAgo: row['seen_secs_ago'] as int? ?? 0,
        onboarded: (row['onboarded'] as int? ?? 0) == 1,
      );

  final String id;
  final String? accountId;
  final String name;
  final String gender;
  final String seeking;
  final DateTime? birthday;
  final String city;
  final String about;
  final int? heightCm;
  final String? photoPath;
  final bool isSelf;
  final int distanceM;
  final int seenSecsAgo;
  final bool onboarded;

  int get age {
    final b = birthday;
    if (b == null) return 0;
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) years--;
    return years;
  }

  /// "Maria 35, Tel Aviv" - the exact label from the Figma person screen.
  String get headline {
    final parts = <String>[name];
    if (age > 0) parts.add(age.toString());
    final left = parts.join(' ');
    return city.isEmpty ? left : left + ', ' + city;
  }

  String get seenLabel {
    if (seenSecsAgo < 90) return 'just now';
    if (seenSecsAgo < 3600) return (seenSecsAgo ~/ 60).toString() + ' min ago';
    return (seenSecsAgo ~/ 3600).toString() + ' h ago';
  }

  /// "You've met her around 11:15" - Figma activity row.
  String get metAtLabel {
    final at = DateTime.now().subtract(Duration(seconds: seenSecsAgo));
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return 'You\'ve met her around ' + hh + ':' + mm;
  }
}

class Message {
  Message({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    required this.sentAt,
    required this.readAt,
  });

  factory Message.fromRow(Map<String, Object?> row) => Message(
        id: row['id'] as int,
        threadId: row['thread_id'] as String,
        authorId: row['author_id'] as String,
        body: row['body'] as String,
        sentAt: DateTime.fromMillisecondsSinceEpoch(row['sent_at'] as int),
        readAt: row['read_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['read_at'] as int),
      );

  final int id;
  final String threadId;
  final String authorId;
  final String body;
  final DateTime sentAt;
  final DateTime? readAt;

  String get timeLabel =>
      sentAt.hour.toString().padLeft(2, '0') + ':' + sentAt.minute.toString().padLeft(2, '0');
}

class LikeRow {
  LikeRow({
    required this.otherId,
    required this.otherName,
    required this.outgoing,
    required this.at,
  });

  factory LikeRow.fromRow(Map<String, Object?> row, String selfId) {
    final from = row['from_id'] as String;
    return LikeRow(
      otherId: from == selfId ? row['to_id'] as String : from,
      otherName: (row['other_name'] as String?) ?? '',
      outgoing: from == selfId,
      at: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  final String otherId;
  final String otherName;
  final bool outgoing;
  final DateTime at;
}
