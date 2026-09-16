import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/tokens.dart';
import 'screens/alerts_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/timesheet_screen.dart';
import 'staff_provider.dart';

/// Staff shell: Check-in · Schedule · Classes · Timesheet · Alerts
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StaffProvider>();
    final hasClasses = p.assignments.isNotEmpty;

    final pages = <Widget>[
      const CheckInScreen(),
      const ScheduleScreen(),
      if (hasClasses) const ClassesScreen(),
      const TimesheetScreen(),
      const AlertsScreen(),
    ];
    final dests = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.location_on_outlined), selectedIcon: Icon(Icons.location_on_rounded), label: 'Check-in'),
      const NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today_rounded), label: 'Schedule'),
      if (hasClasses) const NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school_rounded), label: 'Classes'),
      const NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer_rounded), label: 'Timesheet'),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: p.unreadAlerts > 0,
          label: Text('${p.unreadAlerts}'),
          backgroundColor: TgsColors.brick500,
          child: const Icon(Icons.notifications_outlined),
        ),
        selectedIcon: const Icon(Icons.notifications_rounded),
        label: 'Alerts',
      ),
    ];
    if (_tab >= pages.length) _tab = 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: p.loading && p.profile == null
            ? const Center(child: CircularProgressIndicator(color: TgsColors.navy500))
            : p.error != null && p.profile == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.error!),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: p.load, child: const Text('Retry')),
                  ],
                ),
              )
            : IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: TgsColors.border1)),
        ),
        child: NavigationBarTheme(
          data: Theme.of(context).navigationBarTheme.copyWith(
            indicatorColor: TgsColors.navy50,
            labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: TgsFonts.sans,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: s.contains(WidgetState.selected) ? TgsColors.navy600 : TgsColors.fg3,
            )),
            iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 22,
              color: s.contains(WidgetState.selected) ? TgsColors.navy600 : TgsColors.fg3,
            )),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: dests,
          ),
        ),
      ),
    );
  }
}

/// Header used on staff sub-tabs.
class StaffPageHeader extends StatelessWidget {
  const StaffPageHeader({super.key, required this.title, this.badge, this.trailing});
  final String title;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
    child: Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: TgsColors.navy50, borderRadius: BorderRadius.circular(TgsRadius.pill)),
            child: Text(badge!, style: const TextStyle(fontFamily: TgsFonts.mono, fontSize: 11, fontWeight: FontWeight.w600, color: TgsColors.navy600)),
          ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}
