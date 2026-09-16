import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/staff.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../staff_provider.dart';
import '../staff_shell.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StaffProvider>();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final isToday = p.weekday == now.weekday;

    return Column(
      children: [
        const StaffPageHeader(title: 'Schedule', badge: 'Week 5 · Term 2'),
        // ---- week bar ---------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          child: Row(
            children: List.generate(5, (i) {
              final d = monday.add(Duration(days: i));
              final wd = i + 1;
              final on = wd == p.weekday;
              final today = wd == now.weekday;
              return Expanded(
                child: GestureDetector(
                  onTap: () => p.selectWeekday(wd),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: on ? TgsColors.navy500 : Colors.white,
                      border: Border.all(color: on ? TgsColors.navy500 : today ? TgsColors.navy200 : TgsColors.border1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(const ['M', 'T', 'W', 'T', 'F'][i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: on ? Colors.white70 : TgsColors.fg3)),
                        const SizedBox(height: 2),
                        Text(d.day.toString().padLeft(2, '0'), style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 15, fontWeight: FontWeight.w600, color: on ? Colors.white : TgsColors.fg1)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: p.slots.isEmpty
              ? const Center(child: Text('No lessons scheduled', style: TextStyle(color: TgsColors.fg3)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                  itemCount: p.slots.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _Slot(p.slots[i], isToday ? p.slots[i].stateAt(now) : SlotState.upcoming),
                ),
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot(this.s, this.state);
  final TimetableSlot s;
  final SlotState state;

  @override
  Widget build(BuildContext context) {
    final isNow = state == SlotState.now;
    final done = state == SlotState.done;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNow ? TgsColors.navy500 : Colors.white,
        borderRadius: BorderRadius.circular(TgsRadius.lg),
        border: Border.all(color: isNow ? TgsColors.navy500 : TgsColors.border1),
        boxShadow: isNow ? TgsShadows.sh3 : TgsShadows.sh1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.startsAt, style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 14, fontWeight: FontWeight.w600, color: isNow ? Colors.white : done ? TgsColors.fg3 : TgsColors.fg1)),
                Text(s.endsAt, style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: isNow ? Colors.white60 : TgsColors.fg3)),
              ],
            ),
          ),
          Container(width: 2, height: 30, margin: const EdgeInsets.symmetric(horizontal: 10), color: isNow ? Colors.white24 : done ? TgsColors.success : TgsColors.border1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isNow ? Colors.white : done ? TgsColors.fg2 : TgsColors.fg1, decoration: done ? TextDecoration.lineThrough : null, decorationColor: TgsColors.fg3)),
                if (s.where.isNotEmpty) Text(s.where, style: TextStyle(fontSize: 11, color: isNow ? Colors.white70 : TgsColors.fg3)),
              ],
            ),
          ),
          if (isNow) const Pip('NOW', tone: PipTone.due) else if (done) const Icon(Icons.check_rounded, size: 16, color: TgsColors.success),
        ],
      ),
    );
  }
}
