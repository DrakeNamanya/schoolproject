import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/admin.dart';
import '../../../models/fees.dart';
import '../../../models/student.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Bursar: fees collection, arrears table, post payment (→ parent receipt +
/// notice), requisition inbox.
class FinanceModule extends StatefulWidget {
  const FinanceModule({super.key});
  @override
  State<FinanceModule> createState() => _FinanceModuleState();
}

class _FinanceModuleState extends State<FinanceModule> {
  FinanceKpis? _k;
  List<Student> _students = [];
  final Map<String, int> _bal = {};
  final Map<String, FeeStatus> _st = {};
  List<Requisition> _reqs = [];
  List<PaymentRecord> _recent = [];
  int _tab = 0;

  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final k = await _repo.financeKpis();
    final st = await _repo.students();
    _daysToDue = 15; // TODO read terms.fees_due_on via repo
    for (final s in st) {
      _bal[s.id] = await _repo.balance(s.id);
      _st[s.id] = await _repo.feeStatus(s.id);
    }
    final r = await _repo.requisitions();
    final p = await _repo.recentPayments(limit: 8);
    if (!mounted) return;
    setState(() {
      _k = k;
      _students = st;
      _reqs = r;
      _recent = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = _k;
    if (k == null) return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));

    final filtered = switch (_tab) {
      0 => _students.where((s) => _st[s.id] == FeeStatus.arrears).toList(),
      1 => _students.where((s) => _st[s.id] == FeeStatus.partial).toList(),
      2 => _students.where((s) => _st[s.id] == FeeStatus.cleared).toList(),
      _ => _students,
    }..sort((a, b) => (_bal[b.id] ?? 0).compareTo(_bal[a.id] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHead(
          eyebrow: 'Finance · Term 2 · 2026',
          title: 'Fees',
          emphasis: 'collection',
          description: '${Fmt.ugx(k.invoiced)} invoiced across ${_students.length} learners. Every payment posted here appears on the guardian\'s phone within seconds as a receipt.',
          actions: [
            OutlinedButton.icon(onPressed: () => toast(context, 'Term report queued for print'), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print term report')),
            OutlinedButton.icon(onPressed: () => toast(context, 'EMIS export prepared'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export EMIS')),
            FilledButton.icon(onPressed: _postPayment, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Post payment')),
          ],
        ),
        KpiGrid([
          Kpi(label: 'Collected · Term 2', value: _m(k.collected), unit: '/ ${_m(k.invoiced)}', progress: k.pct, footLeft: '${(k.pct * 100).round()}%', footRight: 'Target 92% by 24 Jul'),
          Kpi(label: 'In arrears', value: '${k.arrearsCount}', unit: 'learners', valueColor: TgsColors.brick600, progress: _students.isEmpty ? 0 : k.arrearsCount / _students.length, progressColor: TgsColors.maroon500, footLeft: '${Fmt.ugx(k.outstanding)} outstanding', footRight: '${_students.isEmpty ? 0 : (k.arrearsCount * 100 ~/ _students.length)}% of roll'),
          Kpi(label: 'Today · payments', value: _m(k.today), trend: k.today > 0 ? 'Received today' : 'No payments yet', trendUp: k.today > 0),
          Kpi(label: 'Mobile money share', value: '${k.mtnShare + k.airtelShare}', unit: '%', progress: (k.mtnShare + k.airtelShare) / 100, progressColor: TgsColors.navy500, footLeft: 'MTN ${k.mtnShare}% · Airtel ${k.airtelShare}%', footRight: 'Bank ${k.bankShare}%'),
        ]),
        TwoCol(
          left: Panel(
            title: 'Recent payments',
            trailing: const Text('Live · posts to guardians', style: TextStyle(fontSize: 11, color: TgsColors.fg3)),
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < _recent.length; i++) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ReqRow(
                    icon: Icons.receipt_long_outlined,
                    tint: TgsColors.success,
                    title: '${_name(_recent[i].studentId)} · ${_recent[i].payment.receiptNo}',
                    sub: '${_recent[i].payment.method.label} · ${Fmt.dateTime(_recent[i].payment.paidAt)}',
                    trailing: Num('+${Fmt.ugx(_recent[i].payment.amount, prefix: false)}', color: TgsColors.success, bold: true),
                  ),
                ),
              ],
            ]),
          ),
          right: Panel(
            title: 'Requisitions',
            trailing: TextButton(onPressed: () {}, child: const Text('Director inbox →')),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(children: [
              for (final r in _reqs.take(4))
                ReqRow(
                  icon: Icons.inventory_2_outlined,
                  tint: r.status.pending ? TgsColors.warning : r.status == RequisitionStatus.rejected ? TgsColors.brick500 : TgsColors.navy500,
                  title: r.title,
                  sub: '${r.ref} · ${r.requester} · ${Fmt.dayMonth(r.date)}',
                  trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Num(Fmt.ugx(r.amount), bold: true),
                    const SizedBox(height: 3),
                    StatusTag(r.status.label, tone: r.status.pending ? PipTone.warn : r.status == RequisitionStatus.rejected ? PipTone.due : PipTone.ok),
                  ]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          title: 'Students · balances',
          trailing: Row(children: [
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_list_rounded, size: 14), label: const Text('Filters', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 6),
            FilledButton(onPressed: () => toast(context, 'SMS reminders queued to ${k.arrearsCount + k.partialCount} guardians'), child: const Text('Send SMS reminders', style: TextStyle(fontSize: 12))),
          ]),
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: PillTabs(
                tabs: ['Arrears (${k.arrearsCount})', 'Partial (${k.partialCount})', 'Cleared (${k.clearedCount})', 'All (${_students.length})'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            WebTable(
              columns: const ['Student', 'Class', 'Admission no.', 'Balance', 'Due', 'Status', ''],
              numeric: const {3},
              flex: const {0: 3, 1: 1, 2: 2, 3: 2, 4: 1, 5: 2, 6: 2},
              rows: [
                for (final s in filtered)
                  [
                    PersonCell(s.fullName, s.boardingLabel),
                    Cell(s.className),
                    Num(s.admissionNo, color: TgsColors.fg2),
                    Num((_bal[s.id] ?? 0) <= 0 ? '—' : Fmt.ugx(_bal[s.id]!, prefix: false), color: _st[s.id] == FeeStatus.arrears ? TgsColors.brick600 : _st[s.id] == FeeStatus.partial ? TgsColors.warningText : TgsColors.fg3, bold: true),
                    Cell(_st[s.id] == FeeStatus.cleared ? '—' : Fmt.relativeDue(_daysToDue), muted: true),
                    StatusTag(_st[s.id]!.name[0].toUpperCase() + _st[s.id]!.name.substring(1), tone: switch (_st[s.id]!) { FeeStatus.arrears => PipTone.due, FeeStatus.partial => PipTone.warn, FeeStatus.cleared => PipTone.ok }),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _postPayment(preselect: s), child: const Text('Post payment', style: TextStyle(fontSize: 12)))),
                  ],
              ],
            ),
          ]),
        ),
      ],
    );
  }

  int _daysToDue = 15;

  String _name(String id) => _students.where((s) => s.id == id).map((s) => s.fullName).firstOrNull ?? id;
  static String _m(int v) => v >= 1000000 ? 'UGX ${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M' : Fmt.ugx(v);

  Future<void> _postPayment({Student? preselect}) async {
    final result = await showDialog<(Student, int, PaymentMethod, String?)>(
      context: context,
      builder: (_) => _PostPaymentDialog(students: _students, balances: _bal, preselect: preselect),
    );
    if (result == null || !mounted) return;
    final by = context.read<AuthProvider>().user!.fullName;
    final p = await _repo.postPayment(result.$1.id, result.$2, result.$3, result.$4, byName: by);
    if (!mounted) return;
    toast(context, 'Receipt ${p.receiptNo} · ${Fmt.ugx(p.amount)} posted to ${result.$1.fullName}. Guardian notified.');
    _load();
  }
}

