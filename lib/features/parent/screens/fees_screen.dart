import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../models/fees.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/brand.dart';
import '../parent_provider.dart';
import '../parent_shell.dart';
import 'child_switcher.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();
    final f = p.fees;
    final child = p.child;

    return Column(
      children: [
        ParentPageHeader(title: 'Fees', badge: p.term?.label),
        Expanded(
          child: f == null || child == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    const ChildSwitcher(),
                    const SizedBox(height: 12),
                    _Receipt(f: f, studentName: child.fullName),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: f.balance <= 0
                                ? null
                                : () => _showPaySheet(context, p.channels),
                            icon: const Icon(Icons.credit_card_rounded, size: 18),
                            label: const Text('Pay now'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _comingSoon(context, 'Statement PDF'),
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('Print'),
                          ),
                        ),
                      ],
                    ),
                    const SectionTitle('Choose a method'),
                    for (final ch in p.channels) ...[
                      _ChannelRow(ch),
                      const SizedBox(height: 8),
                    ],
                    if (f.payments.isNotEmpty) ...[
                      const SectionTitle('Receipts'),
                      TgsCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < f.payments.length; i++) ...[
                              if (i > 0) const Divider(indent: 14, endIndent: 14),
                              _ReceiptRow(f.payments[i]),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  void _showPaySheet(BuildContext context, List<PaymentChannel> channels) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pay school fees', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              const Text(
                'Payments post to the bursar automatically and your receipt appears here within minutes.',
                style: TextStyle(fontSize: 12, color: TgsColors.fg2),
              ),
              const SizedBox(height: 14),
              for (final ch in channels) ...[
                _ChannelRow(ch),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what will be available once the bursar publishes it.')),
    );
  }
}

// ---------------------------------------------------------------------------

class _Receipt extends StatelessWidget {
  const _Receipt({required this.f, required this.studentName});
  final FeeStatement f;
  final String studentName;

  @override
  Widget build(BuildContext context) {
    final cleared = f.balance <= 0;
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
          const FlagStrip(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Statement · $studentName'),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      cleared ? 'Cleared' : Fmt.ugx(f.balance),
                      style: TextStyle(
                        fontFamily: TgsFonts.display,
                        fontSize: 28,
                        color: cleared ? TgsColors.success : TgsColors.fg1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!cleared)
                      Text(
                        f.status == FeeStatus.arrears ? 'overdue' : 'due',
                        style: TextStyle(
                          fontSize: 13,
                          color: f.status == FeeStatus.arrears
                              ? TgsColors.brick600
                              : TgsColors.fg3,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final l in f.lines) _Line(l.label, Fmt.ugxSigned(l.amount)),
                _Line('Paid to date', Fmt.ugxSigned(-f.paid), muted: true),
                const Divider(height: 18),
                _Line('Balance', Fmt.ugx(f.balance), total: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.k, this.v, {this.muted = false, this.total = false});
  final String k, v;
  final bool muted, total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          k,
          style: TextStyle(
            fontSize: total ? 14 : 13,
            fontWeight: total ? FontWeight.w700 : FontWeight.w500,
            color: muted ? TgsColors.success : TgsColors.fg1,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: TgsText.amount(
            size: total ? 16 : 13,
            color: muted
                ? TgsColors.success
                : total
                ? TgsColors.brick600
                : TgsColors.fg1,
          ),
        ),
      ],
    ),
  );
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow(this.ch);
  final PaymentChannel ch;

  @override
  Widget build(BuildContext context) {
    final logo = switch (ch.method) {
      PaymentMethod.mtn => _Logo('MTN', TgsColors.mtnYellow, TgsColors.ink800),
      PaymentMethod.airtel => _Logo('Airtel', TgsColors.airtelRed, Colors.white),
      PaymentMethod.bank => const _Logo.icon(Icons.account_balance_rounded, TgsColors.navy500),
      _ => const _Logo.icon(Icons.payments_outlined, TgsColors.fg2),
    };
    return TgsCard(
      onTap: () => _act(context),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          logo,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(ch.instruction, style: TgsText.mono.copyWith(fontSize: 11)),
              ],
            ),
          ),
          const Chevron(),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context) async {
    final code = RegExp(r'\*\d+#').firstMatch(ch.instruction)?.group(0);
    if (ch.method == PaymentMethod.mtn && code != null) {
      final uri = Uri(scheme: 'tel', path: Uri.encodeComponent(code));
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    await Clipboard.setData(ClipboardData(text: ch.instruction));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ch.title} details copied')),
      );
    }
  }
}

class _Logo extends StatelessWidget {
  const _Logo(this.text, this.bg, this.fg) : icon = null;
  const _Logo.icon(this.icon, this.bg) : text = null, fg = Colors.white;
  final String? text;
  final IconData? icon;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: icon != null
        ? Icon(icon, color: fg, size: 20)
        : Text(
            text!,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
          ),
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.p);
  final Payment p;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: const IconBox(Icons.receipt_long_outlined, tint: TgsColors.success, size: 34),
    title: Text(
      p.receiptNo,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${p.method.label} · ${Fmt.dateTime(p.paidAt)}',
      style: const TextStyle(fontSize: 11, color: TgsColors.fg3),
    ),
    trailing: Text(
      '+${Fmt.ugx(p.amount, prefix: false)}',
      style: TgsText.amount(size: 13, color: TgsColors.success),
    ),
  );
}
