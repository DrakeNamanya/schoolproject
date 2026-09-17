import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/admin.dart';
import '../../../models/user.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Requisitions flow department → bursar → director. Bursar and Director
/// see different action buttons on the same row.
class ProcurementModule extends StatefulWidget {
  const ProcurementModule({super.key});
  @override
  State<ProcurementModule> createState() => _ProcurementModuleState();
}

class _ProcurementModuleState extends State<ProcurementModule> {
  List<Requisition> _all = [];
  int _tab = 0;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.requisitions();
    if (mounted) setState(() => _all = r);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().activeRole;
    final isBursar = role == UserRole.bursar || role == UserRole.admin;
    final isDirector = role == UserRole.director || role == UserRole.admin;

    final pending = _all.where((r) => r.status.pending).toList();
    final approved = _all.where((r) => r.status == RequisitionStatus.approved).toList();
    final po = _all.where((r) => r.status == RequisitionStatus.poRaised).toList();
    final delivered = _all.where((r) => r.status == RequisitionStatus.delivered).toList();
    final rejected = _all.where((r) => r.status == RequisitionStatus.rejected).toList();
    final shown = [pending, approved, po, delivered, rejected][_tab];
    final committed = _all.where((r) => !r.status.pending && r.status != RequisitionStatus.rejected).fold(0, (a, r) => a + r.amount);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Term 2 · procurement pipeline',
        title: 'Requisitions &',
        emphasis: 'purchase orders',
        description: 'Requisitions flow from department → bursar → director. POs are raised only against approved requisitions. Every status change is written to the audit log.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Pipeline exported'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export')),
          FilledButton.icon(onPressed: () => toast(context, 'Departments raise requisitions from the staff app'), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('New requisition')),
        ],
      ),
      KpiGrid([
        Kpi(label: 'Awaiting bursar', value: '${_all.where((r) => r.status == RequisitionStatus.bursar).length}', valueColor: TgsColors.warningText),
        Kpi(label: 'Awaiting director', value: '${_all.where((r) => r.status == RequisitionStatus.director).length}'),
        Kpi(label: 'Approved this term', value: '${approved.length + po.length + delivered.length}', valueColor: TgsColors.success),
        Kpi(label: 'Total committed', value: Fmt.ugx(committed)),
      ]),
      Panel(
        title: 'Pipeline',
        trailing: OutlinedButton(onPressed: () => toast(context, 'Quotation comparison opens per requisition'), child: const Text('Compare quotations', style: TextStyle(fontSize: 12))),
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: PillTabs(tabs: ['Pending (${pending.length})', 'Approved (${approved.length})', 'POs raised (${po.length})', 'Delivered (${delivered.length})', 'Rejected (${rejected.length})'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          ),
          if (shown.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nothing here', style: TextStyle(color: TgsColors.fg3))))
          else
            WebTable(
              columns: const ['Requisition', 'Dept', 'Requester', 'Date', 'Amount', 'Status', 'Action'],
              numeric: const {4},
              flex: const {0: 3, 1: 1, 2: 2, 3: 1, 4: 2, 5: 2, 6: 2},
              rows: [
                for (final r in shown)
                  [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text('${r.ref} · ${r.lines} line item${r.lines == 1 ? '' : 's'}', style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3))]),
                    Cell(r.dept),
                    Cell(r.requester),
                    Cell(Fmt.dayMonthYear(r.date), muted: true),
                    Num(Fmt.ugx(r.amount, prefix: false), bold: true, color: r.status.pending || r.status == RequisitionStatus.rejected ? TgsColors.brick600 : TgsColors.fg1),
                    StatusTag(r.status.label, tone: switch (r.status) { RequisitionStatus.bursar || RequisitionStatus.director => PipTone.warn, RequisitionStatus.rejected => PipTone.due, _ => PipTone.ok }),
                    Align(alignment: Alignment.centerRight, child: _action(r, isBursar: isBursar, isDirector: isDirector)),
                  ],
              ],
            ),
        ]),
      ),
    ]);
  }

  Widget _action(Requisition r, {required bool isBursar, required bool isDirector}) {
    final by = context.read<AuthProvider>().user!.fullName;
    Future<void> set(RequisitionStatus s, String msg) async {
      await _repo.setRequisitionStatus(r.id, s, byName: by);
      if (!mounted) return;
      toast(context, msg);
      _load();
    }
    switch (r.status) {
      case RequisitionStatus.bursar:
        if (!isBursar) return const Cell('Awaiting bursar', muted: true);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          TextButton(onPressed: () => set(RequisitionStatus.rejected, '${r.ref} returned as over budget'), child: const Text('Reject', style: TextStyle(fontSize: 12, color: TgsColors.brick600))),
          FilledButton(onPressed: () => set(RequisitionStatus.director, '${r.ref} forwarded to the Director'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), child: const Text('Review → Director', style: TextStyle(fontSize: 12))),
        ]);
      case RequisitionStatus.director:
        if (!isDirector) return const Cell('Awaiting director', muted: true);
        return FilledButton(onPressed: () => set(RequisitionStatus.approved, '${r.ref} approved · requester notified'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), child: const Text('Sign off', style: TextStyle(fontSize: 12)));
      case RequisitionStatus.approved:
        if (!isBursar) return const Cell('Approved', muted: true);
        return OutlinedButton(onPressed: () => set(RequisitionStatus.poRaised, 'PO raised for ${r.ref}'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), child: const Text('Raise PO', style: TextStyle(fontSize: 12)));
      case RequisitionStatus.poRaised:
        if (!isBursar) return const Cell('PO raised', muted: true);
        return OutlinedButton(onPressed: () => set(RequisitionStatus.delivered, '${r.ref} marked delivered · stores updated'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)), child: const Text('Mark delivered', style: TextStyle(fontSize: 12)));
      case RequisitionStatus.rejected:
        return TextButton(onPressed: () => set(RequisitionStatus.bursar, '${r.ref} re-opened for revision'), child: const Text('Revise', style: TextStyle(fontSize: 12)));
      case RequisitionStatus.delivered:
        return const Icon(Icons.check_circle_outline, size: 18, color: TgsColors.success);
    }
  }
}
