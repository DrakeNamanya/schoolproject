import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/school.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Registrar / Director: month calendar, add event (→ parent Events +
/// notice; 48 h reminder handled server-side).
class EventsModule extends StatefulWidget {
  const EventsModule({super.key});
  @override
  State<EventsModule> createState() => _EventsModuleState();
}

class _EventsModuleState extends State<EventsModule> {
  List<SchoolEvent> _events = [];
  late DateTime _month;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    _load();
  }

  Future<void> _load() async {
    final e = await _repo.events();
    if (mounted) setState(() => _events = e);
  }

  @override
  Widget build(BuildContext context) {
    final first = _month;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1; // Monday = 0
    final cells = <DateTime?>[...List.filled(leading, null), for (var d = 1; d <= daysInMonth; d++) DateTime(_month.year, _month.month, d)];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final today = DateTime.now();
    final upcoming = _events.where((e) => e.startsAt.isAfter(today.subtract(const Duration(hours: 12)))).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'School calendar · ${_monthName(_month)}',
        title: 'Events',
        emphasis: 'calendar',
        description: 'Academic diary, MDD, sports, PTA and Visitation days. Adding an event posts it to every guardian\'s app; push + SMS reminders go out 48 h before.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'ICS export prepared'), icon: const Icon(Icons.download_outlined, size: 16), label: const Text('Export ICS')),
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Add event')),
        ],
      ),
      TwoCol(
        ratio: 2.2,
        left: Panel(
          title: _monthName(_month),
          trailing: Row(children: [
            TextButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), child: const Text('‹ Prev')),
            TextButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), child: const Text('Next ›')),
          ]),
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) Expanded(child: Center(child: Text(d.toUpperCase(), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: .8, color: TgsColors.fg3))))]),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: MediaQuery.sizeOf(context).width > 1100 ? 1.35 : 1,
              children: [
                for (final d in cells)
                  d == null
                      ? const SizedBox.shrink()
                      : _DayCell(
                          date: d,
                          isToday: d.year == today.year && d.month == today.month && d.day == today.day,
                          events: _events.where((e) => e.startsAt.year == d.year && e.startsAt.month == d.month && e.startsAt.day == d.day).toList(),
                          onTap: () => _add(date: d),
                        ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: const [
              _Legend(TgsColors.brick500, 'Academic'), SizedBox(width: 14),
              _Legend(TgsColors.navy500, 'Co-curricular'), SizedBox(width: 14),
              _Legend(TgsColors.maroon500, 'Community & spiritual'),
            ]),
          ]),
        ),
        right: Panel(
          title: 'Upcoming',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            for (final e in upcoming.take(8))
              ReqRow(
                icon: Icons.event_outlined,
                tint: _tint(e.category),
                title: e.title,
                sub: '${Fmt.weekdayDayMonth(e.startsAt)} · ${Fmt.timeRange(e.startsAt, e.endsAt)}${e.venue != null ? ' · ${e.venue}' : ''}',
                trailing: e.highlight ? const StatusTag('Highlight', tone: PipTone.due) : null,
              ),
          ]),
        ),
      ),
    ]);
  }

  static Color _tint(EventCategory c) => switch (c) { EventCategory.academic => TgsColors.brick500, EventCategory.coCurricular => TgsColors.navy500, EventCategory.community => TgsColors.maroon500 };
  static String _monthName(DateTime d) => '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][d.month - 1]} ${d.year}';

  Future<void> _add({DateTime? date}) async {
    final e = await showDialog<SchoolEvent>(context: context, builder: (_) => _EventDialog(date: date ?? DateTime.now().add(const Duration(days: 1))));
    if (e == null || !mounted) return;
    await _repo.addEvent(e, byName: context.read<AuthProvider>().user!.fullName);
    if (!mounted) return;
    toast(context, '"${e.title}" added · all guardians notified');
    _load();
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.date, required this.isToday, required this.events, required this.onTap});
  final DateTime date;
  final bool isToday;
  final List<SchoolEvent> events;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isToday ? TgsColors.brick50 : TgsColors.paper,
        border: Border.all(color: isToday ? TgsColors.brick300 : TgsColors.border1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(date.day.toString().padLeft(2, '0'), style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, fontWeight: FontWeight.w600, color: isToday ? TgsColors.brick600 : TgsColors.fg2)),
        const SizedBox(height: 2),
        for (final e in events.take(2))
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: _EventsModuleState._tint(e.category), borderRadius: BorderRadius.circular(4)),
            child: Text(e.title.split(' · ').first, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        if (events.length > 2) Text('+${events.length - 2}', style: const TextStyle(fontSize: 9, color: TgsColors.fg3)),
      ]),
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.c, this.t);
  final Color c;
  final String t;
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 6), Text(t, style: const TextStyle(fontSize: 11, color: TgsColors.fg2))]);
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.date});
  final DateTime date;
  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _title = TextEditingController(), _venue = TextEditingController(), _aud = TextEditingController();
  late DateTime _date = widget.date;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  EventCategory _cat = EventCategory.academic;
  bool _highlight = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add event', style: TextStyle(fontFamily: TgsFonts.display, fontSize: 22)),
    content: SizedBox(
      width: 460,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2026), lastDate: DateTime(2027)); if (d != null) setState(() => _date = d); }, icon: const Icon(Icons.event_outlined, size: 16), label: Text(Fmt.dayMonthYear(_date)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: () async { final t = await showTimePicker(context: context, initialTime: _start); if (t != null) setState(() => _start = t); }, icon: const Icon(Icons.schedule_rounded, size: 16), label: Text('${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}'))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue')),
        const SizedBox(height: 10),
        TextField(controller: _aud, decoration: const InputDecoration(labelText: 'Audience (e.g. Boarding parents)')),
        const SizedBox(height: 10),
        DropdownButtonFormField<EventCategory>(initialValue: _cat, decoration: const InputDecoration(labelText: 'Category'), items: const [DropdownMenuItem(value: EventCategory.academic, child: Text('Academic')), DropdownMenuItem(value: EventCategory.coCurricular, child: Text('Co-curricular')), DropdownMenuItem(value: EventCategory.community, child: Text('Community & spiritual'))], onChanged: (v) => setState(() => _cat = v ?? _cat)),
        SwitchListTile(contentPadding: EdgeInsets.zero, dense: true, title: const Text('Highlight for parents (e.g. Visitation Day)', style: TextStyle(fontSize: 13)), value: _highlight, onChanged: (v) => setState(() => _highlight = v)),
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isEmpty) return;
          Navigator.pop(context, SchoolEvent(
            id: '', title: _title.text.trim(),
            startsAt: DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute),
            venue: _venue.text.trim().isEmpty ? null : _venue.text.trim(), audience: _aud.text.trim().isEmpty ? null : _aud.text.trim(),
            category: _cat, highlight: _highlight,
          ));
        },
        child: const Text('Add & notify'),
      ),
    ],
  );
}
