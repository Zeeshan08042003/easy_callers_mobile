import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../webservices/model/leadModel.dart';
import 'LeadsPagination.dart';
import 'lead_card.dart';

class LeadList extends StatelessWidget {
  const LeadList({super.key, required this.status, required this.title});
  final String status;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<LeadPaginationController>()) {
      Get.delete<LeadPaginationController>(); // Clean old one
    }
    var controller = Get.put(LeadPaginationController(status: status));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 2,
        backgroundColor: Colors.grey.shade100,
        elevation: 2,
        leading: Icon(Icons.arrow_back),
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.pagingController.refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 10)),

            PagedSliverList<int, Leads>(
              pagingController: controller.pagingController,
              builderDelegate: PagedChildBuilderDelegate<Leads>(
                itemBuilder: (context, item, index) {
                  try {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LeadCard(lead: item, key: ValueKey(item.id)),
                    );
                  } catch (e, st) {
                    print("❌ Error in itemBuilder: $e\n$st");
                    return ListTile(
                      title: Text('⚠️ Failed to render item'),
                    );
                  }
                },

                // ✅ FIXED: Return normal widgets (not slivers)
                noItemsFoundIndicatorBuilder: (_) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 50),
                      SizedBox(height: 10),
                      Text("No leads found"),
                      SizedBox(height: 10),
                      Text("Status: $status", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                firstPageErrorIndicatorBuilder: (_) => Center(
                  child: Text("Something went wrong"),
                ),
                firstPageProgressIndicatorBuilder: (_) => Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
