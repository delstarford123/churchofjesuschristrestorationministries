import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rlds_church_app/data/repositories/church_sync_repository.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_event.dart';
import 'package:rlds_church_app/presentation/blocs/sync/church_sync_state.dart';

class ChurchSyncBloc extends Bloc<ChurchSyncEvent, ChurchSyncState> {
  final ChurchSyncRepository _repository;

  ChurchSyncBloc(this._repository)
      : super(ChurchSyncInitial(queueCount: _repository.getPendingQueueCount())) {
    on<SubmitTitheEvent>(_onSubmitTithe);
    on<SubmitLoanApplicationEvent>(_onSubmitLoan);
    on<TriggerBackgroundSyncEvent>(_onTriggerSync);
    on<RefreshQueueCountEvent>(_onRefreshQueueCount);
  }

  Future<void> _onSubmitTithe(
    SubmitTitheEvent event,
    Emitter<ChurchSyncState> emit,
  ) async {
    emit(ChurchSyncLoading(queueCount: _repository.getPendingQueueCount()));
    try {
      final result = await _repository.submitTithe(
        memberId: event.memberId,
        memberName: event.memberName,
        memberEmail: event.memberEmail,
        amount: event.amount,
        category: event.category,
        mpesaReceipt: event.mpesaReceipt,
      );

      final isQueued = result['status'] == 'offline_queued';
      emit(
        ChurchSyncSuccess(
          message: result['message'] as String,
          isOfflineQueued: isQueued,
          queueCount: _repository.getPendingQueueCount(),
        ),
      );
    } catch (e) {
      emit(
        ChurchSyncError(
          error: e.toString(),
          queueCount: _repository.getPendingQueueCount(),
        ),
      );
    }
  }

  Future<void> _onSubmitLoan(
    SubmitLoanApplicationEvent event,
    Emitter<ChurchSyncState> emit,
  ) async {
    emit(ChurchSyncLoading(queueCount: _repository.getPendingQueueCount()));
    try {
      final result = await _repository.applyForLoan(
        memberId: event.memberId,
        memberName: event.memberName,
        memberEmail: event.memberEmail,
        amountRequested: event.amountRequested,
        repaymentPeriodMonths: event.repaymentPeriodMonths,
        guarantorPhone: event.guarantorPhone,
        purpose: event.purpose,
      );

      final isQueued = result['status'] == 'offline_queued';
      emit(
        ChurchSyncSuccess(
          message: result['message'] as String,
          isOfflineQueued: isQueued,
          queueCount: _repository.getPendingQueueCount(),
        ),
      );
    } catch (e) {
      emit(
        ChurchSyncError(
          error: e.toString(),
          queueCount: _repository.getPendingQueueCount(),
        ),
      );
    }
  }

  Future<void> _onTriggerSync(
    TriggerBackgroundSyncEvent event,
    Emitter<ChurchSyncState> emit,
  ) async {
    emit(ChurchSyncLoading(queueCount: _repository.getPendingQueueCount()));
    try {
      final result = await _repository.syncOfflineQueue();
      emit(
        ChurchSyncSuccess(
          message: result['message'] as String,
          queueCount: _repository.getPendingQueueCount(),
        ),
      );
    } catch (e) {
      emit(
        ChurchSyncError(
          error: 'Background sync error: ${e.toString()}',
          queueCount: _repository.getPendingQueueCount(),
        ),
      );
    }
  }

  void _onRefreshQueueCount(
    RefreshQueueCountEvent event,
    Emitter<ChurchSyncState> emit,
  ) {
    emit(ChurchSyncInitial(queueCount: _repository.getPendingQueueCount()));
  }
}
