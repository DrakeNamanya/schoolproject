import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth_provider.dart';
import '../../../core/config.dart';
import '../../../core/format.dart';
import '../../../models/school.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../parent_provider.dart';
import '../parent_shell.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    final auth = context.watch<AuthProvider>();
    final menu = p.todayMenu;

    return Column(
      children: [
        const ParentPageHeader(title: 'More'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              // ---- Menu -----------------------------------------------
              _MenuHero(menu),

              // ---- Events ---------------------------------------------
              const SectionTitle('Upcoming events'),
              if (p.events.isEmpty)
                const TgsCard(child: Text('No upcoming events', style: TextStyle(fontSize: 13, color: TgsColors.fg2)))
              else
                for (final e in p.events) ...[
                  _EventRow(e),
                  const SizedBox(height: 8),
                ],

              // ---- Documents ------------------------------------------
              const SectionTitle('Documents'),
              TgsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < p.documents.length; i++) ...[
                      if (i > 0) const Divider(indent: 52),
                      _DocRow(p.documents[i]),
                    ],
                    if (p.documents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No documents shared yet', style: TextStyle(fontSize: 13, color: TgsColors.fg2)),
                      ),
                  ],
                ),
              ),

              // ---- Settings -------------------------------------------
              const SectionTitle('Settings'),
              TgsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingRow('Notifications', onTap: () => _soon(context)),
                    const Divider(indent: 16),
                    _SettingRow('Language', hint: 'English · Luganda', onTap: () => _soon(context)),
                    const Divider(indent: 16),
                    _SettingRow('Change PIN', onTap: () => _soon(context)),
                    if ((auth.user?.roles.length ?? 0) > 1) ...[
                      const Divider(indent: 16),
                      _SettingRow('Switch role', hint: auth.activeRole?.label, onTap: auth.switchRole),
                    ],
                    const Divider(indent: 16),
                    _SettingRow('Sign out', danger: true, onTap: auth.signOut),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Center(
                child: Text(
                  AppConfig.motto,
                  style: TextStyle(
                    fontFamily: TgsFonts.display,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    color: TgsColors.maroon500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '${AppConfig.schoolName} · ${AppConfig.vendor}',
                  style: const TextStyle(fontSize: 10, color: TgsColors.fg3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _soon(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Coming in the next release')));
}

// ---------------------------------------------------------------------------

class _MenuHero extends StatelessWidget {
  const _MenuHero(this.menu);
  final DayMenu? menu;

  @override
  Widget build(BuildContext context) {
    final date = menu?.date ?? DateTime.now();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TgsColors.navy500,
        borderRadius: BorderRadius.circular(TgsRadius.xl),
        boxShadow: TgsShadows.sh2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FlagStrip(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(Fmt.weekdayDayMonth(date), color: Colors.white60),
                const SizedBox(height: 4),
                const Text(
                  "Today's menu",
                  style: TextStyle(fontFamily: TgsFonts.display, fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 12),
                if (menu == null)
                  const Text('The kitchen has not posted today\'s menu yet.', style: TextStyle(fontSize: 12, color: Colors.white70))
                else
                  Row(
                    children: [
                      _Meal('Breakfast', menu!.breakfast.main, menu!.breakfast.side),
                      _Meal('Lunch', menu!.lunch.main, menu!.lunch.side),
                      _Meal('Supper', menu!.supper.main, menu!.supper.side),
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

class _Meal extends StatelessWidget {
  const _Meal(this.k, this.n, this.s);
  final String k, n, s;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(n, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
          const SizedBox(height: 2),
          Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    ),
  );
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.e);
  final SchoolEvent e;
  @override
  Widget build(BuildContext context) {
    final tint = switch (e.category) {
      EventCategory.academic => TgsColors.brick500,
      EventCategory.coCurricular => TgsColors.navy500,
      EventCategory.community => TgsColors.maroon500,
    };
    return TgsCard(
      padding: const EdgeInsets.all(12),
      color: e.highlight ? TgsColors.maroon50 : Colors.white,
      child: Row(
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: e.highlight ? TgsColors.maroon500 : TgsColors.paper,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(Fmt.monthAbbr(e.startsAt), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: e.highlight ? Colors.white70 : TgsColors.fg3)),
                Text(Fmt.day(e.startsAt), style: TextStyle(fontFamily: TgsFonts.display, fontSize: 20, color: e.highlight ? Colors.white : TgsColors.fg1, height: 1.1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  [e.audience ?? e.venue, Fmt.timeRange(e.startsAt, e.endsAt)].whereType<String>().join(' · '),
                  style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
                ),
              ],
            ),
          ),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  const _DocRow(this.d);
  final SchoolDocument d;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: const Icon(Icons.picture_as_pdf_outlined, color: TgsColors.brick500),
    title: Text(d.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    subtitle: d.subtitle == null ? null : Text(d.subtitle!, style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
    trailing: const Chevron(),
    onTap: () async {
      final uri = Uri.tryParse(d.url);
      if (uri != null && d.url.isNotEmpty && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document will open once the school uploads the file.')),
        );
      }
    },
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.label, {this.hint, this.danger = false, required this.onTap});
  final String label;
  final String? hint;
  final bool danger;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: danger ? TgsColors.brick600 : TgsColors.fg1)),
        if (hint != null) ...[
          const SizedBox(width: 8),
          Text(hint!, style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
        ],
      ],
    ),
    trailing: Chevron(color: danger ? TgsColors.brick500 : TgsColors.fg3),
    onTap: onTap,
  );
}
