import 'dart:async';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

/// The Glances database. A real relational store on the device: accounts,
/// profiles, likes, matches, messages. Everything the app shows is a query.
class GlancesDb {
  GlancesDb._(this._db);

  final Database _db;

  static Future<GlancesDb> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, 'glances.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _create,
    );
    final instance = GlancesDb._(db);
    await instance._seed();
    return instance;
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id           TEXT PRIMARY KEY,
        provider     TEXT NOT NULL,
        identifier   TEXT NOT NULL,
        secret       TEXT,
        created_at   INTEGER NOT NULL,
        UNIQUE(provider, identifier)
      )
    ''');
    await db.execute('''
      CREATE TABLE profiles (
        id             TEXT PRIMARY KEY,
        account_id     TEXT UNIQUE REFERENCES accounts(id) ON DELETE CASCADE,
        name           TEXT NOT NULL DEFAULT '',
        gender         TEXT NOT NULL DEFAULT '',
        seeking        TEXT NOT NULL DEFAULT '',
        birthday       INTEGER,
        city           TEXT NOT NULL DEFAULT '',
        about          TEXT NOT NULL DEFAULT '',
        height_cm      INTEGER,
        photo_path     TEXT,
        is_self        INTEGER NOT NULL DEFAULT 0,
        distance_m     INTEGER NOT NULL DEFAULT 0,
        seen_secs_ago  INTEGER NOT NULL DEFAULT 0,
        onboarded      INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE likes (
        from_id    TEXT NOT NULL,
        to_id      TEXT NOT NULL,
        state      TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (from_id, to_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE matches (
        a_id       TEXT NOT NULL,
        b_id       TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        expires_at INTEGER,
        unlocked   INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (a_id, b_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        thread_id  TEXT NOT NULL,
        author_id  TEXT NOT NULL,
        body       TEXT NOT NULL,
        sent_at    INTEGER NOT NULL,
        read_at    INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_messages_thread ON messages(thread_id, sent_at)');
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// The other people in the world. Without a server these are fixtures, but
  /// they live in the same tables as everything else.
  Future<void> _seed() async {
    final existing = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COUNT(*) FROM profiles WHERE is_self = 0'),
    );
    if ((existing ?? 0) > 0) return;

    const seed = [
      ['maria', 'Maria', 'Woman', 35, 'Tel Aviv', 6, 120],
      ['orel', 'Orel', 'Woman', 28, 'Netanya', 9, 340],
      ['sima', 'Sima', 'Woman', 31, 'Herzliya', 12, 60],
      ['loren', 'Loren', 'Woman', 26, 'Tel Aviv', 15, 900],
      ['dana', 'Dana', 'Woman', 29, 'Ramat Gan', 18, 1500],
      ['yael', 'Yael', 'Woman', 33, 'Tel Aviv', 20, 240],
      ['noa', 'Noa', 'Woman', 24, 'Bat Yam', 7, 45],
      ['tamar', 'Tamar', 'Woman', 30, 'Netanya', 14, 720],
    ];
    final now = DateTime.now();
    final batch = _db.batch();
    for (final row in seed) {
      final age = row[3] as int;
      batch.insert('profiles', {
        'id': row[0],
        'account_id': null,
        'name': row[1],
        'gender': row[2],
        'seeking': 'Men',
        'birthday': DateTime(now.year - age, now.month, now.day).millisecondsSinceEpoch,
        'city': row[4],
        'about': '',
        'photo_path': null,
        'is_self': 0,
        'distance_m': row[5],
        'seen_secs_ago': row[6],
        'onboarded': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  // ---- accounts -----------------------------------------------------------

  Future<Map<String, Object?>?> findAccount(String provider, String identifier) async {
    final rows = await _db.query(
      'accounts',
      where: 'provider = ? AND identifier = ?',
      whereArgs: [provider, identifier],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<String> createAccount(String provider, String identifier, String? secret) async {
    final id = _uid();
    await _db.insert('accounts', {
      'id': id,
      'provider': provider,
      'identifier': identifier,
      'secret': secret,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await _db.insert('profiles', {
      'id': _uid(),
      'account_id': id,
      'name': '',
      'gender': '',
      'seeking': '',
      'city': '',
      'about': '',
      'is_self': 1,
      'distance_m': 0,
      'seen_secs_ago': 0,
      'onboarded': 0,
    });
    return id;
  }

  Future<void> deleteAccount(String accountId) async {
    final me = await selfProfile(accountId);
    if (me != null) {
      await _db.delete('likes', where: 'from_id = ? OR to_id = ?', whereArgs: [me.id, me.id]);
      await _db.delete('matches', where: 'a_id = ? OR b_id = ?', whereArgs: [me.id, me.id]);
      await _db.delete('messages', where: 'thread_id LIKE ?', whereArgs: ['%' + me.id + '%']);
    }
    await _db.delete('accounts', where: 'id = ?', whereArgs: [accountId]);
  }

  // ---- profiles -----------------------------------------------------------

  Future<Profile?> selfProfile(String accountId) async {
    final rows = await _db.query('profiles', where: 'account_id = ?', whereArgs: [accountId], limit: 1);
    return rows.isEmpty ? null : Profile.fromRow(rows.first);
  }

  Future<Profile?> profile(String id) async {
    final rows = await _db.query('profiles', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Profile.fromRow(rows.first);
  }

  Future<void> updateProfile(String id, Map<String, Object?> values) =>
      _db.update('profiles', values, where: 'id = ?', whereArgs: [id]);

  /// Everyone within [rangeMeters] that the viewer has not already judged.
  Future<List<Profile>> inSight({
    required String viewerId,
    required int rangeMeters,
  }) async {
    final rows = await _db.rawQuery('''
      SELECT p.* FROM profiles p
      WHERE p.is_self = 0
        AND p.distance_m <= ?
        AND p.id NOT IN (SELECT to_id FROM likes WHERE from_id = ? AND state IN ('pass','block'))
      ORDER BY p.distance_m ASC
    ''', [rangeMeters, viewerId]);
    return rows.map(Profile.fromRow).toList();
  }

  /// People seen in the last [withinMinutes], for the pick-one-of-two screen.
  Future<List<Profile>> recentlySeen({
    required String viewerId,
    required int withinMinutes,
  }) async {
    final rows = await _db.rawQuery('''
      SELECT p.* FROM profiles p
      WHERE p.is_self = 0
        AND p.seen_secs_ago <= ?
        AND p.id NOT IN (SELECT to_id FROM likes WHERE from_id = ?)
      ORDER BY p.seen_secs_ago ASC
    ''', [withinMinutes * 60, viewerId]);
    return rows.map(Profile.fromRow).toList();
  }

  // ---- likes and matches --------------------------------------------------

  Future<String?> likeState(String fromId, String toId) async {
    final rows = await _db.query('likes',
        columns: ['state'], where: 'from_id = ? AND to_id = ?', whereArgs: [fromId, toId], limit: 1);
    return rows.isEmpty ? null : rows.first['state'] as String;
  }

  Future<void> setLike(String fromId, String toId, String state) => _db.insert(
        'likes',
        {
          'from_id': fromId,
          'to_id': toId,
          'state': state,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<bool> isMatched(String a, String b) async {
    final key = _pair(a, b);
    final rows = await _db.query('matches',
        where: 'a_id = ? AND b_id = ?', whereArgs: [key.$1, key.$2], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> createMatch(String a, String b, {Duration? window}) async {
    final key = _pair(a, b);
    final now = DateTime.now();
    await _db.insert(
      'matches',
      {
        'a_id': key.$1,
        'b_id': key.$2,
        'created_at': now.millisecondsSinceEpoch,
        'expires_at': window == null ? null : now.add(window).millisecondsSinceEpoch,
        'unlocked': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Profile>> matchesFor(String selfId) async {
    final rows = await _db.rawQuery('''
      SELECT p.* FROM profiles p
      JOIN matches m ON (m.a_id = p.id OR m.b_id = p.id)
      WHERE (m.a_id = ? OR m.b_id = ?) AND p.id != ?
      ORDER BY m.created_at DESC
    ''', [selfId, selfId, selfId]);
    return rows.map(Profile.fromRow).toList();
  }

  Future<DateTime?> matchExpiry(String a, String b) async {
    final key = _pair(a, b);
    final rows = await _db.query('matches',
        where: 'a_id = ? AND b_id = ?', whereArgs: [key.$1, key.$2], limit: 1);
    if (rows.isEmpty) return null;
    final value = rows.first['expires_at'] as int?;
    final unlocked = (rows.first['unlocked'] as int? ?? 0) == 1;
    if (unlocked || value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<void> unlockMatch(String a, String b) async {
    final key = _pair(a, b);
    await _db.update('matches', {'unlocked': 1},
        where: 'a_id = ? AND b_id = ?', whereArgs: [key.$1, key.$2]);
  }

  Future<void> removeMatch(String a, String b) async {
    final key = _pair(a, b);
    await _db.delete('matches', where: 'a_id = ? AND b_id = ?', whereArgs: [key.$1, key.$2]);
  }

  // ---- messages -----------------------------------------------------------

  String threadId(String a, String b) {
    final key = _pair(a, b);
    return key.$1 + ':' + key.$2;
  }

  Future<List<Message>> messages(String a, String b) async {
    final rows = await _db.query('messages',
        where: 'thread_id = ?', whereArgs: [threadId(a, b)], orderBy: 'sent_at ASC');
    return rows.map(Message.fromRow).toList();
  }

  Future<void> addMessage(String a, String b, String authorId, String body) =>
      _db.insert('messages', {
        'thread_id': threadId(a, b),
        'author_id': authorId,
        'body': body,
        'sent_at': DateTime.now().millisecondsSinceEpoch,
      });

  Future<void> markThreadRead(String a, String b, String readerId) => _db.update(
        'messages',
        {'read_at': DateTime.now().millisecondsSinceEpoch},
        where: 'thread_id = ? AND author_id != ? AND read_at IS NULL',
        whereArgs: [threadId(a, b), readerId],
      );

  Future<int> unreadCount(String selfId) async {
    final value = Sqflite.firstIntValue(await _db.rawQuery('''
      SELECT COUNT(*) FROM messages
      WHERE thread_id LIKE ? AND author_id != ? AND read_at IS NULL
    ''', ['%' + selfId + '%', selfId]));
    return value ?? 0;
  }

  Future<Message?> lastMessage(String a, String b) async {
    final rows = await _db.query('messages',
        where: 'thread_id = ?', whereArgs: [threadId(a, b)], orderBy: 'sent_at DESC', limit: 1);
    return rows.isEmpty ? null : Message.fromRow(rows.first);
  }

  /// Everyone who liked the viewer, or whom the viewer liked, most recent first.
  Future<List<LikeRow>> likeFeed(String selfId) async {
    final rows = await _db.rawQuery('''
      SELECT l.*, p.name AS other_name FROM likes l
      JOIN profiles p ON p.id = CASE WHEN l.from_id = ? THEN l.to_id ELSE l.from_id END
      WHERE (l.from_id = ? OR l.to_id = ?) AND l.state IN ('like','liked_you')
      ORDER BY l.created_at DESC
    ''', [selfId, selfId, selfId]);
    return rows.map((r) => LikeRow.fromRow(r, selfId)).toList();
  }

  // ---- settings -----------------------------------------------------------

  Future<String?> setting(String key) async {
    final rows = await _db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> putSetting(String key, String value) => _db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> wipe() async {
    await _db.delete('likes');
    await _db.delete('matches');
    await _db.delete('messages');
    await _db.delete('profiles', where: 'is_self = 1');
    await _db.delete('accounts');
    await _db.delete('settings');
  }

  (String, String) _pair(String a, String b) => a.compareTo(b) <= 0 ? (a, b) : (b, a);

  static String _uid() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(16, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
