import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../staff_provider.dart';
import '../staff_shell.dart';

class TimesheetScreen extends StatelessWidget {
  const TimesheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StaffProvider>();
    final total = p.weekMinutes;
    final target = p.weekTarget;
    final remaining = (target - total).clamp(0, target);
    final pct = target == 0 ? 0.0 : (total / target).clamp(0.0, 1.0);

    return Column(
      children: [
        const StaffPageHeader(title: 'Timesheet', badge: 'Week 5 · Term 2'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              // ---- hero ------------------------------------------------------
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: TgsColors.navy500,
                  borderRadius: BorderRadius.circular(TgsRadius.xl),
                  boxShadow: TgsShadows.sh3,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FlagStrip(height: 4),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('Total logged this week', color: Colors.white60),
                          const SizedBox(height: 4),
                          Text.rich(TextSpan(
                            text: '${total ~/ 60} h ',
                            style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 36, color: Colors.white, height: 1),
                            children: [TextSpan(text: '${(total % 60).toString().padLeft(2, '0')} m', style: const TextStyle(fontSize: 20, color: Colors.white70))],
                          )),
                          const SizedBox(height: 6),
                          Text.rich(TextSpan(
                            text: 'Target ${target ~/ 60} h · ',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            children: [
                              TextSpan(text: formatMinutes(remaining), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                              const TextSpan(text: ' remaining · cut-off Fri 22:00'),
                            ],
                          )),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: Colors.white.withValues(alpha: .15), color: TgsColors.ugYellow),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SectionTitle('This week'),
              TgsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < p.week.length; i++) ...[
                      if (i > 0) const Divider(indent: 14, endIndent: 14),
                      _DayRow(p.week[i]),
                    ],
                  ],
                ),
              ),

              const SectionTitle('Historical'),
              TgsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < p.history.length; i++) ...[
                      if (i > 0) const Divider(indent: 14, endIndent: 14),
                      ListTile(
                        dense: true,
                        title: Text(p.history[i].label.split(' · ').first, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        subtitle: Text(p.history[i].label.split(' · ').last, style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
                        trailing: Text(formatMinutes(p.history[i].minutes), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Hours are computed from geofence events and locked once the bursar approves payroll.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: TgsColors.fg3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow(this.d);
  final TimesheetDay d;

  @override
  Widget build(BuildContext context) {
    final today = d.status == 'in_progress';
    final sched = d.status == 'scheduled';
    return Container(
      color: today ? TgsColors.navy50 : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.date.weekday - 1]} ${d.date.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(d.statusLabel, style: TextStyle(fontSize: 10, color: today ? TgsColors.navy600 : TgsColors.fg3, fontWeight: today ? FontWeight.w700 : null)),
                if (d.lateMinutes > 0) Text('${d.lateMinutes} min late', style: const TextStyle(fontSize: 10, color: TgsColors.warningText)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(d.firstIn == null ? '—' : Fmt.time(d.firstIn!), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 12, color: TgsColors.fg2)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 12, color: TgsColors.fg3)),
                Text(d.lastOut == null ? '—' : Fmt.time(d.lastOut!), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 12, color: TgsColors.fg2)),
              ],
            ),
          ),
          Text(
            sched ? '—' : formatMinutes(d.minutesWorked),
            style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 13, fontWeight: FontWeight.w600, color: sched ? TgsColors.fg3 : TgsColors.fg1),
          ),
        ],
      ),
    );
  }
}
