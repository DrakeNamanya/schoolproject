import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../data/mock/demo_store.dart';
import '../../../models/admin.dart';
import '../../../models/school.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Director / Headteacher overview.
class DashboardModule extends StatefulWidget {
  const DashboardModule({super.key});
  @override
  State<DashboardModule> createState() => _DashboardModuleState();
}

class _DashboardModuleState extends State<DashboardModule> {
  FinanceKpis? _k;
  List<StaffPresence> _staff = [];
  List<Requisition> _reqs = [];
  List<SchoolEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = context.read<AdminRepository>();
    final k = await r.financeKpis();
    final s = await r.staffPresence();
    final q = await r.requisitions();
    final e = await r.events();
    if (!mounted) return;
    setState(() {
      _k = k;
      _staff = s;
      _reqs = q;
      _events = e..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = _k;
    if (k == null) return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
    final store = DemoStore.instance;
    final inside = _staff.where((s) => s.status == PresenceStatus.inside).length;
    final onDuty = _staff.where((s) => s.status != PresenceStatus.offDuty).length;
    final off = _staff.where((s) => s.status == PresenceStatus.outside).toList();
    final today = DateTime.now();
    final visitsToday = store.clinicVisits.where((v) => v.visitedAt.day == today.day && v.visitedAt.month == today.month).length;
    final lowStock = store.stockItems.where((s) => s.needsReorder).toList();
    final approved = _reqs.where((r) => r.status == RequisitionStatus.approved).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Timbitwire Girls School · Term 2 · 2026',
        title: 'School',
        emphasis: 'overview',
        description: 'Live snapshot across finance, attendance, academics, clinic and operations. As of ${Fmt.weekdayDayMonth(today)}, ${Fmt.time(today)} EAT.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Daily brief queued for print'), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print daily brief')),
          FilledButton.icon(onPressed: () => toast(context, 'Announcements post to all parents & staff'), icon: const Icon(Icons.campaign_outlined, size: 16), label: const Text('Post announcement')),
        ],
      ),
      KpiGrid([
        Kpi(label: 'Enrolment', value: '${store.students.length}', unit: 'learners', trend: '+${store.students.length - 10} this term', trendUp: true),
        Kpi(label: 'Fees collected', value: _m(k.collected), unit: 'of ${_m(k.invoiced)}', progress: k.pct, footLeft: '${(k.pct * 100).round()}% · Term 2', footRight: 'Target 24 Jul'),
        Kpi(label: 'Staff on-campus', value: '$inside', unit: '/ $onDuty', progress: onDuty == 0 ? 0 : inside / onDuty, progressColor: TgsColors.navy500, footLeft: '${onDuty == 0 ? 0 : inside * 100 ~/ onDuty}% checked in', footRight: '${_staff.length - onDuty} off duty'),
        Kpi(label: 'Clinic visits today', value: '$visitsToday', trend: 'vs yesterday', trendUp: false),
      ]),
      TwoCol(
        left: Panel(
          title: 'This week at Timbitwire',
          trailing: TextButton(onPressed: () {}, child: const Text('Full calendar →')),
          child: Column(children: [
            _Timeline(date: today, label: 'Today', title: 'Mid-term marks entry deadline', sub: 'All subject teachers to submit by 22:00 · Academics.', tag: const StatusTag('3 subjects outstanding', tone: PipTone.due), isToday: true),
            for (final e in _events.where((e) => e.startsAt.isAfter(today)).take(3))
              _Timeline(date: e.startsAt, label: _rel(e.startsAt, today), title: e.title, sub: [e.venue ?? e.audience, Fmt.timeRange(e.startsAt, e.endsAt)].whereType<String>().join(' · ')),
          ]),
        ),
        right: Panel(
          title: 'Alerts',
          trailing: TextButton(onPressed: () {}, child: const Text('All alerts →')),
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            for (final s in off) _Alert(icon: Icons.warning_amber_rounded, tint: TgsColors.brick600, title: 'DOS office · off-campus', sub: '${s.name} flagged ${s.time} off during lesson.'),
            for (final s in lowStock.take(2)) _Alert(icon: Icons.warehouse_outlined, tint: TgsColors.warning, title: 'Stores · reorder', sub: '${s.name} at ${s.onHand} ${s.unit} (below ${s.reorderAt}).'),
            _Alert(icon: Icons.credit_card_outlined, tint: TgsColors.navy500, title: 'Finance · new payments', sub: '${Fmt.ugx(k.today)} received today.'),
            if (approved.isNotEmpty) _Alert(icon: Icons.check_rounded, tint: TgsColors.success, title: '${approved.first.ref} approved', sub: '${approved.first.title} · ${Fmt.ugx(approved.first.amount)}.'),
          ]),
        ),
      ),
    ]);
  }

  static String _m(int v) => v >= 1000000 ? 'UGX ${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M' : Fmt.ugx(v);
  static String _rel(DateTime d, DateTime now) {
    final diff = DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff == 1 ? 'Tomorrow' : 'In $diff days';
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.date, required this.label, required this.title, required this.sub, this.tag, this.isToday = false});
  final DateTime date;
  final String label, title, sub;
  final Widget? tag;
  final bool isToday;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 96, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${Fmt.weekdayDayMonth(date).substring(0, 3)} ${Fmt.dayMonth(date)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isToday ? TgsColors.brick600 : TgsColors.fg1)),
        Text(label, style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
      ])),
      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5, right: 12), decoration: BoxDecoration(color: isToday ? TgsColors.brick500 : TgsColors.ink200, shape: BoxShape.circle)),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(fontSize: 11, color: TgsColors.fg2)),
        if (tag != null) Padding(padding: const EdgeInsets.only(top: 6), child: tag),
      ])),
    ]),
  );
}

class _Alert extends StatelessWidget {
  const _Alert({required this.icon, required this.tint, required this.title, required this.sub});
  final IconData icon;
  final Color tint;
  final String title, sub;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: tint.withValues(alpha: .06), borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: tint, width: 3))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: tint),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(fontSize: 11, color: TgsColors.fg2)),
      ])),
    ]),
  );
}
