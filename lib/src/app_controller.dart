import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'data/bowl_store.dart';
import 'domain/models.dart';
import 'domain/journal_index.dart';

class BowlController extends ChangeNotifier {
  BowlController(this.store, this.data);
  final BowlStore? store;
  BowlData data;
  JournalIndex? _journal;
  JournalIndex get journal {
    if (_journal?.matches(data.sessions, data.games) != true) {
      _journal = JournalIndex(data.sessions, data.games);
    }
    return _journal!;
  }

  Future<void> _pending = Future.value();
  Object? _photoAcquisition;
  bool get isAcquiringPhoto => _photoAcquisition != null;

  /// Reserve acquisition before showing an external picker/nonmodal camera.
  /// Earlier writes finish first; later conflicting actions cannot invalidate
  /// the session. The returned release belongs only to this reservation.
  Future<VoidCallback> reservePhotoAcquisition({
    String? sessionId,
    bool allowDraft = false,
  }) async {
    if (isAcquiringPhoto) {
      throw StateError('Finish or cancel the open photo picker first.');
    }
    final token = Object();
    _photoAcquisition = token;
    notifyListeners();
    void release() {
      if (identical(_photoAcquisition, token)) {
        _photoAcquisition = null;
        notifyListeners();
      }
    }

    try {
      await _pending;
      if ((sessionId != null && activeSession?.id != sessionId) ||
          (!allowDraft && data.draft != null)) {
        throw StateError(
          'Resume your unfinished game or select the current session first.',
        );
      }
      return release;
    } catch (_) {
      release();
      rethrow;
    }
  }

  Future<void> _updateJournal(BowlData Function(BowlData) change) =>
      isAcquiringPhoto
      ? Future.error(
          StateError('Finish or cancel the open photo picker first.'),
        )
      : update(change);
  static const _uuid = Uuid();
  String newId() => _uuid.v4();
  static Future<BowlController> open() async {
    final store = await BowlStore.open();
    try {
      return BowlController(store, await store.load());
    } catch (_) {
      await store.close();
      rethrow;
    }
  }

  BowlingSession? get activeSession =>
      data.sessions.where((s) => !s.finished).firstOrNull;
  Future<void> update(BowlData Function(BowlData) change) {
    final work = _pending.then((_) async {
      final next = change(data);
      // The store validates persisted snapshots before its transaction. Keep
      // the same guard for in-memory controllers without doing it twice.
      if (store == null) {
        next.validate();
      } else {
        await store!.save(next);
      }
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
    (d) => d.copyWith(
      balls: d.balls.any((b) => b.id == ball.id)
          ? [for (final b in d.balls) b.id == ball.id ? ball : b]
          : [...d.balls, ball],
    ),
  );
  Future<void> saveAlley(BowlingAlley alley) => update(
    (d) => d.copyWith(
      alleys: d.alleys.any((a) => a.id == alley.id)
          ? [for (final a in d.alleys) a.id == alley.id ? alley : a]
          : [...d.alleys, alley],
    ),
  );
  Future<void> startSession(BowlingSession session) => _updateJournal((d) {
    if (d.sessions.any((s) => !s.finished)) {
      throw StateError('Finish your current session first.');
    }
    return d.copyWith(sessions: [...d.sessions, session]);
  });
  Future<void> finishSession(String id) => _updateJournal(
    (d) => d.copyWith(
      sessions: [for (final s in d.sessions) s.id == id ? s.finish() : s],
    ),
  );
  Future<void> saveDraft(Map<String, dynamic> draft) =>
      _updateJournal((d) => d.copyWith(draft: draft));
  Future<void> beginPhotoReview(String sessionId, String sourcePath) =>
      update((d) {
        if (d.draft != null || activeSession?.id != sessionId) {
          throw StateError('Resume or discard your unfinished game first.');
        }
        return d.copyWith(
          draft: {
            'sessionId': sessionId,
            'frames': List.filled(10, ''),
            'sourcePath': sourcePath,
            'pendingPhotoReview': true,
          },
        );
      });
  Future<void> discardDraft() =>
      _updateJournal((d) => d.copyWith(clearDraft: true));
  Future<void> saveGame(BowlingGame game) => _updateJournal((d) {
    final isNew = !d.games.any((g) => g.id == game.id);
    return d.copyWith(
      games: isNew
          ? [...d.games, game]
          : [for (final g in d.games) g.id == game.id ? game : g],
      clearDraft: isNew && d.draft?['sessionId'] == game.sessionId,
    );
  });
  Future<void> deleteGame(String id) => _updateJournal(
    (d) => d.copyWith(games: d.games.where((g) => g.id != id).toList()),
  );

  /// Commit the session, games, and matching draft as one snapshot. Return the
  /// removed draft's private photo only after persistence succeeds, for cleanup.
  Future<String?> deleteSession(String id) async {
    String? source;
    await _updateJournal((d) {
      if (!d.sessions.any((s) => s.id == id)) {
        throw StateError('This session has already been removed.');
      }
      final ownsDraft = d.draft?['sessionId'] == id;
      if (ownsDraft) source = d.draft?['sourcePath'] as String?;
      return d.copyWith(
        sessions: d.sessions.where((s) => s.id != id).toList(),
        games: d.games.where((g) => g.sessionId != id).toList(),
        clearDraft: ownsDraft,
      );
    });
    return source;
  }

  Future<void> restore(BowlData restored) => _updateJournal((_) => restored);
}
