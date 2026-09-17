import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/admin.dart';
import '../../../theme/tokens.dart';
import '../widgets/web_widgets.dart';

/// Director / Admin: immutable trail. Reads `audit_log` (append-only,
/// populated by triggers on payments, marks, clinic, reports, requisitions).
class AuditModule extends StatefulWidget {
  const AuditModule({super.key});
  @override
  State<AuditModule> createState() => _AuditModuleState();
}

class _AuditModuleState extends State<AuditModule> {
  List<AuditEntry> _log = [];
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    context.read<AdminRepository>().auditLog(limit: 100).then((l) {
      if (mounted) setState(() => _log = l);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = switch (_filter) { 1 => _log.where((e) => e.level == 'w').toList(), 2 => _log.where((e) => e.level == 'd').toList(), _ => _log };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Compliance · Uganda Data Protection Act, 2019',
        title: 'Audit',
        emphasis: 'log',
        description: 'Immutable trail of every sensitive action: fee posting, marks entry, clinic edit, report publication, requisition sign-off, geofence flags. Only Director and administrator roles may export.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Audit CSV exported · ${_log.length} events'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export CSV')),
        ],
      ),
      Panel(
        title: 'Recent activity',
        trailing: Row(children: [
          PillTabs(tabs: ['All (${_log.length})', 'Warnings (${_log.where((e) => e.level == 'w').length})', 'Alerts (${_log.where((e) => e.level == 'd').length})'], index: _filter, onChanged: (i) => setState(() => _filter = i)),
        ]),
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            _Row(shown[i]),
          ],
          if (shown.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No events', style: TextStyle(color: TgsColors.fg3))),
        ]),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.e);
  final AuditEntry e;
  @override
  Widget build(BuildContext context) {
    final (lbl, bg, fg) = switch (e.level) {
      'w' => ('WARN', TgsColors.warningBg, TgsColors.warningText),
      'd' => ('ALERT', TgsColors.dangerBg, TgsColors.brick600),
      _ => ('INFO', TgsColors.paper2, TgsColors.fg2),
    };
    final narrow = MediaQuery.sizeOf(context).width < 900;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: narrow ? 56 : 120, child: Text(narrow ? Fmt.time(e.at) : '${Fmt.dayMonth(e.at)} ${Fmt.time(e.at)}', style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, color: TgsColors.fg3))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(text: e.who, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), children: [TextSpan(text: ' · ${e.role}', style: const TextStyle(fontWeight: FontWeight.w400, color: TgsColors.fg3, fontSize: 11))])),
          Text.rich(TextSpan(text: e.action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TgsColors.fg1), children: [TextSpan(text: ' ${e.detail}', style: const TextStyle(fontWeight: FontWeight.w400, color: TgsColors.fg2))])),
        ])),
        if (!narrow) SizedBox(width: 180, child: Text(e.object, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, color: TgsColors.fg2))),
        const SizedBox(width: 10),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(lbl, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: .8, color: fg))),
      ]),
    );
  }
}
