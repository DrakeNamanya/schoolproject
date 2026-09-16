import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../parent_provider.dart';

/// Compact chip row to switch between children on sub-tabs. Hidden when the
/// guardian has only one child.
class ChildSwitcher extends StatelessWidget {
  const ChildSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    if (p.children.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: p.children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = p.children[i];
          final on = i == p.selectedIndex;
          return GestureDetector(
            onTap: () => p.selectChild(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              decoration: BoxDecoration(
                color: on ? TgsColors.brick50 : Colors.white,
                border: Border.all(
                  color: on ? TgsColors.brick300 : TgsColors.border1,
                ),
                borderRadius: BorderRadius.circular(TgsRadius.pill),
              ),
              child: Row(
                children: [
                  InitialsAvatar(
                    s.initials,
                    size: 28,
                    color: on ? TgsColors.brick500 : TgsColors.ink300,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${s.shortName} · ${s.className}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: on ? TgsColors.brick700 : TgsColors.fg2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
