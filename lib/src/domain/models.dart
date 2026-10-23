import 'scoring.dart';

class BowlerProfile {
  const BowlerProfile({this.name = '', this.aliases = const []});
  final String name;
  final List<String> aliases;
  Map<String, dynamic> toJson() => {'name': name, 'aliases': aliases};
  factory BowlerProfile.fromJson(Map<String, dynamic> j) => BowlerProfile(
    name: j['name'] as String,
    aliases: List<String>.from(j['aliases'] as List),
  );
}

class BowlingBall {
  const BowlingBall({
    required this.id,
    required this.name,
    this.brand = '',
    this.weight = 15,
    this.notes = '',
    this.retired = false,
  });
  final String id, name, brand, notes;
  final double weight;
  final bool retired;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'weight': weight,
    'notes': notes,
    'retired': retired,
  };
  factory BowlingBall.fromJson(Map<String, dynamic> j) => BowlingBall(
    id: j['id'] as String,
    name: j['name'] as String,
    brand: j['brand'] as String,
    weight: (j['weight'] as num).toDouble(),
    notes: j['notes'] as String,
    retired: j['retired'] as bool,
  );
}

class BowlingAlley {
  const BowlingAlley({
    required this.id,
    required this.name,
    this.address = '',
    this.latitude,
    this.longitude,
    this.osmId,
    this.notes = '',
    this.retired = false,
  });
  final String id, name, address, notes;
  final String? osmId;
  final double? latitude, longitude;
  final bool retired;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'osmId': osmId,
    'notes': notes,
    'retired': retired,
  };
  factory BowlingAlley.fromJson(Map<String, dynamic> j) => BowlingAlley(
    id: j['id'] as String,
    name: j['name'] as String,
    address: j['address'] as String,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    osmId: j['osmId'] as String?,
    notes: j['notes'] as String,
    retired: j['retired'] as bool,
  );
}

class BowlingSession {
  BowlingSession({
    required this.id,
    required this.alleyId,
    required this.startedAt,
    this.lane = '',
    this.league = false,
    this.leagueName = '',
    this.notes = '',
    this.finishedAt,
    int? utcOffsetMinutes,
  }) : utcOffsetMinutes =
           utcOffsetMinutes ?? startedAt.timeZoneOffset.inMinutes;
  final String id, alleyId, lane, leagueName, notes;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int utcOffsetMinutes;
  final bool league;
  bool get finished => finishedAt != null;
  BowlingSession finish() => BowlingSession(
    id: id,
    alleyId: alleyId,
    startedAt: startedAt,
    lane: lane,
    league: league,
    leagueName: leagueName,
    notes: notes,
    finishedAt: DateTime.now(),
    utcOffsetMinutes: utcOffsetMinutes,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'alleyId': alleyId,
    'startedAt': startedAt.toIso8601String(),
    'utcOffsetMinutes': utcOffsetMinutes,
    'lane': lane,
    'league': league,
    'leagueName': leagueName,
    'notes': notes,
    'finishedAt': finishedAt?.toIso8601String(),
  };
  factory BowlingSession.fromJson(Map<String, dynamic> j) => BowlingSession(
    id: j['id'] as String,
    alleyId: j['alleyId'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    utcOffsetMinutes: j['utcOffsetMinutes'] as int?,
    lane: j['lane'] as String,
    league: j['league'] as bool,
    leagueName: j['leagueName'] as String,
    notes: j['notes'] as String,
    finishedAt: j['finishedAt'] == null
        ? null
        : DateTime.parse(j['finishedAt'] as String),
  );
}

class BowlingGame {
  const BowlingGame({
    required this.id,
    required this.sessionId,
    required this.frames,
    required this.createdAt,
    this.lane = '',
    this.ballIds = const [],
    this.primaryBallId,
    this.notes = '',
  });
  final String id, sessionId, lane, notes;
  final String? primaryBallId;
  final List<String> frames, ballIds;
  final DateTime createdAt;
  ScoreResult get result => TenPinScorer.score(frames);
  int get score => result.total!;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'frames': frames,
    'createdAt': createdAt.toIso8601String(),
    'lane': lane,
    'ballIds': ballIds,
    'primaryBallId': primaryBallId,
    'notes': notes,
  };
  factory BowlingGame.fromJson(Map<String, dynamic> j) => BowlingGame(
    id: j['id'] as String,
    sessionId: j['sessionId'] as String,
    frames: List<String>.from(j['frames'] as List),
    createdAt: DateTime.parse(j['createdAt'] as String),
    lane: j['lane'] as String,
    ballIds: List<String>.from(j['ballIds'] as List),
    primaryBallId: j['primaryBallId'] as String?,
    notes: j['notes'] as String,
  );
}

