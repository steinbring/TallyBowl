import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'common.dart';

const bowlDestinations = <(String, IconData)>[
  ('Tonight', Icons.nights_stay_outlined),
  ('History', Icons.history_rounded),
  ('Insights', Icons.insights_rounded),
  ('My Bag', Icons.sports_baseball_outlined),
  ('Alleys', Icons.location_on_outlined),
];

class DesktopBowlRail extends StatelessWidget {
  const DesktopBowlRail({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onSettings,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: selected,
    onDestinationSelected: onSelected,
    labelType: NavigationRailLabelType.none,
    leading: const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: BallArt(size: 30),
    ),
    trailing: IconButton(
      tooltip: 'Settings',
      onPressed: onSettings,
      icon: const Icon(Icons.tune_rounded),
    ),
    destinations: [
      for (final d in bowlDestinations)
        NavigationRailDestination(
          icon: Tooltip(message: d.$1, child: Icon(d.$2)),
          label: Text(d.$1),
        ),
    ],
  );
}

class BowlSidebar extends StatelessWidget {
  const BowlSidebar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onSettings,
    required this.profile,
  });
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onSettings;
  final BowlerProfile profile;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
      1.0,
      1.5,
    );
    return Container(
      width: 224 * scale,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      BallArt(size: 30),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'TallyBowl!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
                  child: Text(
                    'A little history. Every night.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
                for (var i = 0; i < bowlDestinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: selected == i,
                      selectedTileColor: colors.primaryContainer,
                      selectedColor: colors.onPrimaryContainer,
                      leading: Icon(bowlDestinations[i].$2),
                      title: Text(
                        bowlDestinations[i].$1,
                        style: TextStyle(
                          fontWeight: selected == i
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            leading: const Icon(Icons.tune_rounded),
            title: Text(
              profile.name.isEmpty ? 'Your profile' : profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('Settings & backup'),
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}
