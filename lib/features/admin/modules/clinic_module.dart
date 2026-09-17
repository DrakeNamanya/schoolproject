import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../data/mock/demo_store.dart';
import '../../../models/admin.dart';
import '../../../models/clinic.dart';
import '../../../models/student.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Nurse: daybook, record a visit (→ parent Clinic tab + notice),
/// medicine stock, referrals.
class ClinicModule extends StatefulWidget {
  const ClinicModule({super.key});
  @override
  State<ClinicModule> createState() => _ClinicModuleState();
}

class _ClinicModuleState extends State<ClinicModule> {
  List<ClinicVisit> _today = [];
  List<ClinicVisit> _refs = [];
  List<MedicineStock> _meds = [];
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await _repo.clinicVisitsToday();
    final r = await _repo.referralsThisTerm();
    final m = await _repo.medicines();
    if (!mounted) return;
    setState(() {
      _today = t;
      _refs = r;
      _meds = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoStore.instance;
    final observing = _today.where((v) => v.outcome == VisitOutcome.observing).length;
    final low = _meds.where((m) => m.low).toList();
    final wide = MediaQuery.sizeOf(context).width > 1180;

    final visitsPanel = Panel(
      title: "Today's visits",
      trailing: Text(Fmt.time(DateTime.now()), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, color: TgsColors.fg3)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _today.isEmpty
          ? const Padding(padding: EdgeInsets.all(12), child: Text('No visits recorded today.', style: TextStyle(fontSize: 12, color: TgsColors.fg3)))
          : Column(children: [
              for (final v in _today)
                ReqRow(
                  icon: Icons.add_rounded,
                  tint: switch (v.outcome) { VisitOutcome.discharged => TgsColors.success, VisitOutcome.observing => TgsColors.warning, VisitOutcome.followUp => TgsColors.navy500, VisitOutcome.referred => TgsColors.brick600 },
                  title: '${_name(store, v.studentId)} · ${_cls(store, v.studentId)}',
                  sub: '${v.complaint}${v.treatment == null ? '' : ' · ${v.treatment}'}',
                  trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Num(Fmt.time(v.visitedAt)),
                    const SizedBox(height: 3),
                    StatusTag(v.outcome.label, tone: switch (v.outcome) { VisitOutcome.discharged => PipTone.ok, VisitOutcome.observing => PipTone.warn, VisitOutcome.followUp => PipTone.info, VisitOutcome.referred => PipTone.due }),
                  ]),
                ),
            ]),
    );
    final stockPanel = Panel(
      title: 'Medicine stock',
      trailing: TextButton(onPressed: () => toast(context, 'Issue vouchers decrement stock automatically'), child: const Text('Issue voucher →')),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: [for (final m in _meds) StockRow(name: m.name, sub: '${m.batch} · exp ${m.expiry}', level: m.level, qty: '${m.qty} ${m.unit}', low: m.low)]),
    );
    final refPanel = Panel(
      title: 'Referrals · this term',
      trailing: Text('All ${_refs.length} with parent consent', style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: [
        for (final v in _refs)
          ReqRow(icon: Icons.local_hospital_outlined, tint: TgsColors.navy500, title: v.referralFacility ?? 'Referral', sub: '${_name(store, v.studentId)} · ${_cls(store, v.studentId)} · ${Fmt.dayMonthYear(v.visitedAt)}', trailing: const StatusTag('In progress', tone: PipTone.warn)),
        if (_refs.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No referrals this term.', style: TextStyle(fontSize: 12, color: TgsColors.fg3))),
      ]),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'School clinic · ${Fmt.dayMonthYear(DateTime.now())}',
        title: 'Clinic',
        emphasis: 'daybook',
        description: 'Visits, vitals, medicine issuance and referrals. A recorded visit is visible only to clinic staff, the class teacher and the guardian — who is notified on her phone.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Daybook queued for print'), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print daybook')),
          FilledButton.icon(onPressed: _record, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Record a visit')),
        ],
      ),
      KpiGrid([
        Kpi(label: 'Visits today', value: '${_today.length}', trend: 'vs yesterday', trendUp: false),
        Kpi(label: 'Under observation', value: '$observing', valueColor: observing > 0 ? TgsColors.warningText : TgsColors.fg1, footLeft: 'Rest in sanatorium', footRight: ''),
        Kpi(label: 'Referrals', value: '${_refs.length}', unit: 'this term', footLeft: _refs.isEmpty ? '' : _refs.first.referralFacility ?? '', footRight: ''),
        Kpi(label: 'Medicine stock alerts', value: '${low.length}', valueColor: low.isEmpty ? TgsColors.fg1 : TgsColors.brick600, footLeft: low.map((m) => m.name.split(' ').first).take(2).join(' · '), footRight: 'low'),
      ]),
      if (wide)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: visitsPanel), const SizedBox(width: 14), Expanded(child: stockPanel), const SizedBox(width: 14), Expanded(child: refPanel),
        ])
      else ...[
        TwoCol(left: visitsPanel, right: stockPanel), const SizedBox(height: 14), refPanel,
      ],
    ]);
  }

  String _name(DemoStore s, String id) => s.students.where((x) => x.id == id).map((x) => x.fullName).firstOrNull ?? id;
  String _cls(DemoStore s, String id) => s.students.where((x) => x.id == id).map((x) => x.className).firstOrNull ?? '';

  Future<void> _record() async {
    final students = await _repo.students();
    if (!mounted) return;
    final v = await showDialog<ClinicVisit>(context: context, builder: (_) => _VisitDialog(students: students, nurse: context.read<AuthProvider>().user!.displayName));
    if (v == null || !mounted) return;
    await _repo.recordVisit(v, byName: context.read<AuthProvider>().user!.fullName);
    if (!mounted) return;
    toast(context, 'Visit recorded for ${_name(DemoStore.instance, v.studentId)} · guardian notified');
    _load();
  }
}

