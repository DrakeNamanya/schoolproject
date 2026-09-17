import 'package:flutter/material.dart';

import '../../models/user.dart';

enum AdminModule {
  dashboard, finance, students, academics, attendance,
  clinic, kitchen, events, procurement, stores,
  reports, audit;

  String get label => switch (this) {
    dashboard => 'Dashboard',
    finance => 'Finance',
    students => 'Students',
    academics => 'Academics',
    attendance => 'Attendance',
    clinic => 'Clinic',
    kitchen => 'Kitchen',
    events => 'Events',
    procurement => 'Procurement',
    stores => 'Stores',
    reports => 'Reports',
    audit => 'Audit log',
  };

  IconData get icon => switch (this) {
    dashboard => Icons.dashboard_outlined,
    finance => Icons.credit_card_outlined,
    students => Icons.people_outline,
    academics => Icons.menu_book_outlined,
    attendance => Icons.location_on_outlined,
    clinic => Icons.medical_services_outlined,
    kitchen => Icons.restaurant_outlined,
    events => Icons.event_outlined,
    procurement => Icons.inventory_2_outlined,
    stores => Icons.warehouse_outlined,
    reports => Icons.bar_chart_rounded,
    audit => Icons.history_rounded,
  };

  String get group => switch (this) {
    dashboard || finance || students || academics || attendance => 'Operations',
    clinic || kitchen || events || procurement || stores => 'Services',
    _ => 'Insight',
  };

  /// Which sub-roles can open this module. Mirrors RLS in the migrations.
  Set<UserRole> get roles => switch (this) {
    dashboard => {UserRole.director, UserRole.admin, UserRole.bursar, UserRole.dos},
    finance => {UserRole.bursar, UserRole.director, UserRole.admin},
    students => {UserRole.registrar, UserRole.director, UserRole.dos, UserRole.bursar, UserRole.admin},
    academics => {UserRole.dos, UserRole.director, UserRole.admin},
    attendance => {UserRole.dos, UserRole.director, UserRole.bursar, UserRole.admin},
    clinic => {UserRole.nurse, UserRole.director, UserRole.admin},
    kitchen => {UserRole.cook, UserRole.director, UserRole.bursar, UserRole.admin},
    events => {UserRole.registrar, UserRole.director, UserRole.admin},
    procurement => {UserRole.bursar, UserRole.director, UserRole.dos, UserRole.admin},
    stores => {UserRole.bursar, UserRole.director, UserRole.admin},
    reports => {UserRole.director, UserRole.dos, UserRole.bursar, UserRole.admin},
    audit => {UserRole.director, UserRole.admin},
  };

  static List<AdminModule> forRole(UserRole r) =>
      AdminModule.values.where((m) => m.roles.contains(r)).toList();

  /// Landing module per sub-role.
  static AdminModule homeFor(UserRole r) => switch (r) {
    UserRole.bursar => finance,
    UserRole.registrar => students,
    UserRole.dos => academics,
    UserRole.nurse => clinic,
    UserRole.cook => kitchen,
    _ => dashboard,
  };
}
