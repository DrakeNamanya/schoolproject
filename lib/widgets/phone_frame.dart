import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// On wide (web/desktop) viewports, renders the mobile shells inside a phone
/// bezel so it is obvious that Parent and Staff are phone apps. On actual
/// phones (< 600 px wide) the child fills the screen.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.label});
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width < 600) return child;

    const w = 390.0, h = 820.0;
    final scale = ((size.height - 60) / h).clamp(.6, 1.0);

    return Scaffold(
      backgroundColor: TgsColors.paper3,
      body: Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: Alignment(-.6, -.8), radius: 1.2, colors: [Color(0x0F690427), Colors.transparent]),
            ),
          ),
        ),
        Center(
          child: Transform.scale(
            scale: scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(label!.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: TgsColors.fg3)),
                ),
              Container(
                width: w,
                height: h,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TgsColors.ink800,
                  borderRadius: BorderRadius.circular(46),
                  boxShadow: const [BoxShadow(color: Color(0x47000000), blurRadius: 60, offset: Offset(0, 30)), BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: const Size(w - 24, h - 24),
                      padding: const EdgeInsets.only(top: 30, bottom: 12),
                      viewPadding: const EdgeInsets.only(top: 30, bottom: 12),
                    ),
                    child: Stack(children: [
                      Positioned.fill(child: child),
                      Positioned(
                        top: 10, left: 0, right: 0,
                        child: Center(child: Container(width: 110, height: 26, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)))),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
