import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../data/mock/demo_store.dart';
import '../../../models/academics.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// DOS: review compiled report cards and publish them to parents. Also the
/// marks-grid view (teachers enter on the phone app; DOS can override here).
class AcademicsModule extends StatefulWidget {
  const AcademicsModule({super.key});
  @override
  State<AcademicsModule> createState() => _AcademicsModuleState();
}

class _AcademicsModuleState extends State<AcademicsModule> {
  List<ReportCard> _rcs = [];
  ReportCard? _sel;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _repo.reportCards();
    if (!mounted) return;
    setState(() {
      _rcs = r;
      _sel = _sel == null ? r.firstWhere((x) => !x.isPublished, orElse: () => r.first) : r.firstWhere((x) => x.id == _sel!.id, orElse: () => r.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoStore.instance;
    final review = _rcs.where((r) => r.status == ReportStatus.review).length;
    final published = _rcs.where((r) => r.isPublished).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Academics · Term 2 · 2026',
        title: 'Report cards &',
        emphasis: 'marks',
        description: 'Teachers enter marks on the phone app (locked 7 days after each assessment). Compiled report cards wait here for review — parents see nothing until you publish.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Marks import accepts CSV per class/subject'), icon: const Icon(Icons.upload_outlined, size: 16), label: const Text('Import CSV')),
          FilledButton.icon(
            onPressed: review == 0 ? null : _publishAll,
            icon: const Icon(Icons.publish_rounded, size: 16),
            label: Text('Publish all in review ($review)'),
          ),
        ],
      ),
      KpiGrid([
        Kpi(label: 'Awaiting review', value: '$review', valueColor: review > 0 ? TgsColors.warningText : TgsColors.fg1, trend: 'Compiled by class teachers', trendUp: true),
        Kpi(label: 'Published · Term 2', value: '$published', unit: '/ ${_rcs.length}', progress: _rcs.isEmpty ? 0 : published / _rcs.length, progressColor: TgsColors.success),
        const Kpi(label: 'Marks entry windows open', value: '2', unit: 'assessments', footLeft: 'Physics S3E CAT 2 · Math S2E CAT 2', footRight: 'lock in 5–6 d'),
        const Kpi(label: 'Subjects outstanding', value: '3', valueColor: TgsColors.brick600, footLeft: 'Mid-term marks due 22:00', footRight: 'Chemistry, CRE, Art'),
      ]),
      TwoCol(
        ratio: 1.1,
        left: Panel(
          title: 'Report cards · Term 2',
          padding: EdgeInsets.zero,
          child: WebTable(
            columns: const ['Student', 'Class', 'Position', 'Status', ''],
            flex: const {0: 3, 1: 1, 2: 1, 3: 2, 4: 2},
            rows: [
              for (final r in _rcs)
                [
                  InkWell(onTap: () => setState(() => _sel = r), child: PersonCell(_name(store, r.studentId), _adm(store, r.studentId), color: r.id == _sel?.id ? TgsColors.maroon500 : TgsColors.brick500)),
                  Cell(r.className),
                  Num(r.position == null ? '—' : '${r.position} / ${r.classSize}'),
                  StatusTag(switch (r.status) { ReportStatus.draft => 'Draft', ReportStatus.review => 'In review', ReportStatus.published => 'Published' }, tone: switch (r.status) { ReportStatus.draft => PipTone.neutral, ReportStatus.review => PipTone.warn, ReportStatus.published => PipTone.ok }),
                  Align(
                    alignment: Alignment.centerRight,
                    child: r.isPublished
                        ? Text(r.publishedAt == null ? '' : Fmt.dayMonth(r.publishedAt!), style: const TextStyle(fontSize: 11, color: TgsColors.fg3))
                        : TextButton(onPressed: () => _publish(r), child: const Text('Publish', style: TextStyle(fontSize: 12))),
                  ),
                ],
            ],
          ),
        ),
        right: _sel == null ? const SizedBox.shrink() : _Preview(_sel!, _name(store, _sel!.studentId), onPublish: _sel!.isPublished ? null : () => _publish(_sel!)),
      ),
    ]);
  }

  String _name(DemoStore s, String id) => s.students.where((x) => x.id == id).map((x) => x.fullName).firstOrNull ?? id;
  String _adm(DemoStore s, String id) => s.students.where((x) => x.id == id).map((x) => x.admissionNo).firstOrNull ?? '';

  Future<void> _publish(ReportCard r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publish report card?'),
        content: Text('${_name(DemoStore.instance, r.studentId)} · ${r.termLabel}\n\nThe guardian will be notified immediately and can view and download it from the parent app. Marks become read-only.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Publish')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.publishReport(r.id, byName: context.read<AuthProvider>().user!.fullName);
    if (!mounted) return;
    toast(context, 'Report card published · guardian of ${_name(DemoStore.instance, r.studentId)} notified');
    _load();
  }

  Future<void> _publishAll() async {
    final by = context.read<AuthProvider>().user!.fullName;
    final list = _rcs.where((r) => r.status == ReportStatus.review).toList();
    for (final r in list) {
      await _repo.publishReport(r.id, byName: by);
    }
    if (!mounted) return;
    toast(context, '${list.length} report cards published · guardians notified');
    _load();
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.rc, this.name, {required this.onPublish});
  final ReportCard rc;
  final String name;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) => TgsCard(
    padding: EdgeInsets.zero,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const FlagStrip(height: 4),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow('Preview · ${rc.termLabel}'),
              const SizedBox(height: 4),
              Text(name, style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 22)),
              Text('${rc.className} · ${rc.positionLabel}', style: const TextStyle(fontSize: 12, color: TgsColors.fg2)),
            ])),
            StatusTag(rc.isPublished ? 'Published' : 'In review', tone: rc.isPublished ? PipTone.ok : PipTone.warn),
          ]),
          const SizedBox(height: 14),
          Table(
            columnWidths: const {0: FlexColumnWidth(2.2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(.9)},
            border: const TableBorder(horizontalInside: BorderSide(color: TgsColors.border1), top: BorderSide(color: TgsColors.border1), bottom: BorderSide(color: TgsColors.border1)),
            children: [
              const TableRow(decoration: BoxDecoration(color: TgsColors.paper), children: [
                _H('SUBJECT'), _H('CAT', right: true), _H('EXAM', right: true), _H('GRADE', center: true),
              ]),
              for (final r in rc.results)
                TableRow(children: [
                  _C(Text(r.subject, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  _C(Num('${r.catScore}/${r.catOutOf}', color: TgsColors.fg2), right: true),
                  _C(Num('${r.examScore}/${r.examOutOf}', color: TgsColors.fg2), right: true),
                  _C(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: r.grade.startsWith('D') ? TgsColors.maroon500 : TgsColors.navy50, borderRadius: BorderRadius.circular(6)), child: Text(r.grade, style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, fontWeight: FontWeight.w600, color: r.grade.startsWith('D') ? Colors.white : TgsColors.navy600))), center: true),
                ]),
            ],
          ),
          if (rc.classTeacherComment != null) ...[
            const SizedBox(height: 12),
            const Eyebrow("Class teacher's comment"),
            const SizedBox(height: 4),
            Text(rc.classTeacherComment!, style: const TextStyle(fontSize: 12, height: 1.5)),
            Text('— ${rc.classTeacherName ?? ''}', style: const TextStyle(fontFamily: TgsFonts.display, fontStyle: FontStyle.italic, fontSize: 12, color: TgsColors.maroon600)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: onPublish, icon: const Icon(Icons.publish_rounded, size: 16), label: Text(rc.isPublished ? 'Published' : 'Publish to parent'))),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => toast(context, 'PDF generation runs once the headteacher stamps'), icon: const Icon(Icons.picture_as_pdf_outlined, size: 16), label: const Text('PDF')),
          ]),
        ]),
      ),
    ]),
  );
}

class _H extends StatelessWidget {
  const _H(this.t, {this.right = false, this.center = false});
  final String t;
  final bool right, center;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    child: Text(t, textAlign: center ? TextAlign.center : right ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: .8, color: TgsColors.fg3)),
  );
}

class _C extends StatelessWidget {
  const _C(this.child, {this.right = false, this.center = false});
  final Widget child;
  final bool right, center;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
    child: Align(alignment: center ? Alignment.center : right ? Alignment.centerRight : Alignment.centerLeft, child: child),
  );
}
