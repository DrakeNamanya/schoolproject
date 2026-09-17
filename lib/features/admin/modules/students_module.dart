import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../data/mock/demo_store.dart';
import '../../../models/fees.dart';
import '../../../models/student.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Registrar: roster, student profile, enrol (→ creates guardian link that
/// makes the child appear in the parent app).
class StudentsModule extends StatefulWidget {
  const StudentsModule({super.key});
  @override
  State<StudentsModule> createState() => _StudentsModuleState();
}

class _StudentsModuleState extends State<StudentsModule> {
  List<Student> _all = [];
  Student? _sel;
  int _tab = 0;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.students();
    if (!mounted) return;
    setState(() {
      _all = s;
      _sel ??= s.firstOrNull;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoStore.instance;
    final levels = ['All', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6'];
    final filtered = _tab == 0 ? _all : _all.where((s) => s.className.startsWith(levels[_tab])).toList();
    final boarders = _all.where((s) => s.isBoarder).length;
    final s6 = _all.where((s) => s.className.startsWith('S6')).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: '${_all.length} learners · Term 2, 2026',
        title: 'Students',
        emphasis: 'directory',
        description: 'Enrolled learners with fees status, boarding assignment and guardian contact. Enrolling a student links her guardian, which is what makes her appear in the parent app.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Roster import accepts the MoES CSV template'), icon: const Icon(Icons.upload_outlined, size: 16), label: const Text('Import roster')),
          FilledButton.icon(onPressed: _enrol, icon: const Icon(Icons.person_add_alt_1_rounded, size: 16), label: const Text('Enrol student')),
        ],
      ),
      KpiGrid([
        Kpi(label: 'Enrolment', value: '${_all.length}', unit: 'learners', progress: _all.length / 1040, footLeft: '${(_all.length * 100 / 1040).round()}% of 1,040 capacity', footRight: 'Term 2'),
        Kpi(label: 'Boarding', value: '$boarders', trend: _all.isEmpty ? '' : '${boarders * 100 ~/ _all.length}% of enrolment'),
        Kpi(label: 'Day scholars', value: '${_all.length - boarders}', trend: 'vs Term 1', trendUp: false),
        Kpi(label: 'S6 candidates', value: '$s6', unit: 'UNEB', progress: .92, progressColor: TgsColors.maroon500, footLeft: '92% registered', footRight: 'pending'),
      ]),
      TwoCol(
        ratio: 1.7,
        left: Panel(
          title: 'Roster',
          trailing: OutlinedButton(onPressed: () => toast(context, 'CSV exported'), child: const Text('Export CSV', style: TextStyle(fontSize: 12))),
          padding: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: PillTabs(tabs: [for (final l in levels) l == 'All' ? 'All (${_all.length})' : '$l (${_all.where((s) => s.className.startsWith(l)).length})'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
            ),
            WebTable(
              columns: const ['Student', 'Class', 'House', 'Boarding', 'Fees'],
              flex: const {0: 3, 1: 1, 2: 1, 3: 1, 4: 2},
              rows: [
                for (final s in filtered)
                  [
                    InkWell(onTap: () => setState(() => _sel = s), child: PersonCell(s.fullName, s.admissionNo, color: s.id == _sel?.id ? TgsColors.maroon500 : TgsColors.brick500)),
                    Cell(s.className),
                    Cell(s.house),
                    Cell(s.isBoarder ? 'Boarder' : 'Day'),
                    _feeTag(store.feeStatusFor(s.id)),
                  ],
              ],
            ),
          ]),
        ),
        right: _sel == null ? const SizedBox.shrink() : _Profile(_sel!, key: ValueKey(_sel!.id)),
      ),
    ]);
  }

  static Widget _feeTag(FeeStatus st) => switch (st) {
    FeeStatus.arrears => const StatusTag('Arrears', tone: PipTone.due),
    FeeStatus.partial => const StatusTag('Partial', tone: PipTone.warn),
    FeeStatus.cleared => const StatusTag('Cleared', tone: PipTone.ok),
  };

  Future<void> _enrol() async {
    final r = await showDialog<_EnrolResult>(context: context, builder: (_) => const _EnrolDialog());
    if (r == null || !mounted) return;
    final by = context.read<AuthProvider>().user!.fullName;
    final id = DemoStore.instance.nextId('stu');
    final adm = 'TGS/2026/${(700 + _all.length).toString().padLeft(5, '0')}';
    final s = Student(id: id, admissionNo: adm, firstName: r.first, surname: r.surname, className: r.className, house: r.house, isBoarder: r.boarder, dormitory: r.boarder ? 'To be assigned' : null, admittedOn: DateTime.now());
    await _repo.enrolStudent(s, guardianName: r.guardian, guardianPhone: r.phone, byName: by);
    if (!mounted) return;
    toast(context, '${s.fullName} enrolled as $adm · guardian ${r.guardian} linked · Term 2 invoice raised');
    _sel = s;
    _load();
  }
}

