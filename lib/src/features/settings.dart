import '../ui/layout.dart';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_controller.dart';
import '../config.dart';
import '../data/bowl_store.dart';
import '../data/exports.dart';
import '../domain/models.dart';
import '../ui/common.dart';
import '../ui/branding.dart';
import '../ui/dialogs.dart';
import 'app_document.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key, required this.controller});
  final BowlController controller;
  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  bool _busy = false;
  late Future<BowlData?> _safety;
  late final Future<PackageInfo?> _package = _loadPackage();

  Future<PackageInfo?> _loadPackage() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _safety = BowlExports.safetyData();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) message(context, 'Could not complete that action. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(BuildContext buttonContext, String type) async {
    final data = widget.controller.data;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final value = switch (type) {
      'backup' => BowlStore.encodeBackup(data),
      'games' => BowlExports.gameCsv(data),
      _ => BowlExports.deliveryCsv(data),
    };
    await BowlExports.exportFile(
      buttonContext,
      name: 'tallybowl-$type-$today.${type == 'backup' ? 'json' : 'csv'}',
      mime: type == 'backup' ? 'application/json' : 'text/csv',
      bytes: BowlExports.textBytes(value),
    );
  }

  Future<void> _restore() async {
    if (widget.controller.isAcquiringPhoto) {
      throw StateError('Finish or cancel the open photo picker first.');
    }
    const type = XTypeGroup(
      label: 'TallyBowl backups',
      extensions: ['json'],
      mimeTypes: ['application/json'],
      uniformTypeIdentifiers: ['public.json'],
    );
    final file = await openFile(acceptedTypeGroups: [type]);
    if (file == null) return;
    final incoming = await BowlExports.readBackupFile(file);
    if (!mounted) return;
    final approved = await confirm(
      context,
      'Restore this journal?',
      'This backup has ${incoming.sessions.length} sessions, ${incoming.games.length} games, ${incoming.balls.length} balls, and ${incoming.alleys.length} alleys.\n\nIt will replace this device’s current journal. A recovery copy of your current records will be kept on this device.',
      action: 'Restore backup',
    );
    if (!approved || !mounted) return;
    if (widget.controller.isAcquiringPhoto) {
      throw StateError('Finish or cancel the open photo picker first.');
    }
    await BowlExports.safetyCopy(widget.controller.data);
    await widget.controller.restore(incoming);
    if (mounted) {
      setState(() => _safety = BowlExports.safetyData());
      message(
        context,
        'Journal restored. You can recover the previous journal below.',
      );
    }
  }

  Future<void> _recover(BowlData previous) async {
    if (await confirm(
          context,
          'Recover your previous journal?',
          'Replace the current journal with the ${previous.games.length} games and ${previous.sessions.length} sessions saved immediately before the last restore?',
          action: 'Recover journal',
        ) &&
        mounted) {
      await widget.controller.restore(previous);
      if (mounted) message(context, 'Previous journal recovered.');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: BowlLayout.toolbarHeight(context),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: BowlLayout.settingsWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeading(
                  'Make it yours.',
                  'Your profile and personal bowling journal.',
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: Text(
                      widget.controller.data.profile.name.isEmpty
                          ? 'Set up your bowler profile'
                          : widget.controller.data.profile.name,
                    ),
                    subtitle: Text(
                      widget.controller.data.profile.aliases.isEmpty
                          ? 'Add your scoreboard names and nicknames.'
                          : widget.controller.data.profile.aliases.join(', '),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _busy
                        ? null
                        : () => editProfile(context, widget.controller),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keep your history safe.',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Save a full backup of your records and unfinished frame draft. Original scoreboard photos are not included. On iPad and Android, choose Files or another destination from the share sheet.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Builder(
                              builder: (c) => FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() => _export(c, 'backup')),
                                icon: const Icon(Icons.save_alt_rounded),
                                label: const Text('Export backup'),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : () => _run(_restore),
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text('Restore backup'),
                            ),
                          ],
                        ),
                        FutureBuilder<BowlData?>(
                          future: _safety,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Text(
                                  'The previous recovery copy could not be read. Your current journal has not been changed.',
                                ),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          _run(() => _recover(snapshot.data!)),
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text(
                                  'Recover journal from before last restore',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Take a closer look.',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Export games or individual deliveries as CSV for your own analysis. Use a full backup to move or restore your journal.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            Builder(
                              builder: (c) => OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() => _export(c, 'games')),
                                icon: const Icon(Icons.table_chart_outlined),
                                label: const Text('Export games CSV'),
                              ),
                            ),
                            Builder(
                              builder: (c) => OutlinedButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          _run(() => _export(c, 'deliveries')),
                                icon: const Icon(Icons.view_list_outlined),
                                label: const Text('Export deliveries CSV'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your game stays yours.',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your bowling records are stored locally on this device. Image recognition runs on the device. Android uses bundled Google ML Kit, which may send SDK diagnostics such as device details, image dimensions, timing, and errors to Google. TallyBowl does not upload your photos or bowling records for recognition. Original scoreboard photos stay with unfinished drafts and are removed after saving or discarding them. Maps download tiles from the map service. An alley search sends only the search words to Photon, using OpenStreetMap data. Saved alleys and game recording work offline.',
                          style: TextStyle(
                            height: 1.7,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final document in AppDocument.values)
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AppDocumentPage(document: document),
                              ),
                            ),
                            icon: Icon(
                              document == AppDocument.guide
                                  ? Icons.help_outline_rounded
                                  : Icons.privacy_tip_outlined,
                            ),
                            label: Text(document.title),
                          ),
                        const SizedBox(height: 20),
                        const TallyBowlLogo(size: 64),
                        const SizedBox(height: 12),
                        const Text(
                          AppConfig.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        const Text(AppConfig.tagline),
                        FutureBuilder<PackageInfo?>(
                          future: _package,
                          builder: (context, snapshot) => Text(
                            snapshot.data == null
                                ? 'Version information unavailable'
                                : 'Version ${snapshot.data!.version} '
                                      '(build ${snapshot.data!.buildNumber})',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _run(() async {
                            if (!await launchUrl(
                              Uri.parse(AppConfig.website),
                            )) {
                              throw StateError('Could not open the website.');
                            }
                          }),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: const Text(AppConfig.websiteLabel),
                        ),
                        TextButton(
                          onPressed: () => showLicensePage(
                            context: context,
                            applicationName: AppConfig.name,
                          ),
                          child: const Text('Open-source licenses'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
