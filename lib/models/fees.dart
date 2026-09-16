/// Term identifier. Terms are created by the Director/Registrar.
class Term {
  final String id;
  final int year;
  final int number; // 1..3
  final DateTime startsOn;
  final DateTime endsOn;
  final DateTime? feesDueOn;
  final bool isCurrent;

  const Term({
    required this.id,
    required this.year,
    required this.number,
    required this.startsOn,
    required this.endsOn,
    this.feesDueOn,
    this.isCurrent = false,
  });

  String get label => 'Term $number, $year';
  String get shortLabel => 'Term $number';

  factory Term.fromMap(Map<String, dynamic> m) => Term(
    id: m['id'] as String,
    year: (m['year'] as num).toInt(),
    number: (m['number'] as num).toInt(),
    startsOn: DateTime.parse(m['starts_on'].toString()),
    endsOn: DateTime.parse(m['ends_on'].toString()),
    feesDueOn: m['fees_due_on'] == null
        ? null
        : DateTime.tryParse(m['fees_due_on'].toString()),
    isCurrent: (m['is_current'] as bool?) ?? false,
  );
}

/// One line on a student's fee invoice (tuition, boarding, lunch...).
/// Written by the Bursar.
class FeeLine {
  final String id;
  final String label;
  final int amount; // UGX, whole shillings

  const FeeLine({required this.id, required this.label, required this.amount});

  factory FeeLine.fromMap(Map<String, dynamic> m) => FeeLine(
    id: m['id'] as String,
    label: (m['label'] as String?) ?? '',
    amount: ((m['amount'] as num?) ?? 0).toInt(),
  );
}

enum PaymentMethod {
  mtn,
  airtel,
  bank,
  cash,
  other;

  static PaymentMethod fromKey(String? k) => PaymentMethod.values.firstWhere(
    (e) => e.name == k,
    orElse: () => PaymentMethod.other,
  );

  String get label => switch (this) {
    PaymentMethod.mtn => 'MTN Mobile Money',
    PaymentMethod.airtel => 'Airtel Money',
    PaymentMethod.bank => 'Bank deposit',
    PaymentMethod.cash => 'Cash · Bursar',
    PaymentMethod.other => 'Other',
  };
}

/// A receipt. Written by the Bursar (manual) or the payment gateway (auto).
class Payment {
  final String id;
  final String receiptNo; // R-2026-0891
  final int amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final String? reference;

  const Payment({
    required this.id,
    required this.receiptNo,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.reference,
  });

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'] as String,
    receiptNo: (m['receipt_no'] as String?) ?? '',
    amount: ((m['amount'] as num?) ?? 0).toInt(),
    method: PaymentMethod.fromKey(m['method'] as String?),
    paidAt: DateTime.parse(m['paid_at'].toString()),
    reference: m['reference'] as String?,
  );
}

enum FeeStatus { cleared, partial, arrears }

/// Everything the parent Fees screen needs for one student in one term.
class FeeStatement {
  final String studentId;
  final Term term;
  final List<FeeLine> lines;
  final List<Payment> payments;

  const FeeStatement({
    required this.studentId,
    required this.term,
    required this.lines,
    required this.payments,
  });

  int get invoiced => lines.fold(0, (a, l) => a + l.amount);
  int get paid => payments.fold(0, (a, p) => a + p.amount);
  int get balance => invoiced - paid;

  FeeStatus get status {
    if (balance <= 0) return FeeStatus.cleared;
    final due = term.feesDueOn;
    if (due != null && DateTime.now().isAfter(due)) return FeeStatus.arrears;
    return FeeStatus.partial;
  }

  int? get daysToDue {
    final due = term.feesDueOn;
    if (due == null) return null;
    return due.difference(DateTime.now()).inDays;
  }
}

/// School payment channels published by the Bursar (school code, bank a/c).
class PaymentChannel {
  final PaymentMethod method;
  final String title;
  final String instruction;

  const PaymentChannel({
    required this.method,
    required this.title,
    required this.instruction,
  });
}