class _PostPaymentDialog extends StatefulWidget {
  const _PostPaymentDialog({required this.students, required this.balances, this.preselect});
  final List<Student> students;
  final Map<String, int> balances;
  final Student? preselect;
  @override
  State<_PostPaymentDialog> createState() => _PostPaymentDialogState();
}

class _PostPaymentDialogState extends State<_PostPaymentDialog> {
  Student? _s;
  final _amt = TextEditingController();
  final _ref = TextEditingController();
  PaymentMethod _m = PaymentMethod.mtn;

  @override
  void initState() {
    super.initState();
    _s = widget.preselect ?? widget.students.first;
  }

  @override
  Widget build(BuildContext context) {
    final bal = widget.balances[_s?.id] ?? 0;
    return AlertDialog(
      title: const Text('Post payment', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 22)),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<Student>(
            initialValue: _s,
            decoration: const InputDecoration(labelText: 'Student'),
            items: [for (final s in widget.students) DropdownMenuItem(value: s, child: Text('${s.fullName} · ${s.className}', style: const TextStyle(fontSize: 13)))],
            onChanged: (v) => setState(() => _s = v),
          ),
          const SizedBox(height: 6),
          Text('Current balance: ${bal <= 0 ? 'cleared' : Fmt.ugx(bal)}', style: TextStyle(fontSize: 12, color: bal > 0 ? TgsColors.brick600 : TgsColors.success, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(controller: _amt, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Amount (UGX)', prefixText: 'UGX ')),
          const SizedBox(height: 12),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _m,
            decoration: const InputDecoration(labelText: 'Method'),
            items: [for (final m in PaymentMethod.values) DropdownMenuItem(value: m, child: Text(m.label, style: const TextStyle(fontSize: 13)))],
            onChanged: (v) => setState(() => _m = v ?? _m),
          ),
          const SizedBox(height: 12),
          TextField(controller: _ref, decoration: const InputDecoration(labelText: 'Reference (MM txn / bank slip)')),
          const SizedBox(height: 8),
          const Text('A receipt and push notification are sent to every guardian linked to this student.', style: TextStyle(fontSize: 11, color: TgsColors.fg3)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final a = int.tryParse(_amt.text) ?? 0;
            if (_s == null || a <= 0) return;
            Navigator.pop(context, (_s!, a, _m, _ref.text.trim().isEmpty ? null : _ref.text.trim()));
          },
          child: const Text('Post & notify'),
        ),
      ],
    );
  }
}
