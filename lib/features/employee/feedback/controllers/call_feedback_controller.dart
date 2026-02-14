import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/models/lead_model.dart';
import 'package:easy_callers_mobile/core/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/core/models/call_log_model.dart';
import 'package:uuid/uuid.dart';

class CallFeedbackController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  late LeadModel lead;
  
  final Rx<CallStatus?> callStatus = Rx<CallStatus?>(null);
  final Rx<CallLeadStatus?> leadStatus = Rx<CallLeadStatus?>(null);
  final TextEditingController feedbackController = TextEditingController();
  final Rx<DateTime?> followUpDate = Rx<DateTime?>(null);
  
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is LeadModel) {
      lead = Get.arguments as LeadModel;
    } else {
      Get.back();
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
        callStatus: callStatus.value,
        leadStatus: leadStatus.value,
        feedback: feedbackController.text,
        followUpDate: followUpDate.value,
        createdAt: DateTime.now(),
      );

      await _leadService.addCallLog(callLog);

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
