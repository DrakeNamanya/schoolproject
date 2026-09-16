import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// Uganda flag strip: black / yellow / red. Signature accent from the brand.
class FlagStrip extends StatelessWidget {
  const FlagStrip({super.key, this.height = 4, this.radius = 0});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: const Row(
          children: [
            Expanded(child: ColoredBox(color: TgsColors.ugBlack)),
            Expanded(child: ColoredBox(color: TgsColors.ugYellow)),
            Expanded(child: ColoredBox(color: TgsColors.ugRed)),
          ],
        ),
      ),
    );
  }
}

class Crest extends StatelessWidget {
  const Crest({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/timbitwire-crest.svg',
    width: size,
    height: size,
  );
}

/// Faint brick pattern used behind hero cards.
class PatternBackdrop extends StatelessWidget {
  const PatternBackdrop({super.key, this.opacity = .12, this.size = 160});
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Opacity(
      opacity: opacity,
      child: SvgPicture.asset(
        'assets/images/pattern-blocks.svg',
        fit: BoxFit.none,
        alignment: Alignment.bottomRight,
        width: size,
        height: size,
      ),
    ),
  );
}

/// Section heading with the signature maroon underline.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.top = 20});
  final String text;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 3),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: TgsColors.maroon500, width: 3),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: TgsFonts.sans,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: TgsColors.fg1,
              ),
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = TgsColors.fg3});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontFamily: TgsFonts.sans,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
      color: color,
    ),
  );
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(
    this.initials, {
    super.key,
    this.size = 38,
    this.color = TgsColors.brick500,
  });
  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Text(
      initials,
      style: TextStyle(
        fontFamily: TgsFonts.display,
        fontSize: size * .38,
        color: Colors.white,
      ),
    ),
  );
}

/// Small status pill: ok / warn / due / info.
enum PipTone { ok, warn, due, info, neutral }

class Pip extends StatelessWidget {
  const Pip(this.text, {super.key, this.tone = PipTone.neutral});
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TgsRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: TgsFonts.sans,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Standard white card with rose-grey border.
class TgsCard extends StatelessWidget {
  const TgsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = TgsRadius.xl,
    this.onTap,
    this.color = Colors.white,
    this.shadow = TgsShadows.sh1,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final Color color;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: TgsColors.border1),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Icon tile in brand / navy / maroon tint.
class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.tint = TgsColors.brick500, this.size = 36});
  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, size: size * .5, color: tint),
  );
}

class Chevron extends StatelessWidget {
  const Chevron({super.key, this.color = TgsColors.fg3});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right_rounded, size: 20, color: color);
}
