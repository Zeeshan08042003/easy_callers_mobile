import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../webservices/webservices.dart';
import 'lead_card.dart';
import 'package:get/get.dart';

class LeadPaginationController extends GetxController {
  LeadPaginationController({required this.status});
  final String status;
  final PagingController<int, Leads> pagingController = PagingController(firstPageKey: 1);
  final WebService _webService = WebService();

  final int perPage = 20;

  @override
  void onInit() {
    pagingController.addPageRequestListener((pageKey) async {
      await fetchLeads(pageKey);
    });
    super.onInit();
  }

  Future<void> fetchLeads(int page) async {
    try {
      final resp = await _webService.getLeadData(
        status: status,
        perPage: perPage,
        page: page,
      );

      final hits = resp.payload?.data?.leads?.toList() ?? [];
      final total = resp.payload?.data?.total ?? 0;
      final totalPages = (total / perPage).ceil();
      final nextPage = page + 1;

      print('📡 Fetching leads for page $page');
      print('➡️ Total: ${resp.payload?.data?.total}');
      print('➡️ Leads: ${resp.payload?.data?.leads}');

      if (page >= totalPages) {
        pagingController.appendLastPage(hits);
      } else {
        pagingController.appendPage(hits, nextPage);
      }
    } catch (e) {
      pagingController.error = e;
    }
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  void refreshData() {
    pagingController.refresh();
  }
}