class _Profile extends StatelessWidget {
  const _Profile(this.s, {super.key});
  final Student s;
  @override
  Widget build(BuildContext context) {
    final store = DemoStore.instance;
    final sum = store.summaries[s.id];
    final bal = store.balanceFor(s.id);
    final visits = store.clinicVisits.where((v) => v.studentId == s.id).length;
    return TgsCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [TgsColors.maroon500, TgsColors.brick500]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(TgsRadius.xl)),
          ),
          child: Row(children: [
            InitialsAvatar(s.initials, size: 52, color: Colors.white24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.admissionNo} · ${s.className}', style: const TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700, color: Colors.white70)),
              Text(s.fullName, style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 22, color: Colors.white)),
              Text('${s.dateOfBirth == null ? '' : 'Born ${Fmt.dayMonthYear(s.dateOfBirth!)} · '}admitted ${s.admittedOn == null ? '—' : Fmt.dayMonthYear(s.admittedOn!)}', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _attr('House', '${s.house} House'),
            _attr('Boarding', s.isBoarder ? (s.dormitory ?? 'Boarder') : 'Day scholar'),
            _attr('Position', sum?.positionLabel ?? '—'),
            _attr('Attendance', '${sum?.attendancePct.round() ?? 0}%'),
            _attr('Clinic visits', '$visits · Term 2'),
            _attr('Fees balance', bal <= 0 ? 'Cleared' : Fmt.ugx(bal), color: bal <= 0 ? TgsColors.success : TgsColors.brick600),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              FilledButton.icon(onPressed: () => toast(context, 'Report card PDF queued'), icon: const Icon(Icons.print_outlined, size: 14), label: const Text('Print report card', style: TextStyle(fontSize: 12))),
              OutlinedButton.icon(onPressed: () => toast(context, 'Invoice lines are managed in Finance'), icon: const Icon(Icons.receipt_outlined, size: 14), label: const Text('Post invoice', style: TextStyle(fontSize: 12))),
              OutlinedButton(onPressed: () => toast(context, 'Guardian log opens in the next release'), child: const Text('Guardian log', style: TextStyle(fontSize: 12))),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _attr(String k, String v, {Color color = TgsColors.fg1}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 11, color: TgsColors.fg3, fontWeight: FontWeight.w600))),
      Expanded(child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
    ]),
  );
}

class _EnrolResult {
  final String first, surname, className, house, guardian, phone;
  final bool boarder;
  _EnrolResult(this.first, this.surname, this.className, this.house, this.boarder, this.guardian, this.phone);
}

class _EnrolDialog extends StatefulWidget {
  const _EnrolDialog();
  @override
  State<_EnrolDialog> createState() => _EnrolDialogState();
}

class _EnrolDialogState extends State<_EnrolDialog> {
  final _first = TextEditingController(), _sur = TextEditingController(), _g = TextEditingController(), _ph = TextEditingController(text: '+256 7');
  String _cls = 'S1 North', _house = 'Green';
  bool _boarder = true;
  static const _classes = ['S1 North', 'S1 South', 'S2 East', 'S2 West', 'S2 North', 'S2 South', 'S3 East', 'S3 West', 'S3 North', 'S4 East', 'S4 West', 'S5 A', 'S5 B', 'S6 A', 'S6 B'];

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Enrol student', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 22)),
    content: SizedBox(
      width: 460,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: TextField(controller: _sur, decoration: const InputDecoration(labelText: 'Surname'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _first, decoration: const InputDecoration(labelText: 'First name'))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: _cls, decoration: const InputDecoration(labelText: 'Class'), items: [for (final c in _classes) DropdownMenuItem(value: c, child: Text(c))], onChanged: (v) => setState(() => _cls = v!))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(initialValue: _house, decoration: const InputDecoration(labelText: 'House'), items: [for (final h in ['Green', 'Blue', 'Red', 'White']) DropdownMenuItem(value: h, child: Text(h))], onChanged: (v) => setState(() => _house = v!))),
        ]),
        const SizedBox(height: 6),
        SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: const Text('Boarder', style: TextStyle(fontSize: 13)), value: _boarder, onChanged: (v) => setState(() => _boarder = v)),
        const Divider(),
        const Eyebrow('Primary guardian · creates parent login'),
        const SizedBox(height: 8),
        TextField(controller: _g, decoration: const InputDecoration(labelText: 'Guardian full name')),
        const SizedBox(height: 10),
        TextField(controller: _ph, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (SMS + app login)')),
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_first.text.trim().isEmpty || _sur.text.trim().isEmpty || _g.text.trim().isEmpty) return;
          Navigator.pop(context, _EnrolResult(_first.text.trim(), _sur.text.trim(), _cls, _house, _boarder, _g.text.trim(), _ph.text.trim()));
        },
        child: const Text('Enrol & raise invoice'),
      ),
    ],
  );
}
