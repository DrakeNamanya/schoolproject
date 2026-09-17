import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';

/// Page head: eyebrow, serif title with italic emphasis, description, actions.
class PageHead extends StatelessWidget {
  const PageHead({
    super.key,
    required this.eyebrow,
    required this.title,
    this.emphasis,
    this.description,
    this.actions = const [],
  });
  final String eyebrow, title;
  final String? emphasis, description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(eyebrow, color: TgsColors.maroon500),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: '$title ',
            style: const TextStyle(fontFamily: TgsFonts.display, fontSize: 30, height: 1.05, letterSpacing: -.3, color: TgsColors.fg1),
            children: [
              if (emphasis != null)
                TextSpan(text: emphasis, style: const TextStyle(fontStyle: FontStyle.italic, color: TgsColors.maroon500)),
            ],
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(description!, style: const TextStyle(fontSize: 13, color: TgsColors.fg2, height: 1.5)),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [head, if (actions.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: actions)]])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: head), const SizedBox(width: 16), Wrap(spacing: 8, children: actions)]),
    );
  }
}

class Kpi extends StatelessWidget {
  const Kpi({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.progress,
    this.progressColor = TgsColors.brick500,
    this.footLeft,
    this.footRight,
    this.trend,
    this.trendUp = true,
    this.valueColor = TgsColors.fg1,
  });
  final String label, value;
  final String? unit, footLeft, footRight, trend;
  final double? progress;
  final Color progressColor, valueColor;
  final bool trendUp;

  @override
  Widget build(BuildContext context) => TgsCard(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TgsColors.fg3)),
        const SizedBox(height: 8),
        Text.rich(TextSpan(
          text: value,
          style: TextStyle(fontFamily: TgsFonts.display, fontSize: 28, height: 1, color: valueColor),
          children: [if (unit != null) TextSpan(text: '  $unit', style: const TextStyle(fontFamily: TgsFonts.sans, fontSize: 11, color: TgsColors.fg3))],
        )),
        if (progress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: progress!.clamp(0, 1), minHeight: 5, backgroundColor: TgsColors.paper2, color: progressColor)),
        ],
        if (footLeft != null || footRight != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            if (footLeft != null) Text(footLeft!, style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
            const Spacer(),
            if (footRight != null) Text(footRight!, style: const TextStyle(fontSize: 10, color: TgsColors.fg3)),
          ]),
        ],
        if (trend != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(trendUp ? Icons.north_east_rounded : Icons.south_east_rounded, size: 12, color: trendUp ? TgsColors.success : TgsColors.brick600),
            const SizedBox(width: 4),
            Text(trend!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: trendUp ? TgsColors.success : TgsColors.brick600)),
          ]),
        ],
      ],
    ),
  );
}

class KpiGrid extends StatelessWidget {
  const KpiGrid(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cols = w > 1180 ? 4 : w > 720 ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: LayoutBuilder(builder: (_, c) {
        final itemW = (c.maxWidth - (cols - 1) * 14) / cols;
        return Wrap(spacing: 14, runSpacing: 14, children: [for (final k in children) SizedBox(width: itemW, child: k)]);
      }),
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, this.trailing, required this.child, this.padding = const EdgeInsets.all(16)});
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => TgsCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (trailing != null) trailing!,
          ]),
        ),
        const Divider(),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class TwoCol extends StatelessWidget {
  const TwoCol({super.key, required this.left, required this.right, this.ratio = 1.6});
  final Widget left, right;
  final double ratio;
  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 980;
    if (narrow) return Column(children: [left, const SizedBox(height: 14), right]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: (ratio * 10).round(), child: left),
      const SizedBox(width: 14),
      Expanded(flex: 10, child: right),
    ]);
  }
}

