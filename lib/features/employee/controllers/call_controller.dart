import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_callers_mobile/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/call_session_model.dart';


class CallController extends GetxController {
  final numberController = TextEditingController();

  /// Reactive state
  Rx<CallSession?> callSession = Rx<CallSession?>(null);
  RxBool isSubmittingData = false.obs;
  RxBool isLoading = false.obs;
  Rx<int?> selectedSimSlot = Rx<int?>(null);

  static const MethodChannel _platform =
  MethodChannel('com.easy_callers/call');

  @override
  void onInit() {
    super.onInit();
    _loadSelectedSim();
  }

  Future<void> _loadSelectedSim() async {
    final storage = Get.find<StorageService>();
    final slot = storage.getInt('selected_sim_slot');
    if (slot != null) {
      selectedSimSlot.value = slot;
    }
  }

  Future<void> _saveSelectedSim(int slot) async {
    final storage = Get.find<StorageService>();
    await storage.setInt('selected_sim_slot', slot);
    selectedSimSlot.value = slot;
  }

  // ------------------------------------------------------------
  // SIM SELECTION PROMPT
  // ------------------------------------------------------------

  Future<void> checkAndPromptSimSelection({bool force = false}) async {
    if (Platform.isIOS) return;

    final sims = await getSimCards();
    if (sims.length > 1) {
      // If none selected, or user wants to change (force), show dialog
      if (selectedSimSlot.value == null || force) {
        await _showSimSelectionDialog(sims);
      }
    } else if (sims.length == 1) {
      // Auto-select the only SIM if not already selected
      if (selectedSimSlot.value == null) {
        _saveSelectedSim(sims.first['index'] as int);
      }
    }
  }

  Future<void> _showSimSelectionDialog(List<Map<String, dynamic>> sims) async {
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1A1F30),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sim_card_rounded, color: Colors.blue, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Select Primary SIM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select which SIM card to use for making calls.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ...sims.map((sim) {
                final index = sim['index'] as int;
                final name = sim['name'] ?? 'SIM ${index + 1}';
                final carrier = sim['carrierName'] ?? 'Unknown';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      _saveSelectedSim(index);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedSimSlot.value == index 
                            ? Colors.blue.withOpacity(0.2) 
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedSimSlot.value == index ? Colors.blue : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sim_card_outlined,
                            color: selectedSimSlot.value == index ? Colors.blue : Colors.white70,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  carrier,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedSimSlot.value == index)
                            const Icon(Icons.check_circle, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ------------------------------------------------------------
  // RESET SESSION
  // ------------------------------------------------------------

  void resetCallSession() {
    callSession.value = null;
  }

  // ------------------------------------------------------------
  // iOS CALL
  // ------------------------------------------------------------

  Future<CallSession?> makeCallForIos({
    required String phoneNumber,
  }) async {
    resetCallSession();
    try {
      await _platform.invokeMethod('startCall', {'number': phoneNumber});

      final completer = Completer<String?>();

      _platform.setMethodCallHandler((call) async {
        if (call.method == 'callEnded') {
          final String duration = call.arguments ?? '';
          completer.complete(duration);
        }
      });

      final duration = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => null,
      );


      if (duration != null) {
        callSession(
          CallSession.fromIos(
            number: phoneNumber,
            duration: duration,
            status: "completed",
          ),
        );

        return callSession.value;
      }
    } on PlatformException catch (e) {
      isLoading(false);
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Error', e.message ?? 'iOS call failed');
    }
    return null;
  }

  // ------------------------------------------------------------
  // ANDROID CALL
  // ------------------------------------------------------------

  Future<CallSession?> makeCall({
    required String phoneNumber,
    int? simSlot,
  }) async {
    resetCallSession();

    // Use selected SIM slot if not explicitly provided
    final slotToUse = simSlot ?? selectedSimSlot.value;

    try {
      final result = await _platform.invokeMethod(
        'startCall',
        {
          'number': phoneNumber,
          'simSlot': slotToUse,
        },
      );

      if (result != null) {
        // 🔥 Native already returns Map
        final Map<String, dynamic> data =
        Map<String, dynamic>.from(result);

        callSession.value = CallSession.fromJson(data);

        return callSession.value;
      }
    } on PlatformException catch (e) {
      isLoading(false);
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar('Error', e.message ?? 'Android call failed');
    }

    return null;
  }

  // ------------------------------------------------------------
  // SIM INFO
  // ------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getSimCards() async {
    try {
      final List<dynamic>? result = await _platform.invokeMethod('getSimCards');
      if (result != null) {
        return result.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get SIM info: ${e.message}");
    }
    return [];
  }

  // ------------------------------------------------------------
  // WHATSAPP
  // ------------------------------------------------------------

  Future<void> sendWhatsAppMessage(
      List<String> numbers,
      String defaultMessage,
      ) async {
    try {
      await _platform.invokeMethod('sendBulkWhatsAppMessages', {
        'numbers': numbers,
        'message': defaultMessage,
      });
    } catch (e) {
      debugPrint("WhatsApp error: $e");
    }
  }

  // ------------------------------------------------------------
  // SMS
  // ------------------------------------------------------------

  Future<void> sendSMS(String number, String message) async {
    try {
      await _platform.invokeMethod('sendSMS', {
        'number': number,
        'message': message,
      });
    } on PlatformException catch (e) {
      debugPrint("SMS failed: ${e.message}");
    }
  }

  // ------------------------------------------------------------
  // IOS WHATSAPP
  // ------------------------------------------------------------
  launchWhatsAppChatForIos(String number,
      {String message = "Hello"}) async {
    try {
      await _platform.invokeMethod('whatsappChat', {
        'number': number,
        'message': message,
      });
    } catch (e) {
      print("Failed to open WhatsApp: $e");
    }
  }



  @override
  void onClose() {
    numberController.dispose();
    super.onClose();
  }
}
