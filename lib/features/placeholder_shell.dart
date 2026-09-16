import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_provider.dart';
import '../models/user.dart';
import '../theme/tokens.dart';
import '../widgets/brand.dart';

/// Temporary landing for the Staff and Admin shells while the Parent shell
/// is being built first. Lists the modules that will live here so the
/// data-flow into the parent dashboard is visible to reviewers.
class PlaceholderShell extends StatelessWidget {
  const PlaceholderShell({super.key, required this.shell});
  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.activeRole!;
    final isStaff = shell == AppShell.staff;

    final modules = isStaff
        ? const [
            ('Auto GPS check-in', 'Geofence 120 m · 15 min grace', Icons.location_on_outlined),
            ('Schedule', 'Timetable with NOW marker', Icons.calendar_today_outlined),
            ('Marks entry', 'Feeds parent report cards · locks after 7 days', Icons.edit_note_rounded),
            ('Roll call', 'Feeds parent attendance %', Icons.checklist_rounded),
            ('Timesheet', 'Weekly hours · payroll cut-off', Icons.timer_outlined),
            ('Alerts', 'Push via Firebase', Icons.notifications_outlined),
          ]
        : _adminModules(role);

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? 'Staff' : 'Admin console'),
        actions: [
          if ((auth.user?.roles.length ?? 0) > 1)
            IconButton(icon: const Icon(Icons.swap_horiz_rounded), tooltip: 'Switch role', onPressed: auth.switchRole),
          IconButton(icon: const Icon(Icons.logout_rounded), tooltip: 'Sign out', onPressed: auth.signOut),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              InitialsAvatar(auth.user!.initials, color: isStaff ? TgsColors.navy500 : TgsColors.maroon500),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auth.user!.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(role.label, style: const TextStyle(fontSize: 12, color: TgsColors.fg3)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TgsCard(
            color: TgsColors.warningBg,
            child: Row(
              children: const [
                Icon(Icons.construction_rounded, color: TgsColors.warningText),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This shell is scheduled for the next phase. The Parent app is being completed first; the modules below are what will write the data parents see.',
                    style: TextStyle(fontSize: 12, color: TgsColors.warningText),
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('Planned modules'),
          for (final m in modules) ...[
            TgsCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconBox(m.$3, tint: isStaff ? TgsColors.navy500 : TgsColors.maroon500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(m.$2, style: const TextStyle(fontSize: 11, color: TgsColors.fg3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  List<(String, String, IconData)> _adminModules(UserRole r) => switch (r) {
    UserRole.bursar => const [
      ('Finance', 'Invoices, payments, arrears → parent Fees', Icons.credit_card_outlined),
      ('Procurement', 'Requisition approvals', Icons.inventory_2_outlined),
      ('Stores', 'Inventory & issue vouchers', Icons.warehouse_outlined),
    ],
    UserRole.nurse => const [
      ('Clinic daybook', 'Record visit → parent Clinic', Icons.medical_services_outlined),
      ('Medicine stock', 'Batches & expiry', Icons.medication_outlined),
      ('Referrals', 'With parent consent', Icons.local_hospital_outlined),
    ],
    UserRole.cook => const [
      ('Weekly menu', 'Publish → parent Feeding menu', Icons.restaurant_menu_outlined),
      ('Kitchen inventory', 'Consumption vs roll', Icons.kitchen_outlined),
    ],
    UserRole.dos => const [
      ('Academics', 'Compile & publish report cards → parent Academics', Icons.menu_book_outlined),
      ('Attendance & GPS', 'Live staff geofence', Icons.location_on_outlined),
    ],
    UserRole.registrar => const [
      ('Students', 'Enrol, guardians → parent hero card', Icons.people_outline),
      ('Events', 'Calendar → parent Events', Icons.event_outlined),
      ('Documents', 'Handbook, calendar, consents', Icons.folder_outlined),
    ],
    _ => const [
      ('Dashboard', 'Live KPIs', Icons.dashboard_outlined),
      ('Finance', 'Fees collection', Icons.credit_card_outlined),
      ('Students', 'Directory', Icons.people_outline),
      ('Academics', 'Marks & report cards', Icons.menu_book_outlined),
      ('Attendance', 'Staff geofence', Icons.location_on_outlined),
      ('Clinic', 'Daybook', Icons.medical_services_outlined),
      ('Kitchen', 'Feeding plan', Icons.restaurant_outlined),
      ('Events', 'Calendar', Icons.event_outlined),
      ('Procurement', 'Requisitions & POs', Icons.inventory_2_outlined),
      ('Stores', 'Inventory', Icons.warehouse_outlined),
      ('Reports', 'UNEB / EMIS exports', Icons.bar_chart_rounded),
      ('Audit log', 'Immutable trail', Icons.history_rounded),
    ],
  };
}
