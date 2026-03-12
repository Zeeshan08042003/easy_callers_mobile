import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_session_model.dart';
import 'package:easy_callers_mobile/features/employee/models/lead_status_model.dart';
import 'package:uuid/uuid.dart';

class CallFeedbackController extends GetxController {
  final WebService _webService = Get.find<WebService>();
  final AuthService _authService = Get.find<AuthService>();

  late LeadModel lead;
  CallSession? callSessionData;
  
  final Rx<CallStatus?> callStatus = Rx<CallStatus?>(null);
  final Rx<dynamic> leadStatus = Rx<dynamic>(null);
  final RxList<LeadStatusModel> availableLeadStatuses = <LeadStatusModel>[].obs;
  
  final TextEditingController feedbackController = TextEditingController();
  final Rx<DateTime?> followUpDate = Rx<DateTime?>(null);
  
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      if (args is LeadModel) {
        lead = args;
      } else if (args is Map) {
        lead = args['lead'] as LeadModel;
        callSessionData = args['session'] as CallSession?;
        
        if (callSessionData != null) {
          // Pre-populate call status from native result
          callStatus.value = CallStatus.fromString(callSessionData!.status);
        }
      }
    } else {
      Get.back();
      return;
    }
    fetchLeadStatuses();
  }

  Future<void> fetchLeadStatuses() async {
    try {
      isLoading.value = true;
      final managerId = _authService.currentEmployee.value?.managerId;
      final statusesList = (await _webService.getLeadStatuses(managerId)).payload ?? [];
      
      // Employee visible statuses: Follow-up, Not Interested, Visiting, Visit Completed
      final visibleMappings = ['follow_up', 'not_interested', 'visiting', 'visit_completed'];
      
      final filteredStatuses = statusesList.where((s) {
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitFeedback() async {
    if (callStatus.value == null || leadStatus.value == null) {
      Get.snackbar('Missing Info', 'Please select both call and lead status');
      return;
    }

    try {
      isLoading.value = true;
      final employeeId = _authService.currentEmployee.value?.id;
      if (employeeId == null) return;

      final callLog = CallLogModel(
        id: const Uuid().v4(),
        leadId: lead.id,
        employeeId: employeeId,
        callStatus: callStatus.value?.value,
        leadStatus: leadStatus.value,
        feedback: feedbackController.text,
        followUpDate: followUpDate.value,
        createdAt: DateTime.now(),
      );

      await _webService.addCallLog(callLog);

      Get.back();
      Get.snackbar('Success', 'Feedback submitted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit feedback: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFollowUpDate(DateTime date) {
    followUpDate.value = date;
  }
}
