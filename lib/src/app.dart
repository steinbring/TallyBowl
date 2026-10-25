import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_controller.dart';
import 'config.dart';
import 'features/insights.dart';
import 'features/inventory.dart';
import 'features/journal.dart';
import 'theme.dart';
import 'ui/common.dart';
import 'ui/branding.dart';
import 'ui/layout.dart';
import 'ui/app_navigation.dart';
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
    darkTheme: tallyBowlDarkTheme,
    themeMode: ThemeMode.system,
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
                  icon: Icon(Icons.storage_outlined),
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
      String? reviewPath;
      final release = await controller.reservePhotoAcquisition(
        allowDraft: true,
      );
      try {
        // Startup cleanup and lost-picker recovery share the same reservation
        // as a new capture, so cleanup cannot delete a concurrently retained file.
        await PhotoService.cleanOrphans(
          controller.data.draft?['sourcePath'] as String?,
        );
        final session = controller.activeSession;
        if (session == null) return;
        if (controller.data.draft != null) {
          if (controller.data.draft?['pendingPhotoReview'] == true) {
            reviewPath = controller.data.draft?['sourcePath'] as String?;
          }
        } else {
          final recovered = await PhotoService.recover();
          if (recovered != null) {
            await controller.beginPhotoReview(session.id, recovered);
            reviewPath = recovered;
          }
        }
      } finally {
        release();
      }
      final session = controller.activeSession;
      if (reviewPath != null && session != null && mounted) {
        await recordOrResumeGame(context, controller, session);
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
        final wide = constraints.maxWidth >= BowlLayout.navigationWidth;
        final desktop =
            !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
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
                  toolbarHeight: BowlLayout.toolbarHeight(context),
                  title: const Row(
                    children: [
                      ExcludeSemantics(child: TallyBowlLogo(size: 34)),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'TallyBowl!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
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
                  BowlSidebar(
                    selected: _index,
                    onSelected: (i) => setState(() => _index = i),
                    onSettings: _settings,
                    profile: c.data.profile,
                  )
                else if (desktop)
                  DesktopBowlRail(
                    selected: _index,
                    onSelected: (i) => setState(() => _index = i),
                    onSettings: _settings,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (wide)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
                          child: Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Text(
                                'YOUR PERSONAL BOWLING JOURNAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Saved on this device',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                              constraints: const BoxConstraints(
                                maxWidth: BowlLayout.dashboardWidth,
                              ),
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
          bottomNavigationBar: wide || desktop
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in bowlDestinations)
                      NavigationDestination(icon: d.$2, label: d.$1),
                  ],
                ),
        );
      },
    ),
  );
}
