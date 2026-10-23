import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'config.dart';
import 'features/insights.dart';
import 'features/inventory.dart';
import 'features/journal.dart';
import 'theme.dart';
import 'ui/common.dart';
import 'features/settings.dart';
import 'recognition/photo_service.dart';
import 'features/photo_capture.dart';

class TallyBowlApp extends StatefulWidget {
  const TallyBowlApp({super.key, this.controller});
  final BowlController? controller;
  @override
  State<TallyBowlApp> createState() => _TallyBowlAppState();
}

class _TallyBowlAppState extends State<TallyBowlApp> {
  late Future<BowlController> _controller;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller == null
        ? BowlController.open()
        : Future.value(widget.controller);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConfig.name,
    debugShowCheckedModeBanner: false,
    theme: tallyBowlTheme,
    home: FutureBuilder<BowlController>(
      future: _controller,
      builder: (context, snapshot) {
        if (snapshot.hasData) return BowlShell(controller: snapshot.data!);
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: EmptyCard(
                  icon: Icons.storage_outlined,
                  title: 'Your journal couldn’t be opened.',
                  body: 'Your saved data has been left in place. Try opening it again.',
                  action: FilledButton(
                    onPressed: () =>
                        setState(() => _controller = BowlController.open()),
                    child: const Text('Try again'),
                  ),
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    ),
  );
}

class BowlShell extends StatefulWidget {
  const BowlShell({super.key, required this.controller});
  final BowlController controller;
  @override
  State<BowlShell> createState() => _BowlShellState();
}

class _BowlShellState extends State<BowlShell> {
  int _index = 0;
  @override
  void initState() {
    super.initState();
    if (widget.controller.store != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverPhoto());
    }
  }

  Future<void> _recoverPhoto() async {
    try {
      final controller = widget.controller;
      await PhotoService.cleanOrphans(
        controller.data.draft?['sourcePath'] as String?,
      );
      final session = controller.activeSession;
      if (session == null || controller.data.draft != null) return;
      final recovered = await PhotoService.recover();
      if (recovered != null && mounted) {
        await importScorePhoto(
          context,
          controller,
          session,
          recoveredPath: recovered,
        );
      }
    } catch (_) {
      if (mounted) {
        message(
          context,
          'The interrupted photo could not be recovered. You can select it again.',
        );
      }
    }
  }

  static const destinations = <(String, IconData)>[
    ('Tonight', Icons.nights_stay_outlined),
    ('History', Icons.history_rounded),
    ('Insights', Icons.insights_rounded),
    ('My Bag', Icons.sports_baseball_outlined),
    ('Alleys', Icons.location_on_outlined),
  ];
  void _settings() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ProfileSettings(controller: widget.controller),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 850;
        final c = widget.controller;
        final page = switch (_index) {
          0 => TonightPage(
            controller: c,
            onHistory: () => setState(() => _index = 1),
          ),
          1 => HistoryPage(controller: c),
          2 => InsightsPage(controller: c),
          3 => BagPage(controller: c),
          _ => AlleysPage(controller: c),
        };
        return Scaffold(
          appBar: wide
              ? null
              : AppBar(
                  title: const Text(
                    'TallyBowl!',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: _settings,
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 224,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: BowlColors.line)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 32, 16, 8),
                          child: Row(
                            children: [
                              BallArt(size: 30),
                              SizedBox(width: 10),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'TallyBowl!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 24, bottom: 42),
                          child: Text(
                            'A LITTLE HISTORY. EVERY NIGHT.',
                            style: TextStyle(
                              color: BowlColors.muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        for (var i = 0; i < destinations.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              selected: _index == i,
                              selectedTileColor: BowlColors.mint,
                              selectedColor: BowlColors.ink,
                              leading: Icon(destinations[i].$2, size: 22),
                              title: Text(
                                destinations[i].$1,
                                style: TextStyle(
                                  fontWeight: _index == i
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => setState(() => _index = i),
                            ),
                          ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            radius: 17,
                            backgroundColor: BowlColors.canvas,
                            child: Text(
                              c.data.profile.name.isEmpty
                                  ? 'Y'
                                  : c.data.profile.name.characters.first
                                        .toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: BowlColors.ink,
                              ),
                            ),
                          ),
                          title: Text(
                            c.data.profile.name.isEmpty
                                ? 'Your profile'
                                : c.data.profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Settings & backup',
                            style: TextStyle(fontSize: 10),
                          ),
                          onTap: _settings,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (wide)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
                          child: Row(
                            children: [
                              const Text(
                                'YOUR PERSONAL BOWLING JOURNAL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: BowlColors.muted,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 13,
                                color: BowlColors.muted,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Saved on this device',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BowlColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: ValueKey(_index),
                          padding: EdgeInsets.all(wide ? 36 : 20),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: page,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(icon: Icon(d.$2), label: d.$1),
                  ],
                ),
        );
      },
    ),
  );
}
