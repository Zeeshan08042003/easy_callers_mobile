import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';

class BatchLeadsController extends GetxController
    with GetTickerProviderStateMixin {
  final SupabaseService _supabase = Get.find<SupabaseService>();
  final AuthService _authService = Get.find<AuthService>();

  late final LeadBatchModel batch;
  late final TabController tabController;

  final RxBool isLoading = true.obs;
  final RxList<LeadModel> allLeads = <LeadModel>[].obs;
  final RxList<CallLogModel> attendedLeads = <CallLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    batch = Get.arguments as LeadBatchModel;
    tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        _fetchAllLeads(),
        _fetchAttendedLeads(),
      ]);
    } catch (e) {
      print('Error fetching batch leads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAllLeads() async {
    try {
      final response = await _supabase.leadsTable
          .select('''
            *,
            employees:assigned_to(first_name, last_name, manager_id),
            managers:uploaded_by(first_name, last_name)
          ''')
          .eq('batch_id', batch.id)
          .order('created_at', ascending: false);

      var leads = (response as List)
          .map((json) => LeadModel.fromJson(json))
          .toList();

      // For managers: only show leads that are either unassigned
      // or assigned to the current manager's own employees
      final managerId = _authService.currentManager.value?.id;
      if (managerId != null) {
        final webService = Get.find<WebService>();
        final myEmployees =
            (await webService.getEmployeesByManager(managerId)).payload ?? [];
        final myEmployeeIds = myEmployees.map((e) => e.id).toSet();

        leads = leads.where((lead) {
          // Show unassigned leads (no employee assigned yet)
          if (lead.assignedTo == null) return true;
          // Show leads assigned to this manager's employees
          return myEmployeeIds.contains(lead.assignedTo);
        }).toList();
      }

      allLeads.value = leads;
    } catch (e) {
      print('Error fetching all leads: $e');
    }
  }

  Future<void> _fetchAttendedLeads() async {
    try {
      // First get all lead IDs for this batch
      final leadIdsResponse = await _supabase.leadsTable
          .select('id, assigned_to')
          .eq('batch_id', batch.id);

      var leadEntries = (leadIdsResponse as List);

      // For managers: filter to only their own employees' leads
      final managerId = _authService.currentManager.value?.id;
      Set<String>? myEmployeeIds;
      if (managerId != null) {
        final webService = Get.find<WebService>();
        final myEmployees =
            (await webService.getEmployeesByManager(managerId)).payload ?? [];
        myEmployeeIds = myEmployees.map((e) => e.id).toSet();

        leadEntries = leadEntries.where((l) {
          final assignedTo = l['assigned_to'] as String?;
          if (assignedTo == null) return true;
          return myEmployeeIds!.contains(assignedTo);
        }).toList();
      }

      final leadIds = leadEntries.map((l) => l['id'] as String).toList();
      if (leadIds.isEmpty) return;

      // Fetch call logs for those leads, joined with lead and employee data
      final response = await _supabase.client
          .from('call_logs')
          .select('''
            *,
            lead:lead_id(id, name, phone, status, email, location),
            employee:employee_id(first_name, last_name)
          ''')
          .inFilter('lead_id', leadIds)
          .order('created_at', ascending: false);

      attendedLeads.value = (response as List)
          .map((json) => CallLogModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching attended leads: $e');
    }
  }
}
