import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../staff_provider.dart';
import '../staff_shell.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StaffProvider>();
    final today = DateTime.now();
    final groups = <String, List<StaffAlert>>{};
    for (final a in p.alerts) {
      final d = DateTime(a.at.year, a.at.month, a.at.day);
      final diff = DateTime(today.year, today.month, today.day).difference(d).inDays;
      final key = diff == 0 ? 'Today · ${Fmt.dayMonth(a.at)}' : diff == 1 ? 'Yesterday · ${Fmt.dayMonth(a.at)}' : Fmt.dayMonthYear(a.at);
      (groups[key] ??= []).add(a);
    }

    return Column(
      children: [
        StaffPageHeader(title: 'Alerts', badge: p.unreadAlerts > 0 ? 'Unread · ${p.unreadAlerts}' : 'All read'),
        Expanded(
          child: RefreshIndicator(
            color: TgsColors.navy500,
            onRefresh: p.refreshAlerts,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              children: [
                if (p.alerts.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No alerts', style: TextStyle(color: TgsColors.fg3)))),
                for (final e in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 12, 0, 8),
                    child: Eyebrow(e.key),
                  ),
                  for (final a in e.value) ...[
                    _AlertCard(a, onTap: () => p.markAlertRead(a)),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard(this.a, {required this.onTap});
  final StaffAlert a;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (a.severity) {
      'danger' => (Icons.warning_amber_rounded, TgsColors.brick600),
      'warn' => (Icons.schedule_rounded, TgsColors.warning),
      'success' => (Icons.check_rounded, TgsColors.success),
      _ => (Icons.info_outline_rounded, TgsColors.navy500),
    };
    return Container(
      decoration: BoxDecoration(
        color: a.read ? Colors.white : tint.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(TgsRadius.lg),
        border: Border(
          left: BorderSide(color: tint, width: 3),
          top: const BorderSide(color: TgsColors.border1),
          right: const BorderSide(color: TgsColors.border1),
          bottom: const BorderSide(color: TgsColors.border1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TgsRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBox(icon, tint: tint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: TextStyle(fontSize: 13, fontWeight: a.read ? FontWeight.w600 : FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(a.body, style: const TextStyle(fontSize: 12, color: TgsColors.fg2, height: 1.4)),
                      const SizedBox(height: 6),
                      Text('${Fmt.time(a.at)} · ${a.source}', style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3)),
                    ],
                  ),
                ),
                if (!a.read) Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
