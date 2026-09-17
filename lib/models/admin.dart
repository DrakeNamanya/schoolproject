// Admin-console models: procurement, stores, clinic stock, staff presence,
// audit. Table mapping in docs/DATA_MODEL.md §9–§13.

enum RequisitionStatus {
  bursar, // awaiting bursar
  director, // awaiting director
  approved,
  poRaised,
  delivered,
  rejected;

  String get label => switch (this) {
    RequisitionStatus.bursar => 'Bursar',
    RequisitionStatus.director => 'Director',
    RequisitionStatus.approved => 'Approved',
    RequisitionStatus.poRaised => 'PO raised',
    RequisitionStatus.delivered => 'Delivered',
    RequisitionStatus.rejected => 'Over budget',
  };

  bool get pending => this == bursar || this == director;
}

class Requisition {
  final String id;
  final String ref; // REQ-0347
  final String title;
  final String dept;
  final String requester;
  final DateTime date;
  final int amount;
  final int lines;
  final RequisitionStatus status;

  const Requisition({
    required this.id,
    required this.ref,
    required this.title,
    required this.dept,
    required this.requester,
    required this.date,
    required this.amount,
    required this.lines,
    required this.status,
  });

  Requisition withStatus(RequisitionStatus s) => Requisition(
    id: id, ref: ref, title: title, dept: dept, requester: requester,
    date: date, amount: amount, lines: lines, status: s,
  );
}

class StockItem {
  final String id;
  final String sku;
  final String name;
  final String category;
  final int onHand;
  final int reorderAt;
  final String unit;
  final String lastIssued;

  const StockItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.onHand,
    required this.reorderAt,
    required this.unit,
    required this.lastIssued,
  });

  bool get needsReorder => onHand < reorderAt;
  bool get watch => !needsReorder && onHand < reorderAt * 1.2;
}

class MedicineStock {
  final String id;
  final String name;
  final String batch;
  final String expiry;
  final int qty;
  final String unit;
  final int reorderAt;

  const MedicineStock({
    required this.id,
    required this.name,
    required this.batch,
    required this.expiry,
    required this.qty,
    required this.unit,
    required this.reorderAt,
  });

  double get level => (qty / (reorderAt * 2)).clamp(0, 1);
  bool get low => qty < reorderAt;
}

enum PresenceStatus { inside, outside, offDuty }

class StaffPresence {
  final String name;
  final String role;
  final PresenceStatus status;
  final String time;
  final String detail;
  final double x, y; // 0..1 map position

  const StaffPresence({
    required this.name,
    required this.role,
    required this.status,
    required this.time,
    required this.detail,
    required this.x,
    required this.y,
  });
}

class AuditEntry {
  final DateTime at;
  final String who;
  final String role;
  final String action;
  final String detail;
  final String object;
  final String level; // i | w | d

  const AuditEntry({
    required this.at,
    required this.who,
    required this.role,
    required this.action,
    required this.detail,
    required this.object,
    this.level = 'i',
  });
}

/// Aggregates for the dashboard / finance KPIs — computed client-side from
/// the store in demo mode, from SQL views (`v_finance_kpis` etc.) later.
class FinanceKpis {
  final int invoiced;
  final int collected;
  final int today;
  final int arrearsCount;
  final int partialCount;
  final int clearedCount;
  final int mtnShare, airtelShare, bankShare; // percent

  const FinanceKpis({
    required this.invoiced,
    required this.collected,
    required this.today,
    required this.arrearsCount,
    required this.partialCount,
    required this.clearedCount,
    required this.mtnShare,
    required this.airtelShare,
    required this.bankShare,
  });

  int get outstanding => invoiced - collected;
  double get pct => invoiced == 0 ? 0 : collected / invoiced;
}