class StatusTag extends StatelessWidget {
  const StatusTag(this.text, {super.key, this.tone = PipTone.neutral});
  final String text;
  final PipTone tone;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PipTone.ok => (TgsColors.successBg, TgsColors.success),
      PipTone.warn => (TgsColors.warningBg, TgsColors.warningText),
      PipTone.due => (TgsColors.dangerBg, TgsColors.brick600),
      PipTone.info => (TgsColors.infoBg, TgsColors.navy600),
      PipTone.neutral => (TgsColors.paper2, TgsColors.fg2),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(TgsRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

/// Data table with horizontal scroll on narrow screens.
class WebTable extends StatelessWidget {
  const WebTable({super.key, required this.columns, required this.rows, this.numeric = const {}, this.flex = const {}});
  final List<String> columns;
  final List<List<Widget>> rows;
  final Set<int> numeric;
  final Map<int, int> flex; // column -> flex weight (default 1)

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final minW = columns.length * 130.0;
    final table = Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: const TableBorder(horizontalInside: BorderSide(color: TgsColors.border1)),
      columnWidths: {for (var i = 0; i < columns.length; i++) i: FlexColumnWidth((flex[i] ?? 1).toDouble())},
      children: [
        TableRow(
          decoration: const BoxDecoration(color: TgsColors.paper),
          children: [
            for (var i = 0; i < columns.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(columns[i].toUpperCase(), textAlign: numeric.contains(i) ? TextAlign.right : TextAlign.left,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .8, color: TgsColors.fg3)),
              ),
          ],
        ),
        for (final r in rows)
          TableRow(children: [
            for (var i = 0; i < r.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Align(alignment: numeric.contains(i) ? Alignment.centerRight : Alignment.centerLeft, child: r[i]),
              ),
          ]),
      ],
    );
    if (c.maxWidth >= minW) return table;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: SizedBox(width: minW, child: table));
  });
}

class PersonCell extends StatelessWidget {
  const PersonCell(this.name, this.sub, {super.key, this.color = TgsColors.brick500});
  final String name, sub;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final p = name.trim().split(' ');
    final ini = p.length > 1 ? '${p[0][0]}${p[1][0]}' : p[0].isEmpty ? '?' : p[0][0];
    return Row(mainAxisSize: MainAxisSize.min, children: [
      InitialsAvatar(ini.toUpperCase(), size: 30, color: color),
      const SizedBox(width: 10),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3)),
        ]),
      ),
    ]);
  }
}

class Num extends StatelessWidget {
  const Num(this.text, {super.key, this.color = TgsColors.fg1, this.bold = false});
  final String text;
  final Color color;
  final bool bold;
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w500, color: color));
}

class Cell extends StatelessWidget {
  const Cell(this.text, {super.key, this.muted = false});
  final String text;
  final bool muted;
  @override
  Widget build(BuildContext context) => Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: muted ? TgsColors.fg3 : TgsColors.fg1));
}

class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.tabs, required this.index, required this.onChanged});
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (var i = 0; i < tabs.length; i++)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(tabs[i]),
            selected: i == index,
            onSelected: (_) => onChanged(i),
            selectedColor: TgsColors.maroon50,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: i == index ? TgsColors.maroon600 : TgsColors.fg2),
            showCheckmark: false,
          ),
        ),
    ]),
  );
}

/// Stock level row (medicine / kitchen / stores).
class StockRow extends StatelessWidget {
  const StockRow({super.key, required this.name, required this.sub, required this.level, required this.qty, this.low = false});
  final String name, sub, qty;
  final double level;
  final bool low;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(sub, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 10, color: TgsColors.fg3)),
      ])),
      SizedBox(width: 90, child: ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: level.clamp(0, 1), minHeight: 6, backgroundColor: TgsColors.paper2, color: low ? TgsColors.brick500 : level < .5 ? TgsColors.warning : TgsColors.success))),
      const SizedBox(width: 12),
      SizedBox(width: 64, child: Text(qty, textAlign: TextAlign.right, style: TextStyle(fontFamily: TgsFonts.mono, fontSize: 12, fontWeight: FontWeight.w600, color: low ? TgsColors.brick600 : TgsColors.fg1))),
    ]),
  );
}

/// Compact list row with icon, title/sub, trailing.
class ReqRow extends StatelessWidget {
  const ReqRow({super.key, required this.icon, required this.tint, required this.title, required this.sub, this.trailing});
  final IconData icon;
  final Color tint;
  final String title, sub;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      IconBox(icon, tint: tint, size: 34),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
      ])),
      if (trailing != null) ...[const SizedBox(width: 8), trailing!],
    ]),
  );
}

void toast(BuildContext context, String msg, {bool ok = true}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(children: [Icon(ok ? Icons.check_circle_outline : Icons.error_outline, color: ok ? TgsColors.ugYellow : TgsColors.brick200, size: 18), const SizedBox(width: 10), Expanded(child: Text(msg))]),
    width: MediaQuery.sizeOf(context).width > 600 ? 440 : null,
  ));
}
