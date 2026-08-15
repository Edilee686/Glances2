/// Models mapped 1:1 onto the existing Django serializers. Field names match
/// the API exactly — where the API is odd (liked_early_me, my_age) the oddness
/// is preserved here rather than "cleaned up", so the mapping stays obvious.

int? _int(dynamic v) => v == null ? null : (v is int ? v : int.tryParse('$v'));
DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();

/// users.serializers.ShortUserSerializer
class ShortUser {
  final int id;
  final String? name;
  final String? city;
  final String? gender;
  final String? imageUrl;
  final DateTime? dateOfBirthday;
  final bool online;

  ShortUser({
    required this.id,
    this.name,
    this.city,
    this.gender,
    this.imageUrl,
    this.dateOfBirthday,
    this.online = false,
  });

  factory ShortUser.fromJson(Map<String, dynamic> j) => ShortUser(
        id: _int(j['id']) ?? 0,
        name: j['name'] as String?,
        city: j['city'] as String?,
        gender: j['gender'] as String?,
        imageUrl: j['image_url'] as String?,
        dateOfBirthday: _date(j['date_of_birthday']),
        online: j['status'] == true,
      );

  int? get age {
    final dob = dateOfBirthday;
    if (dob == null) return null;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) a--;
    return a;
  }
}

/// users.serializers.UserFilteredListSerializer — a discovery candidate.
class Candidate {
  final int id;
  final String? name;
  final String? imageUrl;
  final String? gender;

  /// They liked me before I saw them.
  final bool likedEarlyMe;

  /// I already liked them earlier.
  final bool likedEarlyI;

  /// A like exists in either direction.
  final bool likedI;

  Candidate({
    required this.id,
    this.name,
    this.imageUrl,
    this.gender,
    this.likedEarlyMe = false,
    this.likedEarlyI = false,
    this.likedI = false,
  });

  factory Candidate.fromJson(Map<String, dynamic> j) => Candidate(
        id: _int(j['id']) ?? 0,
        name: j['name'] as String?,
        imageUrl: j['image_url'] as String?,
        gender: j['gender'] as String?,
        likedEarlyMe: j['liked_early_me'] == true,
        likedEarlyI: j['liked_early_i'] == true,
        likedI: j['liked_i'] == true,
      );
}

/// users.serializers.UserProfileSerializer
class Profile {
  final int? id;
  final DateTime? dateOfBirthday;
  final String? gender;
  final int? myAge;
  final int unreadMessages;
  final int unreadLikes;

  Profile({
    this.id,
    this.dateOfBirthday,
    this.gender,
    this.myAge,
    this.unreadMessages = 0,
    this.unreadLikes = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: _int(j['id']),
        dateOfBirthday: _date(j['date_of_birthday']),
        gender: j['gender'] as String?,
        myAge: _int(j['my_age']),
        unreadMessages: _int(j['unread_messages']) ?? 0,
        unreadLikes: _int(j['unread_likes']) ?? 0,
      );
}

/// users.serializers.UserSettingSerializer
class Settings {
  final int? id;
  final String? location;
  final String meetGender;
  final bool invisibility;
  final bool notification;
  final bool online;
  final bool showInfo;
  final int preferredAgeFrom;
  final int preferredAgeTo;
  final int distance;

  Settings({
    this.id,
    this.location,
    this.meetGender = 'both',
    this.invisibility = false,
    this.notification = true,
    this.online = true,
    this.showInfo = true,
    this.preferredAgeFrom = 18,
    this.preferredAgeTo = 65,
    this.distance = 100,
  });

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        id: _int(j['id']),
        location: j['location'] as String?,
        meetGender: (j['meet_gender'] as String?) ?? 'both',
        invisibility: j['invisibility'] == true,
        notification: j['notification'] != false,
        online: j['online'] != false,
        showInfo: j['show_info'] != false,
        preferredAgeFrom: _int(j['preferred_age_from']) ?? 18,
        preferredAgeTo: _int(j['preferred_age_to']) ?? 65,
        distance: _int(j['distance']) ?? 100,
      );

  Map<String, dynamic> toJson() => {
        'location': location,
        'meet_gender': meetGender,
        'invisibility': invisibility,
        'notification': notification,
        'online': online,
        'show_info': showInfo,
        'preferred_age_from': preferredAgeFrom,
        'preferred_age_to': preferredAgeTo,
        'distance': distance,
      };

