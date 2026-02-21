import 'dart:io';

import 'package:easy_callers_mobile/features/employee/controllers/call_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

import 'package:easy_callers_mobile/features/employee/models/lead_status_model.dart';
import 'package:easy_callers_mobile/features/employee/dashboard/controllers/employee_dashboard_controller.dart';
import '../models/call_session_model.dart';

class LeadDetailController extends GetxController {
  // static const platform = MethodChannel('com.easy_callers/call');
  final LeadModel lead;
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();
  final Rx<CallSession?> lastCallSession = Rx<CallSession?>(null);
  LeadDetailController({required this.lead});

  final RxString selectedStatus = ''.obs;
  final RxList<LeadStatusModel> availableLeadStatuses = <LeadStatusModel>[].obs;
  final RxBool followUpEnabled = false.obs;
  final Rx<DateTime?> followUpDate = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;
  final RxInt callDurationSeconds = 0.obs;
  final TextEditingController notesController = TextEditingController();

  // Visiting date & time
  final Rx<DateTime?> visitingDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> visitingTime = Rx<TimeOfDay?>(null);

  // Last call log for this lead (fetched from DB)
  final Rx<CallLogModel?> lastCallLog = Rx<CallLogModel?>(null);
  final RxBool isLoadingLastCall = false.obs;
  var callController = Get.find<CallController>();
  @override
  void onInit() {
    super.onInit();
    // Reset all state — don't carry over previous lead's data
    selectedStatus.value = '';
    callController.callSession.value = null; // Clear previous call session
    lastCallSession.value = null;
    fetchLeadStatuses();
    fetchLastCallLog();
  }

  Future<void> fetchLeadStatuses() async {
    try {
      final managerId = _authService.currentEmployee.value?.managerId;
      final statuses = await _leadService.getLeadStatuses(managerId);
      availableLeadStatuses.assignAll(statuses);
    } catch (e) {
      print('Error loading statuses: $e');
    }
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  /// Fetch the last call log for this lead from the database
  Future<void> fetchLastCallLog() async {
    try {
      isLoadingLastCall.value = true;
      final logs = await _leadService.getCallLogsByLead(lead.id);
      if (logs.isNotEmpty) {
        lastCallLog.value = logs.first; // newest first (ordered DESC)
        print('LeadDetail: Last call for lead ${lead.id}: status=${logs.first.callStatus}, leadStatus=${logs.first.leadStatus}');
      } else {
        lastCallLog.value = null;
        print('LeadDetail: No previous calls for lead ${lead.id}');
      }
    } catch (e) {
      print('LeadDetail: Error fetching last call log: $e');
    } finally {
      isLoadingLastCall.value = false;
    }
  }


  Future<void> makeCall() async {
    try {
      CallSession? session;

      if (Platform.isIOS) {
        session = await callController.makeCallForIos(
          phoneNumber: lead.phone,
        );
      } else {
        session = await callController.makeCall(
          phoneNumber: lead.phone,
        );
      }

      if (session == null) {
        selectedStatus.value = 'no_answer';
        callDurationSeconds.value = 0;
        lastCallSession.value = null;
        return;
      }

      lastCallSession.value = session;
      callDurationSeconds.value = session.durationInSeconds;
      // Save duration
      callDurationSeconds.value = session.durationInSeconds;

      // Business decision
      if (!session.isConnected) {
        selectedStatus.value = 'callback';
      } else if (session.durationInSeconds > 30) {
        selectedStatus.value = 'interested';
      } else {
        selectedStatus.value = 'callback';
      }

    } catch (e) {
      print("object $e");
      Get.snackbar("Error", "Call failed: $e");
    }
  }



  whatsappMsg() {
    if (Platform.isIOS) {
      callController.launchWhatsAppChatForIos(lead.phone);
    } else {
      callController.sendWhatsAppMessage([lead.phone], "Hello");
    }
  }

  sendMobileSMS(){
    if (Platform.isIOS) {
      callController.sendSMS(lead.phone,"Hello");
    } else {
      callController.sendSMS(lead.phone, "Hello");
    }
  }

  Future<void> saveUpdate() async {
    try {
      isLoading.value = true;

      // Validate status is selected
      if (selectedStatus.value.isEmpty) {
        Get.snackbar(
          'Select Status',
          'Please select a lead status before saving',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        isLoading.value = false;
        return;
      }

      final employeeId = _authService.currentEmployee.value?.id;
      if (employeeId == null) {
        Get.snackbar('Error', 'Employee not found');
        isLoading.value = false;
        return;
      }

      final session = callController.callSession.value;

      // Build visiting DateTime if status is visiting
      DateTime? resolvedFollowUpDate;
      String? resolvedFollowUpNotes;

      if (selectedStatus.value == 'visiting' && visitingDate.value != null) {
        final date = visitingDate.value!;
        final time = visitingTime.value ?? const TimeOfDay(hour: 10, minute: 0);
        resolvedFollowUpDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        resolvedFollowUpNotes = 'Visiting';
      } else if (followUpEnabled.value && followUpDate.value != null) {
        resolvedFollowUpDate = followUpDate.value;
      }

      final callLog = CallLogModel(
        id: '', // Will be generated by database
        leadId: lead.id,
        employeeId: employeeId,
        callStatus: session?.status ?? (lastCallSession.value?.status ?? 'Completed'),
        leadStatus: selectedStatus.value,
        callDurationSeconds: callDurationSeconds.value,
        feedback: notesController.text.trim().isNotEmpty 
            ? notesController.text.trim() 
            : null,
        followUpDate: resolvedFollowUpDate,
        followUpNotes: resolvedFollowUpNotes,
        createdAt: DateTime.now(),
      );

      print('SaveUpdate: Saving call log for lead ${lead.id}, status: ${selectedStatus.value}');

      // Save call log
      final savedLog = await _leadService.addCallLog(callLog);

      if (savedLog != null) {
        print('SaveUpdate: Call log saved successfully');
        isLoading.value = false;

        // Remove this lead from dashboard's list so user doesn't see it again
        try {
          final dashboardController = Get.find<EmployeeDashboardController>();
          dashboardController.assignedLeads.removeWhere((l) => l.id == lead.id);
          // Update contacted count (+1 unique lead)
          dashboardController.contactedLeadsCount.value += 1;
          final goal = dashboardController.todayStats['goal'] ?? 24;
          if (goal > 0) {
            dashboardController.dailyProgress.value = 
                (dashboardController.contactedLeadsCount.value / goal).clamp(0.0, 1.0);
          }
        } catch (_) {
          // Dashboard controller might not exist, that's OK
        }

        // Navigate back
        if (Get.context != null) {
          Navigator.of(Get.context!).pop();
        }

        // Show success snackbar after navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success',
            'Call log saved successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        });
      } else {
        print('SaveUpdate: addCallLog returned null');
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Failed to save call log. Check your connection.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('SaveUpdate: Error - $e');
      try { isLoading.value = false; } catch (_) {}
      Get.snackbar(
        'Error',
        'Failed to save update: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
