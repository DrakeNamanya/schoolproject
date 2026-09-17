import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../data/admin_repository.dart';
import '../../../models/admin.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../widgets/web_widgets.dart';

class StoresModule extends StatefulWidget {
  const StoresModule({super.key});
  @override
  State<StoresModule> createState() => _StoresModuleState();
}

class _StoresModuleState extends State<StoresModule> {
  List<StockItem> _all = [];
  int _tab = 0;
  static const _cats = ['All', 'Stationery', 'Kitchen', 'Uniforms', 'Cleaning', 'Low stock'];

  @override
  void initState() {
    super.initState();
    context.read<AdminRepository>().stock().then((s) {
      if (mounted) setState(() => _all = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final low = _all.where((s) => s.needsReorder).toList();
    final shown = switch (_tab) { 0 => _all, 5 => low, _ => _all.where((s) => s.category == _cats[_tab]).toList() };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageHead(
        eyebrow: 'Stores · Term 2 · 2026',
        title: 'Inventory &',
        emphasis: 'issue vouchers',
        description: 'Physical goods held on-site: stationery, uniforms, cleaning, kitchen supplies. Reorder alerts fire when quantity dips below the reorder point. Issue vouchers decrement stock automatically.',
        actions: [
          OutlinedButton.icon(onPressed: () => toast(context, 'Stock take sheet queued for print'), icon: const Icon(Icons.print_outlined, size: 16), label: const Text('Print stock take')),
          FilledButton.icon(onPressed: () => toast(context, 'Issue voucher form opens in the next release'), icon: const Icon(Icons.add_rounded, size: 16), label: const Text('Issue voucher')),
        ],
      ),
      KpiGrid([
        Kpi(label: 'SKUs tracked', value: '${_all.length}'),
        Kpi(label: 'Reorder alerts', value: '${low.length}', valueColor: low.isEmpty ? TgsColors.fg1 : TgsColors.brick600),
        const Kpi(label: 'Vouchers this week', value: '23'),
        const Kpi(label: 'Stock value', value: 'UGX 118M'),
      ]),
      Panel(
        title: 'Stock items',
        trailing: OutlinedButton(onPressed: () => toast(context, 'Stock take started'), child: const Text('Stock take', style: TextStyle(fontSize: 12))),
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: PillTabs(tabs: [for (var i = 0; i < _cats.length; i++) '${_cats[i]} (${i == 0 ? _all.length : i == 5 ? low.length : _all.where((s) => s.category == _cats[i]).length})'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          ),
          WebTable(
            columns: const ['Item', 'Category', 'On hand', 'Reorder point', 'Last issued', 'Status'],
            numeric: const {2, 3},
            flex: const {0: 3, 1: 1, 2: 1, 3: 1, 4: 2, 5: 2},
            rows: [
              for (final s in shown)
                [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text(s.sku, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3))]),
                  Cell(s.category),
                  Num('${s.onHand} ${s.unit}', bold: true, color: s.needsReorder ? TgsColors.brick600 : TgsColors.fg1),
                  Num('${s.reorderAt} ${s.unit}', color: TgsColors.fg2),
                  Cell(s.lastIssued, muted: true),
                  s.needsReorder ? const StatusTag('Reorder', tone: PipTone.due) : s.watch ? const StatusTag('Watch', tone: PipTone.warn) : const StatusTag('OK', tone: PipTone.ok),
                ],
            ],
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Text('Reorder threshold and unit costs are managed by the bursar. ${Fmt.ugx(118000000)} valuation uses last purchase price.', style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
    ]);
  }
}
