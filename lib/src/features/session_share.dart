import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../app_controller.dart';
import '../config.dart';
import '../data/exports.dart';
import '../domain/models.dart';
import '../theme.dart';
import '../ui/common.dart';

Future<void> openSessionShare(
  BuildContext context,
  BowlController controller,
  BowlingSession session,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => SessionSharePage(data: controller.data, session: session),
  ),
);

class SessionSharePage extends StatefulWidget {
  const SessionSharePage({
    super.key,
    required this.data,
    required this.session,
  });
  final BowlData data;
  final BowlingSession session;
  @override
  State<SessionSharePage> createState() => _SessionSharePageState();
}

class _SessionSharePageState extends State<SessionSharePage> {
  final _imageKey = GlobalKey();
  bool _showName = true,
      _showAlley = true,
      _showBalls = true,
      _showDate = true,
      _busy = false;
  Future<void> _export(BuildContext buttonContext, {bool share = true}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final anchor = BowlExports.origin(buttonContext);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = encoded!.buffer.asUint8List();
      final name =
          'tallybowl-${widget.session.startedAt.toIso8601String().substring(0, 10)}.png';
      if (share) {
        final file = await BowlExports.temporaryFile(name, bytes);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            fileNameOverrides: [name],
            sharePositionOrigin: anchor,
          ),
        );
      } else if (buttonContext.mounted) {
        await BowlExports.exportFile(
          buttonContext,
          name: name,
          mime: 'image/png',
          bytes: bytes,
        );
      }
    } catch (e) {
      if (mounted) message(context, 'Could not create the recap image. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Share your night')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeading(
                'A night worth sharing.',
                'Make it yours, then send a little bowling joy.',
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Your name'),
                    selected: _showName,
                    onSelected: (v) => setState(() => _showName = v),
                  ),
                  FilterChip(
                    label: const Text('Alley & lane'),
                    selected: _showAlley,
                    onSelected: (v) => setState(() => _showAlley = v),
                  ),
                  FilterChip(
                    label: const Text('Balls used'),
                    selected: _showBalls,
                    onSelected: (v) => setState(() => _showBalls = v),
                  ),
                  FilterChip(
                    label: const Text('Date'),
                    selected: _showDate,
                    onSelected: (v) => setState(() => _showDate = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _imageKey,
                    child: RecapCard(
                      data: widget.data,
                      session: widget.session,
                      showName: _showName,
                      showAlley: _showAlley,
                      showBalls: _showBalls,
                      showDate: _showDate,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Builder(
                    builder: (c) => FilledButton.icon(
                      onPressed: _busy ? null : () => _export(c),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: Text(_busy ? 'Creating image…' : 'Share image'),
                    ),
                  ),
                  Builder(
                    builder: (c) => OutlinedButton.icon(
                      onPressed: _busy ? null : () => _export(c, share: false),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Save image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Only this recap is shared. Your original photo and other bowlers are never included.',
                style: TextStyle(color: BowlColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class RecapCard extends StatelessWidget {
  const RecapCard({
    super.key,
    required this.data,
    required this.session,
    this.showName = true,
    this.showAlley = true,
    this.showBalls = true,
    this.showDate = true,
  });
  final BowlData data;
  final BowlingSession session;
  final bool showName, showAlley, showBalls, showDate;
  @override
  Widget build(BuildContext context) {
    final games = data.sessionGames(session.id);
    final total = games.fold<int>(0, (n, g) => n + g.score);
    final ballIds = games.expand((g) => g.ballIds).toSet();
    return Container(
      width: 540,
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        color: BowlColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'sans-serif',
          height: 1.3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                BallArt(size: 34, color: Color(0xFFFF9C73)),
                SizedBox(width: 12),
                Text(
                  'TallyBowl!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const Text(
              'HOW YOU BOWLED,',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFC5DDCC),
                letterSpacing: 3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'tonight.',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -3,
              ),
            ),
            const SizedBox(height: 20),
            if (showName && data.profile.name.isNotEmpty)
              Text(
                data.profile.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (showAlley)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${data.alley(session.alleyId)!.name}${session.lane.isEmpty ? '' : ' · Lane ${session.lane}'}',
                  style: const TextStyle(
                    color: Color(0xFFD6E3DB),
                    fontSize: 16,
                  ),
                ),
              ),
            if (showDate)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  dateLabel(session.startedAt),
                  style: const TextStyle(color: Color(0xFFD6E3DB)),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              session.league
                  ? (session.leagueName.isEmpty
                        ? 'LEAGUE NIGHT'
                        : 'LEAGUE NIGHT · ${session.leagueName}')
                  : 'PRACTICE NIGHT',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.5,
                color: Color(0xFFFFAC8A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < games.length; i++)
                  Container(
                    width: 108,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'GAME ${i + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: Color(0xFFC5DDCC),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${games[i].score}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BowlColors.mint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(color: BowlColors.ink),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SERIES TOTAL',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVERAGE',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            averageLabel(games),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showBalls && ballIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'IN THE BAG  ·  ${ballIds.map((id) => data.ball(id)!.name).join(' / ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD6E3DB),
                    height: 1.6,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFF456360)),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Every frame. Your story.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFC5DDCC)),
                  ),
                ),
                Text(
                  AppConfig.websiteLabel,
                  style: TextStyle(fontSize: 11, color: Color(0xFFFFAC8A)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Standard ten-pin · Scratch scores',
              style: TextStyle(fontSize: 9, color: Color(0xFF9CB8AC)),
            ),
          ],
        ),
      ),
    );
  }
}
