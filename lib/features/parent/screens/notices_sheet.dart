import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../models/school.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../parent_provider.dart';

Future<void> showNotices(BuildContext context) {
  final provider = context.read<ParentProvider>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const _NoticesSheet(),
    ),
  );
}

class _NoticesSheet extends StatelessWidget {
  const _NoticesSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      maxChildSize: .92,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TgsColors.ink200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                if (p.unreadCount > 0) Pip('${p.unreadCount} unread', tone: PipTone.due),
              ],
            ),
          ),
          Expanded(
            child: p.notices.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications yet',
                      style: TextStyle(color: TgsColors.fg3),
                    ),
                  )
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    itemCount: p.notices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _NoticeTile(p.notices[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile(this.n);
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
    return TgsCard(
      onTap: () => context.read<ParentProvider>().markRead(n),
      padding: const EdgeInsets.all(12),
      color: n.read ? Colors.white : tint.withValues(alpha: .05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon, tint: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: n.read ? FontWeight.w600 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  n.subtitle,
                  style: const TextStyle(fontSize: 12, color: TgsColors.fg2),
                ),
                const SizedBox(height: 4),
                Text(
                  Fmt.dateTime(n.at),
                  style: const TextStyle(
                    fontFamily: TgsFonts.mono,
                    fontSize: 10,
                    color: TgsColors.fg3,
                  ),
                ),
              ],
            ),
          ),
          if (!n.read)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
