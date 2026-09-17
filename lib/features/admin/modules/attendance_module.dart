import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/admin.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// DOS / Director: live staff geofence map, today's presence list, rule
/// configuration. Reads v_staff_presence.
class AttendanceModule extends StatefulWidget {
  const AttendanceModule({super.key});
  @override
  State<AttendanceModule> createState() => _AttendanceModuleState();
}

class _AttendanceModuleState extends State<AttendanceModule> {
  List<StaffPresence> _staff = [];

  @override
  void initState() {
    super.initState();
    context.read<AdminRepository>().staffPresence().then((s) {
      if (mounted) setState(() => _staff = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inside = _staff.where((s) => s.status == PresenceStatus.inside).toList();
    final outside = _staff.where((s) => s.status == PresenceStatus.outside).toList();
    final onDuty = _staff.where((s) => s.status != PresenceStatus.offDuty).length;
    final late = _staff.where((s) => s.detail.contains('late')).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Staff GPS attendance · ${Fmt.dayMonthYear(DateTime.now())}',
        title: 'Staff',
        emphasis: 'geofence',
        description: 'Live positions of all ${_staff.length} staff members from the phone app. Anyone crossing the campus geofence is automatically checked in; anyone leaving during class hours raises an alert to the DOS.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Daybook queued for print'), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print daybook')),
          FilledButton.icon(onPressed: () => toast(context, 'Geofence editor: drag the boundary on the map (next release)'), icon: const Icon(Icons.edit_location_alt_outlined, size: 16), label: const Text('Edit geofence')),
        ],
      ),
      KpiGrid([
        Kpi(label: 'On-campus now', value: '${inside.length}', unit: '/ $onDuty', valueColor: TgsColors.success, progress: onDuty == 0 ? 0 : inside.length / onDuty, progressColor: TgsColors.success, footLeft: '${onDuty == 0 ? 0 : inside.length * 100 ~/ onDuty}%', footRight: '${_staff.length - onDuty} off duty'),
        Kpi(label: 'Auto check-ins today', value: '${inside.length + outside.length}', unit: 'events', trend: 'Avg. entry 07:34', trendUp: true),
        Kpi(label: 'Late arrivals', value: '$late', valueColor: TgsColors.warningText, footLeft: '>15 min past 07:30', footRight: 'Grace applied'),
        Kpi(label: 'Off-campus alerts', value: '${outside.length}', valueColor: outside.isEmpty ? TgsColors.fg1 : TgsColors.brick600, footLeft: outside.isEmpty ? 'None' : '${outside.first.name} · ${outside.first.time}', footRight: outside.isEmpty ? '' : 'Escalated · DOS'),
      ]),
      TwoCol(
        ratio: 1.5,
        left: Panel(
          title: 'Campus geofence · live',
          trailing: const Text('±6 m · GPS + cell', style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3)),
          padding: const EdgeInsets.all(12),
          child: _Map(_staff),
        ),
        right: Panel(
          title: 'Staff · today',
          trailing: TextButton(onPressed: () {}, child: const Text('All staff →')),
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < _staff.length; i++) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: switch (_staff[i].status) { PresenceStatus.inside => TgsColors.successBg, PresenceStatus.outside => TgsColors.dangerBg, PresenceStatus.offDuty => TgsColors.paper2 }),
                    child: Icon(switch (_staff[i].status) { PresenceStatus.inside => Icons.check_rounded, PresenceStatus.outside => Icons.warning_amber_rounded, PresenceStatus.offDuty => Icons.remove_rounded }, size: 14,
                        color: switch (_staff[i].status) { PresenceStatus.inside => TgsColors.success, PresenceStatus.outside => TgsColors.brick600, PresenceStatus.offDuty => TgsColors.fg3 }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_staff[i].name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(_staff[i].role, style: const TextStyle(fontSize: 10.5, color: TgsColors.fg3)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Num(_staff[i].time, bold: true, color: _staff[i].status == PresenceStatus.outside ? TgsColors.brick600 : TgsColors.fg1),
                    Text(_staff[i].detail, style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
                  ]),
                ]),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Panel(
        title: 'Auto check-in rule',
        trailing: const Text('Configuration · least-privilege', style: TextStyle(fontSize: 11, color: TgsColors.fg3)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: const Text(
              "When a staff member's device enters the campus geofence during their scheduled duty window, the system automatically posts a check-in event to their timesheet — no manual button-tap needed. GPS is only sampled inside the duty window to protect privacy under the Uganda Data Protection and Privacy Act, 2019.",
              style: TextStyle(fontSize: 13, color: TgsColors.fg2, height: 1.5),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: const [_Cfg('Geofence radius', '120 m'), SizedBox(width: 40), _Cfg('Grace period', '15 minutes'), SizedBox(width: 40), _Cfg('Sampling', 'Duty window only')]),
        ]),
      ),
    ]);
  }
}

class _Cfg extends StatelessWidget {
  const _Cfg(this.k, this.v);
  final String k, v;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Eyebrow(k),
    const SizedBox(height: 2),
    Text(v, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 18, fontWeight: FontWeight.w600)),
  ]);
}

class _Map extends StatelessWidget {
  const _Map(this.staff);
  final List<StaffPresence> staff;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 10,
    child: LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final cx = w * .32, cy = h * .48, r = h * .34;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TgsRadius.lg),
          gradient: const LinearGradient(colors: [Color(0xFFE8D9D5), TgsColors.paper], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(children: [
          Positioned.fill(child: Opacity(opacity: .45, child: SvgPicture.asset('assets/images/pattern-blocks.svg', fit: BoxFit.cover))),
          Positioned(
            left: cx - r, top: cy - r,
            child: Container(width: r * 2, height: r * 2, decoration: BoxDecoration(shape: BoxShape.circle, color: TgsColors.brick500.withValues(alpha: .10), border: Border.all(color: TgsColors.brick500.withValues(alpha: .55), width: 2))),
          ),
          for (final s in staff.where((s) => s.status != PresenceStatus.offDuty))
            Positioned(
              left: s.x * w - 7, top: s.y * h - 7,
              child: Tooltip(
                message: '${s.name} · ${s.detail}',
                child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: s.status == PresenceStatus.inside ? TgsColors.success : TgsColors.brick500, border: Border.all(color: Colors.white, width: 2.5), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))])),
              ),
            ),
          Positioned(
            left: 12, top: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Lg(TgsColors.success, 'Inside · ${staff.where((s) => s.status == PresenceStatus.inside).length}'),
                _Lg(TgsColors.brick500, 'Off-campus · ${staff.where((s) => s.status == PresenceStatus.outside).length}'),
                const _Lg(TgsColors.brick300, 'Boundary · 120 m'),
              ]),
            ),
          ),
        ]),
      );
    }),
  );
}

class _Lg extends StatelessWidget {
  const _Lg(this.c, this.t);
  final Color c;
  final String t;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 6), Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))]));
}
