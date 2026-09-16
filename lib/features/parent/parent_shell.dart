import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/tokens.dart';
import 'parent_provider.dart';
import 'screens/academics_screen.dart';
import 'screens/clinic_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/home_screen.dart';
import 'screens/more_screen.dart';

/// Bottom-tab shell for guardians: Home · Fees · Academics · Clinic · More
class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _tab = 0;

  void _goTo(int i) => setState(() => _tab = i);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParentProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParentProvider>();

    final pages = [
      HomeScreen(onNavigate: _goTo),
      const FeesScreen(),
      const AcademicsScreen(),
      const ClinicScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: p.loading && p.children.isEmpty
            ? const _Loading()
            : p.error != null && p.children.isEmpty
            ? _ErrorView(message: p.error!, onRetry: p.load)
            : IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: TgsColors.border1)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _goTo,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.credit_card_outlined),
              selectedIcon: Icon(Icons.credit_card_rounded),
              label: 'Fees',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Academics',
            ),
            NavigationDestination(
              icon: Icon(Icons.medical_services_outlined),
              selectedIcon: Icon(Icons.medical_services_rounded),
              label: 'Clinic',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: TgsColors.brick500),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: TgsColors.fg3),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

/// Shared page header for sub-tabs: title + term badge.
class ParentPageHeader extends StatelessWidget {
  const ParentPageHeader({super.key, required this.title, this.badge});
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: TgsColors.maroon50,
                borderRadius: BorderRadius.circular(TgsRadius.pill),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontFamily: TgsFonts.mono,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TgsColors.maroon600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
