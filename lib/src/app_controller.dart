import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'data/bowl_store.dart';
import 'domain/models.dart';

class BowlController extends ChangeNotifier {
  BowlController(this.store, this.data);
  final BowlStore? store;
  BowlData data;
  Future<void> _pending = Future.value();
  static const _uuid = Uuid();
  String newId() => _uuid.v4();
  static Future<BowlController> open() async {
    final store = await BowlStore.open();
    return BowlController(store, await store.load());
  }

  BowlingSession? get activeSession =>
      data.sessions.where((s) => !s.finished).firstOrNull;
  Future<void> update(BowlData Function(BowlData) change) {
    final work = _pending.then((_) async {
      final next = change(data);
      next.validate();
      await store?.save(next);
      data = next;
      notifyListeners();
    });
    // Failed writes surface to the caller without poisoning subsequent writes.
    _pending = work.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return work;
  }

  Future<void> saveProfile(BowlerProfile profile) =>
      update((d) => d.copyWith(profile: profile));
  Future<void> saveBall(BowlingBall ball) => update(
    (d) => d.copyWith(balls: [...d.balls.where((b) => b.id != ball.id), ball]),
  );
  Future<void> saveAlley(BowlingAlley alley) => update(
    (d) =>
        d.copyWith(alleys: [...d.alleys.where((a) => a.id != alley.id), alley]),
  );
  Future<void> startSession(BowlingSession session) => update((d) {
    if (d.sessions.any((s) => !s.finished)) {
      throw StateError('Finish your current session first.');
    }
    return d.copyWith(sessions: [...d.sessions, session]);
  });
  Future<void> finishSession(String id) => update(
    (d) => d.copyWith(
      sessions: [for (final s in d.sessions) s.id == id ? s.finish() : s],
    ),
  );
  Future<void> saveDraft(Map<String, dynamic> draft) =>
      update((d) => d.copyWith(draft: draft));
  Future<void> discardDraft() => update((d) => d.copyWith(clearDraft: true));
  Future<void> saveGame(BowlingGame game) => update((d) {
    final isNew = !d.games.any((g) => g.id == game.id);
    return d.copyWith(
      games: isNew
          ? [...d.games, game]
          : [for (final g in d.games) g.id == game.id ? game : g],
      clearDraft: isNew && d.draft?['sessionId'] == game.sessionId,
    );
  });
  Future<void> deleteGame(String id) => update(
    (d) => d.copyWith(games: d.games.where((g) => g.id != id).toList()),
  );
  Future<void> restore(BowlData restored) => update((_) => restored);
}
