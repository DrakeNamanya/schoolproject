import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

class ReportsModule extends StatelessWidget {
  const ReportsModule({super.key});

  static const _reports = [
    (Icons.menu_book_outlined, 'Report card', 'Per-learner Term 2 report with grades, attendance, class-teacher comment and headteacher stamp.', 'Generate all'),
    (Icons.credit_card_outlined, 'Fees statement', 'Individual fees statement by student, term, or class. Emits to PDF and SMS one-line summary.', 'Batch export'),
    (Icons.medical_services_outlined, 'Clinic term summary', 'Aggregated clinic visits with confidentiality-preserving initials; issued to headteacher and nurse.', 'Export PDF'),
    (Icons.verified_outlined, 'UNEB · S6 candidate list', 'CSV export in UNEB registration format for S6 candidates. Signed off by DOS.', 'Export CSV'),
    (Icons.bar_chart_rounded, 'EMIS · statutory return', 'Termly EMIS submission: enrolment, teachers, infrastructure. Compliant with MoES schema.', 'Prepare submission'),
    (Icons.timer_outlined, 'Payroll timesheet', 'Hours per staff per week from geofence events, feeds into monthly payroll. Locked once approved.', 'Prepare payroll'),
    (Icons.location_on_outlined, 'Staff attendance daybook', 'Daily check-in/out per staff member with late minutes and off-campus flags.', 'Export PDF'),
    (Icons.inventory_2_outlined, 'Procurement register', 'All requisitions and POs for the term with sign-off trail.', 'Export CSV'),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w > 1180 ? 3 : w > 720 ? 2 : 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const PageHead(
        eyebrow: 'Printable outputs · Term 2 · 2026',
        title: 'Reports &',
        emphasis: 'exports',
        description: 'Branded PDFs and regulator exports. All bear the school header, stamp, signatures and — where relevant — the Uganda flag colour strip.',
      ),
      LayoutBuilder(builder: (_, c) {
        final iw = (c.maxWidth - (cols - 1) * 14) / cols;
        return Wrap(spacing: 14, runSpacing: 14, children: [
          for (final r in _reports)
            SizedBox(
              width: iw,
              child: TgsCard(
                padding: EdgeInsets.zero,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const FlagStrip(height: 3),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      IconBox(r.$1, tint: TgsColors.maroon500, size: 40),
                      const SizedBox(height: 12),
                      Text(r.$2, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(r.$3, style: const TextStyle(fontSize: 12, color: TgsColors.fg2, height: 1.5)),
                      const SizedBox(height: 14),
                      Row(children: [
                        FilledButton(onPressed: () => toast(context, '${r.$2}: ${r.$4.toLowerCase()} queued'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)), child: Text(r.$4, style: const TextStyle(fontSize: 12))),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: () => toast(context, 'Preview renders from live data'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)), child: const Text('Preview', style: TextStyle(fontSize: 12))),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
        ]);
      }),
    ]);
  }
}
