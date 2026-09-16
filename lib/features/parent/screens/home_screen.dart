import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../models/school.dart';
import '../../../models/student.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../parent_provider.dart';
import 'notices_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});
  final void Function(int tab) onNavigate;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    final user = context.watch<AuthProvider>().user;

    return RefreshIndicator(
      color: TgsColors.brick500,
      onRefresh: p.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // ---- Top bar --------------------------------------------------
          Row(
            children: [
              InitialsAvatar(user?.initials ?? '?'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Fmt.greeting(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: TgsColors.fg3,
                      ),
                    ),
                    Text(
                      user?.displayName ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _Bell(count: p.unreadCount, onTap: () => showNotices(context)),
            ],
          ),
          const SizedBox(height: 14),

          // ---- Child hero (swipeable) --------------------------------------
          if (p.children.isNotEmpty) ...[
            SizedBox(
              height: 168,
              child: PageView.builder(
                controller: PageController(
                  initialPage: p.selectedIndex,
                  viewportFraction: 1,
                ),
                onPageChanged: p.selectChild,
                itemCount: p.children.length,
                itemBuilder: (_, i) => _ChildHero(
                  student: p.children[i],
                  summary: p.summaryFor(p.children[i].id),
                  termLabel: p.term?.shortLabel ?? '',
                ),
              ),
            ),
            if (p.children.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  p.children.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == p.selectedIndex ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == p.selectedIndex
                          ? TgsColors.brick500
                          : TgsColors.ink200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ],

          // ---- Fees --------------------------------------------------------
          const SectionTitle('Fees', top: 14),
          _BalanceCard(onPay: () => onNavigate(1)),

          // ---- School tiles ------------------------------------------------
          const SectionTitle('School'),
          _Tiles(onNavigate: onNavigate),

          // ---- Recent feed -------------------------------------------------
          const SectionTitle('Recent'),
          if (p.notices.isEmpty)
            const TgsCard(
              child: Text(
                'Nothing yet. Receipts, clinic notes and school news will appear here.',
                style: TextStyle(fontSize: 13, color: TgsColors.fg2),
              ),
            )
          else
            TgsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < p.notices.length && i < 4; i++) ...[
                    if (i > 0) const Divider(indent: 56),
                    _FeedItem(p.notices[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Bell extends StatelessWidget {
  const _Bell({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: TgsColors.border1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: TgsColors.fg1,
            ),
          ),
        ),
      ),
      if (count > 0)
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: TgsColors.brick500,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
    ],
  );
}

class _ChildHero extends StatelessWidget {
  const _ChildHero({
    required this.student,
    required this.summary,
    required this.termLabel,
  });
  final Student student;
  final StudentSummary? summary;
  final String termLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TgsRadius.xxl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TgsColors.maroon500, TgsColors.brick500, TgsColors.maroon600],
          stops: [0, .6, 1],
        ),
        boxShadow: TgsShadows.sh3,
      ),
      child: Stack(
        children: [
          const PatternBackdrop(opacity: .10, size: 200),
          const Positioned(top: 0, left: 0, right: 0, child: FlagStrip(height: 4)),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(
                  '${student.house.isEmpty ? 'Timbitwire Girls' : 'Timbitwire Girls'} · $termLabel',
                  color: Colors.white70,
                ),
                const SizedBox(height: 6),
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontFamily: TgsFonts.display,
                    fontSize: 26,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.className} · ${student.house} House · ${student.boardingLabel}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const Spacer(),
                Row(
                  children: [
                    _Stat('Attendance', '${summary?.attendancePct.round() ?? '—'}%'),
                    _Stat('Position', summary?.positionLabel ?? '—'),
                    _Stat('Clinic', '${summary?.clinicVisitsThisTerm ?? 0} · Term'),
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

class _Stat extends StatelessWidget {
  const _Stat(this.k, this.v);
  final String k, v;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          v,
          style: const TextStyle(
            fontFamily: TgsFonts.mono,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onPay});
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    final f = p.fees;
    final balance = f?.balance ?? 0;
    final cleared = balance <= 0;

    return TgsCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance · ${p.term?.shortLabel ?? ''}',
                  style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
                ),
                const SizedBox(height: 2),
                Text(
                  cleared ? 'Cleared' : Fmt.ugx(balance),
                  style: TgsText.amount(
                    size: 24,
                    color: cleared ? TgsColors.success : TgsColors.brick600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cleared
                      ? 'Thank you — no fees outstanding'
                      : f?.term.feesDueOn == null
                      ? ''
                      : 'Due ${Fmt.dayMonth(f!.term.feesDueOn!)} · ${Fmt.relativeDue(f.daysToDue)}',
                  style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onPay,
            style: FilledButton.styleFrom(
              backgroundColor: cleared ? TgsColors.navy500 : TgsColors.brick500,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            icon: Text(cleared ? 'Statement' : 'Pay now'),
            label: const Icon(Icons.arrow_forward_rounded, size: 16),
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.onNavigate});
  final void Function(int) onNavigate;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    final report = p.report;
    final menu = p.todayMenu;
    final nextEvent = p.events.isEmpty ? null : p.events.first;

    final tiles = [
      _Tile(
        icon: Icons.menu_book_outlined,
        tint: TgsColors.brick500,
        title: 'Marks · ${p.term?.shortLabel ?? ''}',
        sub: report == null ? 'Not yet released' : 'Ready · view report card',
        badge: report != null,
        onTap: () => onNavigate(2),
      ),
      _Tile(
        icon: Icons.restaurant_outlined,
        tint: TgsColors.navy500,
        title: 'Feeding menu',
        sub: menu == null ? 'No menu posted' : 'Today · ${menu.lunch.main}',
        onTap: () => onNavigate(4),
      ),
      _Tile(
        icon: Icons.medical_services_outlined,
        tint: TgsColors.maroon500,
        title: 'Clinic history',
        sub: '${p.clinicVisits.length} visits · this term',
        onTap: () => onNavigate(3),
      ),
      _Tile(
        icon: Icons.event_outlined,
        tint: TgsColors.navy500,
        title: 'Events',
        sub: nextEvent == null
            ? 'No upcoming events'
            : '${nextEvent.title.split(' · ').first} · ${Fmt.dayMonth(nextEvent.startsAt)}',
        onTap: () => onNavigate(4),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: tiles,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.sub,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final Color tint;
  final String title, sub;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) => TgsCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBox(icon, tint: tint, size: 32),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
            ),
          ],
        ),
        if (badge)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: TgsColors.brick500,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  );
}

class _FeedItem extends StatelessWidget {
  const _FeedItem(this.n);
  final Notice n;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (n.kind) {
      NoticeKind.payment => (Icons.receipt_long_outlined, TgsColors.success),
      NoticeKind.clinic => (Icons.add_circle_outline, TgsColors.navy500),
      NoticeKind.academics => (Icons.menu_book_outlined, TgsColors.brick500),
      NoticeKind.event => (Icons.event_outlined, TgsColors.maroon500),
      NoticeKind.general => (Icons.campaign_outlined, TgsColors.fg2),
    };
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: IconBox(icon, tint: tint, size: 34),
      title: Text(
        n.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        n.subtitle,
        style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
      ),
      trailing: n.amount == null
          ? null
          : Text(
              '+${Fmt.ugx(n.amount!, prefix: false)}',
              style: TgsText.amount(size: 13, color: TgsColors.success),
            ),
      onTap: () => context.read<ParentProvider>().markRead(n),
    );
  }
}