  Settings copyWith({
    String? location,
    String? meetGender,
    bool? invisibility,
    bool? notification,
    bool? online,
    bool? showInfo,
    int? preferredAgeFrom,
    int? preferredAgeTo,
    int? distance,
  }) =>
      Settings(
        id: id,
        location: location ?? this.location,
        meetGender: meetGender ?? this.meetGender,
        invisibility: invisibility ?? this.invisibility,
        notification: notification ?? this.notification,
        online: online ?? this.online,
        showInfo: showInfo ?? this.showInfo,
        preferredAgeFrom: preferredAgeFrom ?? this.preferredAgeFrom,
        preferredAgeTo: preferredAgeTo ?? this.preferredAgeTo,
        distance: distance ?? this.distance,
      );
}

class PhotoItem {
  final int id;
  final String url;
  PhotoItem({required this.id, required this.url});
  factory PhotoItem.fromJson(Map<String, dynamic> j) =>
      PhotoItem(id: _int(j['id']) ?? 0, url: (j['image_url'] ?? '') as String);
}

/// users.serializers.UserSerializer — the logged-in user.
class Me {
  final int id;
  final String? name;
  final String? email;
  final List<PhotoItem> images;
  final Profile? profile;
  final Settings? settings;

  Me({
    required this.id,
    this.name,
    this.email,
    this.images = const [],
    this.profile,
    this.settings,
  });

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: _int(j['id']) ?? 0,
        name: j['name'] as String?,
        email: j['email'] as String?,
        images: ((j['images'] as List?) ?? [])
            .map((e) => PhotoItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        profile: j['profile'] == null
            ? null
            : Profile.fromJson(Map<String, dynamic>.from(j['profile'] as Map)),
        settings: j['setting'] == null
            ? null
            : Settings.fromJson(Map<String, dynamic>.from(j['setting'] as Map)),
      );

  /// The backend refuses discovery (400) until both a profile and a settings
  /// row exist — user_validate_profile / user_validate_setting.
  bool get onboarded => profile != null && settings != null && images.isNotEmpty;
}

/// chats.serializers.ListChatRoomSerializer
class ChatRoom {
  final int id;
  final List<ShortUser> users;
  final DateTime? liveTimeTo;
  final String status;
  final int unread;
  final String? lastMessage;

  ChatRoom({
    required this.id,
    required this.users,
    this.liveTimeTo,
    this.status = 'new',
    this.unread = 0,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> j) {
    String? last;
    final lm = j['last_message'];
    if (lm is Map && lm['body'] != null) last = lm['body'] as String;
    return ChatRoom(
      id: _int(j['id']) ?? 0,
      users: ((j['users'] as List?) ?? [])
          .map((e) => ShortUser.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      liveTimeTo: _date(j['live_time_to']),
      status: (j['status'] as String?) ?? 'new',
      unread: _int(j['unread_messages']) ?? 0,
      lastMessage: last,
    );
  }

  ShortUser? partner(int myId) {
    for (final u in users) {
      if (u.id != myId) return u;
    }
    return null;
  }

  /// The chat window only starts once the partner has replied. Until then
  /// live_time_to is null and the conversation does not expire.
  Duration? get remaining {
    final t = liveTimeTo;
    if (t == null) return null;
    final d = t.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  bool get expired => remaining == Duration.zero;
  bool get locked => status == 'locked';
}

/// chats.serializers.MessageSerializer
class Message {
  final int id;
  final String body;
  final ShortUser? owner;
  final DateTime? created;
  final bool read;

  Message({
    required this.id,
    required this.body,
    this.owner,
    this.created,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: _int(j['id']) ?? 0,
        body: (j['body'] ?? '') as String,
        owner: j['owner'] == null
            ? null
            : ShortUser.fromJson(Map<String, dynamic>.from(j['owner'] as Map)),
        created: _date(j['created']),
        read: j['read'] == true,
      );
}

/// likes.serializer.LikesSerializer
class Like {
  final int id;
  final ShortUser? sender;
  final ShortUser? receiver;
  final bool isMutual;
  final int? chatId;

  Like({
    required this.id,
    this.sender,
    this.receiver,
    this.isMutual = false,
    this.chatId,
  });

  factory Like.fromJson(Map<String, dynamic> j) {
    int? chatId;
    final c = j['chat'];
    if (c is Map) chatId = _int(c['id']);
    return Like(
      id: _int(j['id']) ?? 0,
      sender: j['sender'] == null
          ? null
          : ShortUser.fromJson(Map<String, dynamic>.from(j['sender'] as Map)),
      receiver: j['receiver'] == null
          ? null
          : ShortUser.fromJson(Map<String, dynamic>.from(j['receiver'] as Map)),
      isMutual: j['is_mutual'] == true,
      chatId: chatId,
    );
  }
}

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}
