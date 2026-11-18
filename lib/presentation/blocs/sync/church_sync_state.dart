import 'package:equatable/equatable.dart';

abstract class ChurchSyncState extends Equatable {
  final int queueCount;
  const ChurchSyncState({this.queueCount = 0});

  @override
  List<Object?> get props => [queueCount];
}

class ChurchSyncInitial extends ChurchSyncState {
  const ChurchSyncInitial({super.queueCount = 0});
}

class ChurchSyncLoading extends ChurchSyncState {
  const ChurchSyncLoading({super.queueCount});
}

class ChurchSyncSuccess extends ChurchSyncState {
  final String message;
  final bool isOfflineQueued;

  const ChurchSyncSuccess({
    required this.message,
    this.isOfflineQueued = false,
    super.queueCount,
  });

  @override
  List<Object?> get props => [message, isOfflineQueued, queueCount];
}

class ChurchSyncError extends ChurchSyncState {
  final String error;

  const ChurchSyncError({
    required this.error,
    super.queueCount,
  });

  @override
  List<Object?> get props => [error, queueCount];
}
