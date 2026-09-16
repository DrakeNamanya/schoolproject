import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../models/clinic.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../parent_provider.dart';
import '../parent_shell.dart';
import 'child_switcher.dart';

class ClinicScreen extends StatelessWidget {
  const ClinicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    final visits = p.clinicVisits;
    final child = p.child;
    final last = visits.isEmpty ? null : visits.first;
    final followUp = visits.where((v) => v.outcome == VisitOutcome.followUp || v.outcome == VisitOutcome.observing).length;

    return Column(
      children: [
        ParentPageHeader(title: 'Clinic', badge: child?.shortName),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const ChildSwitcher(),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat('Visits · Term', '${visits.length}'),
                  const SizedBox(width: 8),
                  _Stat('Last visit', last == null ? '—' : _relative(last.visitedAt)),
                  const SizedBox(width: 8),
                  _Stat('Follow-up', followUp == 0 ? 'None' : '$followUp open'),
                ],
              ),
              const SectionTitle('Recent visits'),
              if (visits.isEmpty)
                const TgsCard(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      IconBox(Icons.favorite_border_rounded, tint: TgsColors.success, size: 48),
                      SizedBox(height: 12),
                      Text('No clinic visits this term', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text(
                        'The school nurse records every visit here, with vitals and any follow-up.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: TgsColors.fg2),
                      ),
                    ],
                  ),
                )
              else
                for (final v in visits) ...[
                  _VisitCard(v),
                  const SizedBox(height: 10),
                ],
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Clinic records are visible only to you, the class teacher and clinic staff.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: TgsColors.fg3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _relative(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff d ago';
    return Fmt.dayMonth(d);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.k, this.v);
  final String k, v;
  @override
  Widget build(BuildContext context) => Expanded(
    child: TgsCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(fontSize: 10, color: TgsColors.fg3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            v,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 18),
          ),
        ],
      ),
    ),
  );
}

class _VisitCard extends StatelessWidget {
  const _VisitCard(this.v);
  final ClinicVisit v;

  @override
  Widget build(BuildContext context) {
    final tone = switch (v.outcome) {
      VisitOutcome.discharged => PipTone.ok,
      VisitOutcome.observing => PipTone.warn,
      VisitOutcome.followUp => PipTone.warn,
      VisitOutcome.referred => PipTone.due,
    };
    return TgsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.complaint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(Fmt.dateTime(v.visitedAt), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, color: TgsColors.fg3)),
                  ],
                ),
              ),
              Pip(v.followUpNote ?? v.outcome.label, tone: tone),
            ],
          ),
          const SizedBox(height: 10),
          Text(v.notes, style: const TextStyle(fontSize: 13, height: 1.5, color: TgsColors.fg2)),
          if (v.vitals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final vt in v.vitals) _VitalChip(vt)],
            ),
          ],
          if (v.referralFacility != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_hospital_outlined, size: 14, color: TgsColors.brick600),
                const SizedBox(width: 6),
                Text('Referred to ${v.referralFacility}', style: const TextStyle(fontSize: 12, color: TgsColors.brick600, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const Divider(height: 22),
          Text.rich(
            TextSpan(
              text: 'Recorded by ',
              style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
              children: [
                TextSpan(text: v.recordedBy, style: const TextStyle(fontWeight: FontWeight.w700, color: TgsColors.fg1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  const _VitalChip(this.v);
  final Vital v;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: TgsColors.paper,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: TgsColors.border1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(v.label, style: const TextStyle(fontSize: 10, color: TgsColors.fg3, fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        Text(v.value, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
