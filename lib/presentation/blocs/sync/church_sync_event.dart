import 'package:equatable/equatable.dart';

abstract class ChurchSyncEvent extends Equatable {
  const ChurchSyncEvent();

  @override
  List<Object?> get props => [];
}

class SubmitTitheEvent extends ChurchSyncEvent {
  final String memberId;
  final String memberName;
  final String? memberEmail;
  final double amount;
  final String category;
  final String mpesaReceipt;

  const SubmitTitheEvent({
    required this.memberId,
    required this.memberName,
    this.memberEmail,
    required this.amount,
    required this.category,
    required this.mpesaReceipt,
  });

  @override
  List<Object?> get props => [memberId, memberName, amount, category, mpesaReceipt];
}

class SubmitLoanApplicationEvent extends ChurchSyncEvent {
  final String memberId;
  final String memberName;
  final String? memberEmail;
  final double amountRequested;
  final int repaymentPeriodMonths;
  final String guarantorPhone;
  final String purpose;

  const SubmitLoanApplicationEvent({
    required this.memberId,
    required this.memberName,
    this.memberEmail,
    required this.amountRequested,
    required this.repaymentPeriodMonths,
    required this.guarantorPhone,
    required this.purpose,
  });

  @override
  List<Object?> get props => [memberId, memberName, amountRequested, guarantorPhone, purpose];
}

class TriggerBackgroundSyncEvent extends ChurchSyncEvent {
  const TriggerBackgroundSyncEvent();
}

class RefreshQueueCountEvent extends ChurchSyncEvent {
  const RefreshQueueCountEvent();
}
