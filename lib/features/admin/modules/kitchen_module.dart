import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';
import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/admin.dart';
import '../../../models/school.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

/// Cook: weekly menu editor (→ parent "Today's menu"), kitchen inventory.
class KitchenModule extends StatefulWidget {
  const KitchenModule({super.key});
  @override
  State<KitchenModule> createState() => _KitchenModuleState();
}

class _KitchenModuleState extends State<KitchenModule> {
  List<DayMenu?> _week = [];
  List<StockItem> _stock = [];
  late DateTime _monday;
  AdminRepository get _repo => context.read<AdminRepository>();

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _monday = DateTime(n.year, n.month, n.day - (n.weekday - 1));
    _load();
  }

  Future<void> _load() async {
    final w = await _repo.weekMenu(_monday);
    final s = await _repo.stock();
    if (!mounted) return;
    setState(() {
      _week = w;
      _stock = s.where((i) => i.category == 'Kitchen').toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Kitchen · Week of ${Fmt.dayMonth(_monday)}',
        title: 'Feeding',
        emphasis: 'plan',
        description: 'Weekly menu published to parents — what you enter here is exactly what the guardian sees under "Today\'s menu". Consumption is tracked against roll to spot waste.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Menu queued for print'), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print menu')),
          FilledButton.icon(onPressed: () => toast(context, 'Consumption log opens in the next release'), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Log consumption')),
        ],
      ),
      TwoCol(
        ratio: 2,
        left: Panel(
          title: 'Weekly menu',
          trailing: Row(children: [
            IconButton(onPressed: () => setState(() { _monday = _monday.subtract(const Duration(days: 7)); _load(); }), icon: const Icon(Icons.chevron_left_rounded)),
            Text('${Fmt.dayMonth(_monday)} – ${Fmt.dayMonth(_monday.add(const Duration(days: 6)))}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            IconButton(onPressed: () => setState(() { _monday = _monday.add(const Duration(days: 7)); _load(); }), icon: const Icon(Icons.chevron_right_rounded)),
          ]),
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const Divider(),
              _DayRow(
                date: _monday.add(Duration(days: i)),
                menu: i < _week.length ? _week[i] : null,
                isToday: _monday.add(Duration(days: i)).day == today.day && _monday.add(Duration(days: i)).month == today.month,
                onEdit: () => _edit(_monday.add(Duration(days: i)), i < _week.length ? _week[i] : null),
              ),
            ],
          ]),
        ),
        right: Panel(
          title: 'Kitchen inventory',
          trailing: TextButton(onPressed: () => toast(context, 'Requisition raised to the bursar'), child: const Text('Request stock →')),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            for (final s in _stock) StockRow(name: s.name, sub: '${s.sku} · reorder at ${s.reorderAt} ${s.unit}', level: s.onHand / (s.reorderAt * 2), qty: '${s.onHand} ${s.unit}', low: s.needsReorder),
          ]),
        ),
      ),
    ]);
  }

  Future<void> _edit(DateTime date, DayMenu? m) async {
    final r = await showDialog<DayMenu>(context: context, builder: (_) => _MenuDialog(date: date, initial: m));
    if (r == null || !mounted) return;
    await _repo.setMenu(r, byName: context.read<AuthProvider>().user!.fullName);
    if (!mounted) return;
    toast(context, 'Menu for ${Fmt.weekdayDayMonth(date)} published to parents');
    _load();
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.date, required this.menu, required this.isToday, required this.onEdit});
  final DateTime date;
  final DayMenu? menu;
  final bool isToday;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
    color: isToday ? TgsColors.navy50 : null,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      SizedBox(width: 74, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isToday ? TgsColors.navy600 : TgsColors.fg1)),
        Text(Fmt.dayMonth(date), style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3)),
        if (isToday) const Pip('TODAY', tone: PipTone.info),
      ])),
      if (menu == null)
        const Expanded(child: Text('No menu set', style: TextStyle(fontSize: 12, color: TgsColors.fg3, fontStyle: FontStyle.italic)))
      else ...[
        _Meal('Breakfast', menu!.breakfast), _Meal('Lunch', menu!.lunch), _Meal('Supper', menu!.supper),
      ],
      IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 18), color: TgsColors.fg3, tooltip: 'Edit'),
    ]),
  );
}

class _Meal extends StatelessWidget {
  const _Meal(this.k, this.m);
  final String k;
  final Meal m;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(k.toUpperCase(), style: const TextStyle(fontSize: 8.5, letterSpacing: 1, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
    Text(m.main, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    Text(m.side, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
  ]));
}

class _MenuDialog extends StatefulWidget {
  const _MenuDialog({required this.date, this.initial});
  final DateTime date;
  final DayMenu? initial;
  @override
  State<_MenuDialog> createState() => _MenuDialogState();
}

class _MenuDialogState extends State<_MenuDialog> {
  late final _c = [
    TextEditingController(text: widget.initial?.breakfast.main ?? ''), TextEditingController(text: widget.initial?.breakfast.side ?? ''),
    TextEditingController(text: widget.initial?.lunch.main ?? ''), TextEditingController(text: widget.initial?.lunch.side ?? ''),
    TextEditingController(text: widget.initial?.supper.main ?? ''), TextEditingController(text: widget.initial?.supper.side ?? ''),
  ];

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Menu · ${Fmt.weekdayDayMonth(widget.date)}', style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 22)),
    content: SizedBox(
      width: 460,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < 3; i++) ...[
          Eyebrow(const ['Breakfast', 'Lunch', 'Supper'][i]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(flex: 3, child: TextField(controller: _c[i * 2], decoration: const InputDecoration(labelText: 'Main'))),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: TextField(controller: _c[i * 2 + 1], decoration: const InputDecoration(labelText: 'Side'))),
          ]),
          const SizedBox(height: 12),
        ],
      ]),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(
        onPressed: () => Navigator.pop(context, DayMenu(date: widget.date, breakfast: Meal(_c[0].text.trim(), _c[1].text.trim()), lunch: Meal(_c[2].text.trim(), _c[3].text.trim()), supper: Meal(_c[4].text.trim(), _c[5].text.trim()))),
        child: const Text('Publish'),
      ),
    ],
  );
}