class BowlData {
  const BowlData({
    this.profile = const BowlerProfile(),
    this.balls = const [],
    this.alleys = const [],
    this.sessions = const [],
    this.games = const [],
    this.draft,
  });
  final BowlerProfile profile;
  final List<BowlingBall> balls;
  final List<BowlingAlley> alleys;
  final List<BowlingSession> sessions;
  final List<BowlingGame> games;
  final Map<String, dynamic>? draft;
  BowlData copyWith({
    BowlerProfile? profile,
    List<BowlingBall>? balls,
    List<BowlingAlley>? alleys,
    List<BowlingSession>? sessions,
    List<BowlingGame>? games,
    Map<String, dynamic>? draft,
    bool clearDraft = false,
  }) => BowlData(
    profile: profile ?? this.profile,
    balls: balls ?? this.balls,
    alleys: alleys ?? this.alleys,
    sessions: sessions ?? this.sessions,
    games: games ?? this.games,
    draft: clearDraft ? null : draft ?? this.draft,
  );
  BowlingAlley? alley(String id) => alleys.where((a) => a.id == id).firstOrNull;
  BowlingBall? ball(String id) => balls.where((b) => b.id == id).firstOrNull;
  List<BowlingGame> sessionGames(String id) =>
      games.where((g) => g.sessionId == id).toList();
  Map<String, dynamic> toJson() => {
    'profile': profile.toJson(),
    'balls': balls.map((b) => b.toJson()).toList(),
    'alleys': alleys.map((a) => a.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'games': games.map((g) => g.toJson()).toList(),
    'draft': draft,
  };
  factory BowlData.fromJson(Map<String, dynamic> j) {
    final data = BowlData(
      profile: BowlerProfile.fromJson(
        Map<String, dynamic>.from(j['profile'] as Map),
      ),
      balls: (j['balls'] as List)
          .map((v) => BowlingBall.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      alleys: (j['alleys'] as List)
          .map(
            (v) => BowlingAlley.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      sessions: (j['sessions'] as List)
          .map(
            (v) => BowlingSession.fromJson(Map<String, dynamic>.from(v as Map)),
          )
          .toList(),
      games: (j['games'] as List)
          .map((v) => BowlingGame.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      draft: j['draft'] == null
          ? null
          : Map<String, dynamic>.from(j['draft'] as Map),
    );
    data.validate();
    return data;
  }
  void validate() {
    void ids(Iterable<String> values) {
      final list = values.toList();
      if (list.any((v) => v.isEmpty) || list.toSet().length != list.length) {
        throw const FormatException('Missing or duplicate record identifiers.');
      }
    }

    ids(balls.map((v) => v.id));
    ids(alleys.map((v) => v.id));
    ids(sessions.map((v) => v.id));
    ids(games.map((v) => v.id));
    if (sessions.where((s) => !s.finished).length > 1) {
      throw const FormatException('Only one session can be in progress.');
    }
    for (final b in balls) {
      if (b.name.trim().isEmpty ||
          !b.weight.isFinite ||
          b.weight <= 0 ||
          b.weight > 16) {
        throw const FormatException('Invalid ball name or weight.');
      }
    }
    for (final a in alleys) {
      if (a.name.trim().isEmpty ||
          (a.latitude == null) != (a.longitude == null) ||
          (a.latitude != null &&
              (!a.latitude!.isFinite ||
                  a.latitude!.abs() > 90 ||
                  !a.longitude!.isFinite ||
                  a.longitude!.abs() > 180))) {
        throw const FormatException('Invalid alley name or coordinates.');
      }
    }
    for (final s in sessions) {
      if (alley(s.alleyId) == null) {
        throw const FormatException('A session references a missing alley.');
      }
    }
    for (final g in games) {
      if (!sessions.any((s) => s.id == g.sessionId) ||
          !g.result.complete ||
          g.ballIds.toSet().length != g.ballIds.length ||
          g.ballIds.any((id) => ball(id) == null) ||
          (g.primaryBallId != null && !g.ballIds.contains(g.primaryBallId))) {
        throw const FormatException(
          'Invalid game frames or record references.',
        );
      }
    }
    if (draft != null) {
      if (!sessions.any((s) => s.id == draft!['sessionId'] && !s.finished) ||
          draft!['frames'] is! List ||
          (draft!['frames'] as List).length != 10 ||
          (draft!['frames'] as List).any((v) => v is! String || v.length > 3)) {
        throw const FormatException('Invalid game draft.');
      }
      final d = draft!;
      final tags = d['ballIds'] ?? <String>[];
      if ((d['lane'] != null && d['lane'] is! String) ||
          (d['notes'] != null && d['notes'] is! String) ||
          (d['sourceLabel'] != null && d['sourceLabel'] is! String) ||
          (d['sourcePath'] != null && d['sourcePath'] is! String) ||
          tags is! List ||
          tags.any((v) => v is! String || ball(v) == null) ||
          tags.toSet().length != tags.length ||
          (d['primaryBallId'] != null && !tags.contains(d['primaryBallId'])) ||
          (d['displayedTotal'] != null &&
              (d['displayedTotal'] is! int ||
                  (d['displayedTotal'] as int) < 0 ||
                  (d['displayedTotal'] as int) > 300))) {
        throw const FormatException('Invalid game draft details.');
      }
    }
  }
}
