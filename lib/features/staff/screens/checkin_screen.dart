import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../staff_provider.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StaffProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;
    final prof = p.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        // ---- brand head ----------------------------------------------------
        Row(
          children: [
            const Crest(size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timbitwire', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 16, height: 1)),
                Text(
                  'STAFF · ${(prof?.department ?? '').toUpperCase()}',
                  style: const TextStyle(fontSize: 9, letterSpacing: 1.6, fontWeight: FontWeight.w700, color: TgsColors.fg3),
                ),
              ],
            ),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: TgsColors.fg1),
              onSelected: (v) {
                if (v == 'switch') auth.switchRole();
                if (v == 'out') auth.signOut();
              },
              itemBuilder: (_) => [
                if (user.roles.length > 1) const PopupMenuItem(value: 'switch', child: Text('Switch role')),
                const PopupMenuItem(value: 'out', child: Text('Sign out')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            InitialsAvatar(user.initials, size: 44, color: TgsColors.navy500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 20, height: 1.1)),
                  const SizedBox(height: 2),
                  Text(
                    '${prof?.staffNo ?? ''} · Day duty · ${prof?.dutyLabel ?? ''}',
                    style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, color: TgsColors.fg3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ---- map ------------------------------------------------------------
        _FenceMap(p),
        const SizedBox(height: 12),

        // ---- check-in card ----------------------------------------------------
        _CheckInCard(p),

        // ---- today's log ----------------------------------------------------
        const SectionTitle("Today's log"),
        TgsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (p.today.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No attendance events yet today.', style: TextStyle(fontSize: 13, color: TgsColors.fg2)),
                ),
              for (var i = 0; i < p.today.length; i++) ...[
                if (i > 0) const Divider(indent: 56),
                _LogRow(p.today[i]),
              ],
            ],
          ),
        ),
        if (p.simulated)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Location is simulated on web and when permission is not granted. On Android the real GPS is used inside your duty window only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: TgsColors.fg3),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _FenceMap extends StatelessWidget {
  const _FenceMap(this.p);
  final StaffProvider p;

  @override
  Widget build(BuildContext context) {
    final fence = p.fence;
    final s = p.sample;
    // Map 0..(radius*2.4) metres to the widget. Pin placed by distance from
    // centre along a fixed bearing so it reads like the prototype.
    const bearing = 0.7;
    final (labelText, labelColor) = switch (p.state) {
      FenceState.inside => ('Inside campus geofence', TgsColors.success),
      FenceState.leaving => ('Exiting geofence', TgsColors.warningText),
      FenceState.outside => ('Outside geofence', TgsColors.brick600),
      FenceState.reentering => ('Approaching geofence', TgsColors.warningText),
      FenceState.unknown => ('Locating…', TgsColors.fg3),
    };

    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth, h = 210.0;
        final scale = fence == null ? 1.0 : (h * .42) / fence.radiusM; // px per metre
        final cx = w * .42, cy = h * .55;
        final d = (s?.distanceM ?? 40).clamp(0, (fence?.radiusM ?? 120) * 2.6).toDouble();
        final px = cx + math.sin(bearing) * d * scale;
        final py = cy - math.cos(bearing) * d * scale;
        final r = (fence?.radiusM ?? 120) * scale;

        return Container(
          height: h,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TgsRadius.xxl),
            gradient: const LinearGradient(colors: [Color(0xFFE8D9D5), TgsColors.paper], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: TgsShadows.sh2,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: .5,
                  child: SvgPicture.asset('assets/images/pattern-blocks.svg', fit: BoxFit.cover),
                ),
              ),
              // fence
              Positioned(
                left: cx - r, top: cy - r,
                child: _PulseRing(radius: r, inside: s?.inside ?? true),
              ),
              // pin
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                left: px - 8, top: py - 8,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: (s?.inside ?? true) ? TgsColors.brick500 : TgsColors.ink600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                ),
              ),
              Positioned(
                left: 12, top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(TgsRadius.pill)),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: labelColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(labelText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor)),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12, bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: TgsColors.ink800.withValues(alpha: .8), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '±${s?.accuracyM.round() ?? '—'} m · ${s?.distanceM.round() ?? '—'} m from centre · r ${fence?.radiusM ?? '—'} m',
                    style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 9, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.radius, required this.inside});
  final double radius;
  final bool inside;
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Container(
      width: widget.radius * 2, height: widget.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TgsColors.brick500.withValues(alpha: .08 + _c.value * .08),
        border: Border.all(color: TgsColors.brick500.withValues(alpha: .55), width: 2, strokeAlign: BorderSide.strokeAlignOutside),
      ),
    ),
  );
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard(this.p);
  final StaffProvider p;

  @override
  Widget build(BuildContext context) {
    final prof = p.profile;
    final inAt = p.lastCheckInAt;
    final (eyebrow, statusText, statusColor, statusIcon, delta, deltaColor) = switch (p.state) {
      FenceState.inside => ('Auto check-in', 'Auto-checked in via geofence', TgsColors.success, Icons.check_rounded, 'On duty', TgsColors.success),
      FenceState.leaving => ('Leaving geofence…', 'Detecting exit', TgsColors.warningText, Icons.radio_button_unchecked, 'Watching', TgsColors.warningText),
      FenceState.outside => ('Auto check-out', p.today.isNotEmpty && p.today.first.kind.isOut ? 'Auto-checked out at ${Fmt.time(p.today.first.at)}' : 'Outside campus', TgsColors.brick600, Icons.warning_amber_rounded, 'Off-campus', TgsColors.brick600),
      FenceState.reentering => ('Re-entering campus…', 'Verifying position', TgsColors.warningText, Icons.radio_button_unchecked, 'Resuming', TgsColors.warningText),
      FenceState.unknown => ('Waiting for location', 'Not yet checked in', TgsColors.fg3, Icons.gps_not_fixed_rounded, 'Pending', TgsColors.fg3),
    };
    final accent = p.state == FenceState.outside ? TgsColors.brick500 : p.state == FenceState.inside ? TgsColors.success : TgsColors.warning;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TgsRadius.xl),
        border: Border.all(color: TgsColors.border1),
        boxShadow: TgsShadows.sh2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4, color: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                          Eyebrow(eyebrow),
                          const SizedBox(height: 4),
                          Text.rich(TextSpan(
                            text: inAt == null ? '--:--' : Fmt.time(inAt),
                            style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 34, height: 1),
                            children: const [TextSpan(text: '  EAT', style: TextStyle(fontFamily: TgsFonts.sans, fontSize: 11, color: TgsColors.fg3))],
                          )),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(Fmt.dayMonthYear(DateTime.now()), style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
                              const Text(' · ', style: TextStyle(color: TgsColors.fg3)),
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Flexible(child: Text(statusText, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Text('AUTO GPS', style: TextStyle(fontSize: 8, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
                        Switch(
                          value: prof?.autoCheckin ?? true,
                          activeTrackColor: TgsColors.success,
                          onChanged: p.setAutoCheckin,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _KV('Scheduled', prof?.dutyStart ?? '—'),
                    _KV('Grace', '${p.fence?.graceMinutes ?? 15} min'),
                    _KV('Status', delta, color: deltaColor),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: p.sample == null ? null : p.manualToggle,
                        style: OutlinedButton.styleFrom(foregroundColor: TgsColors.navy600, padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: Icon(p.checkedIn ? Icons.logout_rounded : Icons.login_rounded, size: 16),
                        label: Text(p.checkedIn ? 'Manual check-out' : 'Manual check-in'),
                      ),
                    ),
                    if (p.simulated) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: p.demoRunning ? null : p.runDemoTrip,
                          style: FilledButton.styleFrom(backgroundColor: TgsColors.navy500, padding: const EdgeInsets.symmetric(vertical: 12)),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Demo trip'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV(this.k, this.v, {this.color = TgsColors.fg1});
  final String k, v;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
        const SizedBox(height: 2),
        Text(v, style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
}

class _LogRow extends StatelessWidget {
  const _LogRow(this.e);
  final AttendanceEvent e;
  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (e.kind) {
      AttendanceKind.autoIn || AttendanceKind.manualIn => (Icons.check_rounded, TgsColors.success),
      AttendanceKind.autoOut || AttendanceKind.manualOut => (Icons.logout_rounded, TgsColors.navy500),
      AttendanceKind.flaggedOffCampus => (Icons.warning_amber_rounded, TgsColors.brick600),
    };
    return ListTile(
      dense: true,
      leading: IconBox(icon, tint: tint, size: 34),
      title: Text(e.kind.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        e.kind == AttendanceKind.flaggedOffCampus
            ? '${e.distanceM?.round() ?? 0} m from campus · DOS notified'
            : 'Main campus · ±${e.accuracyM?.round() ?? 0} m accuracy',
        style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
      ),
      trailing: Text(Fmt.time(e.at), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