class _VisitDialog extends StatefulWidget {
  const _VisitDialog({required this.students, required this.nurse});
  final List<Student> students;
  final String nurse;
  @override
  State<_VisitDialog> createState() => _VisitDialogState();
}

class _VisitDialogState extends State<_VisitDialog> {
  Student? _s;
  final _complaint = TextEditingController(), _notes = TextEditingController(), _treat = TextEditingController();
  final _temp = TextEditingController(), _bp = TextEditingController(), _pulse = TextEditingController(), _wt = TextEditingController();
  VisitOutcome _out = VisitOutcome.discharged;
  final _follow = TextEditingController(), _facility = TextEditingController();

  @override
  void initState() {
    super.initState();
    _s = widget.students.first;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record clinic visit', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 22)),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<Student>(initialValue: _s, decoration: const InputDecoration(labelText: 'Student'), items: [for (final s in widget.students) DropdownMenuItem(value: s, child: Text('${s.fullName} · ${s.className}', style: const TextStyle(fontSize: 13)))], onChanged: (v) => setState(() => _s = v)),
          const SizedBox(height: 10),
          TextField(controller: _complaint, decoration: const InputDecoration(labelText: 'Complaint (e.g. Headache · mild fever)')),
          const SizedBox(height: 10),
          TextField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes')),
          const SizedBox(height: 10),
          TextField(controller: _treat, decoration: const InputDecoration(labelText: 'Treatment / medicine issued')),
          const SizedBox(height: 12),
          const Eyebrow('Vitals'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _temp, decoration: const InputDecoration(labelText: 'Temp °C'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _bp, decoration: const InputDecoration(labelText: 'BP'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _pulse, decoration: const InputDecoration(labelText: 'Pulse'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _wt, decoration: const InputDecoration(labelText: 'Wt kg'))),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<VisitOutcome>(initialValue: _out, decoration: const InputDecoration(labelText: 'Outcome'), items: [for (final o in VisitOutcome.values) DropdownMenuItem(value: o, child: Text(o.label))], onChanged: (v) => setState(() => _out = v ?? _out)),
          if (_out == VisitOutcome.followUp) ...[const SizedBox(height: 10), TextField(controller: _follow, decoration: const InputDecoration(labelText: 'Follow-up note (e.g. Follow up 24 h)'))],
          if (_out == VisitOutcome.referred) ...[const SizedBox(height: 10), TextField(controller: _facility, decoration: const InputDecoration(labelText: 'Referral facility'))],
        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_s == null || _complaint.text.trim().isEmpty) return;
          final vitals = <Vital>[
            if (_temp.text.isNotEmpty) Vital('Temp', '${_temp.text}°C'),
            if (_bp.text.isNotEmpty) Vital('BP', _bp.text),
            if (_pulse.text.isNotEmpty) Vital('Pulse', _pulse.text),
            if (_wt.text.isNotEmpty) Vital('Wt', '${_wt.text} kg'),
          ];
          Navigator.pop(context, ClinicVisit(
            id: DemoStore.instance.nextId('cv'), studentId: _s!.id, visitedAt: DateTime.now(),
            complaint: _complaint.text.trim(), notes: _notes.text.trim(), treatment: _treat.text.trim().isEmpty ? null : _treat.text.trim(),
            vitals: vitals, outcome: _out, followUpNote: _out == VisitOutcome.followUp && _follow.text.isNotEmpty ? _follow.text.trim() : null,
            referralFacility: _out == VisitOutcome.referred ? _facility.text.trim() : null, recordedBy: widget.nurse,
          ));
        },
        child: const Text('Record & notify guardian'),
      ),
    ],
  );
}
