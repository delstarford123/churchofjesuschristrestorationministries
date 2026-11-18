import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:rlds_church_app/core/constants/api_constants.dart';

class ChurchSyncRepository {
  final Dio _dio;
  late final Box _offlineQueueBox;

  ChurchSyncRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _offlineQueueBox = Hive.box('offline_queue');
  }

  /// Check whether device has an active network connection.
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // In connectivity_plus v6.0+, checkConnectivity returns List<ConnectivityResult>
      if (connectivityResult.isEmpty) return false;
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// Returns count of pending offline transactions in Hive
  int getPendingQueueCount() {
    return _offlineQueueBox.length;
  }

  /// Returns list of all pending queued items
  List<Map<dynamic, dynamic>> getQueueItems() {
    return _offlineQueueBox.values.map((e) => Map<dynamic, dynamic>.from(e as Map)).toList();
  }

  // --- 1. TITHE & OFFERING SUBMISSION (Offline-First) ---
  Future<Map<String, dynamic>> submitTithe({
    required String memberId,
    required String memberName,
    String? memberEmail,
    required double amount,
    required String category,
    required String mpesaReceipt,
  }) async {
    final clientTxId = 'TX-${DateTime.now().millisecondsSinceEpoch}';
    final transactionData = {
      'client_transaction_id': clientTxId,
      'member_id': memberId,
      'member_name': memberName,
      'member_email': memberEmail,
      'amount': amount,
      'currency': 'KES',
      'category': category,
      'mpesa_receipt': mpesaReceipt,
      'payment_method': 'M-Pesa',
      'transaction_date': DateTime.now().toIso8601String(),
    };

    final isOnline = await hasInternetConnection();

    if (isOnline) {
      try {
        final response = await _dio.post(
          ApiConstants.syncTithes,
          data: {
            'transactions': [transactionData]
          },
        );
        return {
          'status': 'success',
          'message': 'Tithe submitted successfully online.',
          'data': response.data,
        };
      } catch (e) {
        // Fallback to offline queue on network hiccup
        await _saveToOfflineQueue('tithe', transactionData);
        return {
          'status': 'offline_queued',
          'message': 'Network error. Saved offline and will sync automatically once connected.',
        };
      }
    } else {
      // Offline mode: Save to Hive queue
      await _saveToOfflineQueue('tithe', transactionData);
      return {
        'status': 'offline_queued',
        'message': 'Offline mode. Transaction saved locally on your device.',
      };
    }
  }

  // --- 2. STEWARDSHIP KITTY LOAN APPLICATION (Offline-First) ---
  Future<Map<String, dynamic>> applyForLoan({
    required String memberId,
    required String memberName,
    String? memberEmail,
    required double amountRequested,
    required int repaymentPeriodMonths,
    required String guarantorPhone,
    required String purpose,
  }) async {
    final clientLoanId = 'LOAN-${DateTime.now().millisecondsSinceEpoch}';
    final loanData = {
      'client_loan_id': clientLoanId,
      'member_id': memberId,
      'member_name': memberName,
      'member_email': memberEmail,
      'amount_requested': amountRequested,
      'repayment_period_months': repaymentPeriodMonths,
      'guarantor_phone': guarantorPhone,
      'purpose': purpose,
      'applied_at': DateTime.now().toIso8601String(),
    };

    final isOnline = await hasInternetConnection();

    if (isOnline) {
      try {
        final response = await _dio.post(ApiConstants.applyLoan, data: loanData);
        return {
          'status': 'success',
          'message': 'Loan application submitted successfully online.',
          'data': response.data,
        };
      } catch (e) {
        await _saveToOfflineQueue('loan', loanData);
        return {
          'status': 'offline_queued',
          'message': 'Network error. Loan application queued locally.',
        };
      }
    } else {
      await _saveToOfflineQueue('loan', loanData);
      return {
        'status': 'offline_queued',
        'message': 'Offline mode. Loan application saved to local device queue.',
      };
    }
  }

  // Helper to save requests into Hive offline queue box
  Future<void> _saveToOfflineQueue(String type, Map<String, dynamic> data) async {
    final queueItem = {
      'type': type, // 'tithe' or 'loan'
      'payload': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _offlineQueueBox.add(queueItem);
  }

  // --- 3. BACKGROUND SYNC WORKER (Flushes Hive Queue to Flask API) ---
  Future<Map<String, dynamic>> syncOfflineQueue() async {
    if (_offlineQueueBox.isEmpty) {
      return {'status': 'empty', 'message': 'Offline queue is already empty.'};
    }

    if (!await hasInternetConnection()) {
      return {'status': 'offline', 'message': 'Device is still offline. Sync skipped.'};
    }

    final keys = _offlineQueueBox.keys.toList();
    final List<Map<String, dynamic>> pendingTithes = [];
    final Map<dynamic, dynamic> keyMap = {};
    int syncedLoans = 0;

    for (var key in keys) {
      final item = _offlineQueueBox.get(key);
      if (item is Map) {
        final type = item['type'];
        final payload = Map<String, dynamic>.from(item['payload'] as Map);

        if (type == 'tithe') {
          pendingTithes.add(payload);
          keyMap[payload['client_transaction_id']] = key;
        } else if (type == 'loan') {
          try {
            await _dio.post(ApiConstants.applyLoan, data: payload);
            await _offlineQueueBox.delete(key);
            syncedLoans++;
          } catch (_) {
            // Keep in queue to retry later
          }
        }
      }
    }

    // Batch sync tithes
    int syncedTithes = 0;
    if (pendingTithes.isNotEmpty) {
      try {
        final response = await _dio.post(
          ApiConstants.syncTithes,
          data: {'transactions': pendingTithes},
        );
        if (response.statusCode == 200) {
          for (var tx in pendingTithes) {
            final hiveKey = keyMap[tx['client_transaction_id']];
            if (hiveKey != null) {
              await _offlineQueueBox.delete(hiveKey);
              syncedTithes++;
            }
          }
        }
      } catch (_) {
        // Will retry on next connectivity trigger
      }
    }

    return {
      'status': 'success',
      'message': 'Sync complete: $syncedTithes tithe(s) and $syncedLoans loan(s) synchronized.',
      'synced_tithes': syncedTithes,
      'synced_loans': syncedLoans,
    };
  }
}
