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
  final WebService _webService = Get.find<WebService>();
  final AuthService _authService = Get.find<AuthService>();
  final Rx<CallSession?> lastCallSession = Rx<CallSession?>(null);
  LeadDetailController({required this.lead});

  final RxString selectedStatus = ''.obs;
  final RxList<LeadStatusModel> availableLeadStatuses = <LeadStatusModel>[].obs;
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
      final statusesStr = (await _webService.getLeadStatuses(managerId)).payload ?? [];
      
      // Employee visible statuses: Follow-up, Not Interested, Visiting, Visit Completed
      final visibleMappings = ['follow_up', 'not_interested', 'visiting', 'visit_completed'];
      
      final filteredStatuses = statusesStr.where((s) {
        final mapping = s.leadStatusMapping.toLowerCase();
        
        // Basic visibility
        if (!visibleMappings.contains(mapping)) return false;
        
        // Visit Completed only if currently visiting
        if (mapping == 'visit_completed') {
          return lead.status == LeadStatus.visiting;
        }
        
        return true;
      }).toList();

      availableLeadStatuses.assignAll(filteredStatuses);
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
      final logsStr = (await _webService.getCallLogsByLead(lead.id)).payload ?? [];
      if (logsStr.isNotEmpty) {
        lastCallLog.value = logsStr.first; // newest first (ordered DESC)
        print('LeadDetail: Last call for lead ${lead.id}: status=${logsStr.first.callStatus}, leadStatus=${logsStr.first.leadStatus}');
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


  Future<void> makeCall({String? phoneNumber}) async {
    try {
      CallSession? session;
      final numberToCall = phoneNumber ?? (lead.phone.isNotEmpty ? lead.phone.first : '');

      if (Platform.isIOS) {
        session = await callController.makeCallForIos(
          phoneNumber: numberToCall,
        );
      } else {
        session = await callController.makeCall(
          phoneNumber: numberToCall,
        );
      }

      if (session == null) {
        selectedStatus.value = 'follow_up';
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
        selectedStatus.value = 'follow_up';
      } else if (session.durationInSeconds > 30) {
        selectedStatus.value = 'visiting';
      } else {
        selectedStatus.value = 'follow_up';
      }

    } catch (e) {
      print("object $e");
      Get.snackbar("Error", "Call failed: $e");
    }
  }



  whatsappMsg({String? phoneNumber}) {
    final numberToCall = phoneNumber ?? (lead.phone.isNotEmpty ? lead.phone.first : '');
    if (Platform.isIOS) {
      callController.launchWhatsAppChatForIos(numberToCall);
    } else {
      callController.sendWhatsAppMessage([numberToCall], "Hello");
    }
  }

  sendMobileSMS({String? phoneNumber}) {
    final numberToCall = phoneNumber ?? (lead.phone.isNotEmpty ? lead.phone.first : '');
    if (Platform.isIOS) {
      callController.sendSMS(numberToCall, "Hello");
    } else {
      callController.sendSMS(numberToCall, "Hello");
    }
  }

  Future<void> saveUpdate() async {
    try {
      isLoading.value = true;

      final String statusValue = selectedStatus.value;
      final bool requiresDateTime = statusValue == 'visiting' || statusValue == 'follow_up';

      if (requiresDateTime && (visitingDate.value == null || visitingTime.value == null)) {
        Get.snackbar(
          'Date & Time Required',
          'Please select a date and time for ${statusValue == 'visiting' ? 'Visiting' : 'Follow-up'}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
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

      // Build follow-up DateTime
      DateTime? resolvedFollowUpDate;
      String? resolvedFollowUpNotes;

      if (requiresDateTime && visitingDate.value != null) {
        final date = visitingDate.value!;
        final time = visitingTime.value ?? const TimeOfDay(hour: 10, minute: 0);
        resolvedFollowUpDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        resolvedFollowUpNotes = statusValue.capitalizeFirst;
      }

      final callLog = CallLogModel(
        id: '', // Will be generated by database
        leadId: lead.id,
        employeeId: employeeId,
        callStatus: session?.status ?? (lastCallSession.value?.status ?? 'Completed'),
        leadStatus: statusValue,
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
      final savedLog = await _webService.addCallLog(callLog);

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
