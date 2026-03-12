import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';

/// Represents a single background upload task.
class UploadTask {
  final String id;
  final String fileName;
  final String? projectId;
  final String? projectName;
  final String? managerId;
  final RxDouble progress;
  final RxString status; // 'uploading', 'done', 'error'
  final RxString message;
  final Rx<LeadBatchModel?> result;

  UploadTask({
    required this.id,
    required this.fileName,
    this.projectId,
    this.projectName,
    this.managerId,
  })  : progress = 0.0.obs,
        status = 'uploading'.obs,
        message = 'Preparing upload...'.obs,
        result = Rx<LeadBatchModel?>(null);

  bool get isUploading => status.value == 'uploading';
  bool get isDone => status.value == 'done';
  bool get isError => status.value == 'error';
}

/// Manages background Excel uploads so users can continue using the app.
///
/// Usage:
///   1. Call `startUpload()` — file picker opens, upload begins in background
///   2. A persistent banner/snackbar shows progress
///   3. User can navigate freely while upload continues
///   4. On completion, a success notification appears
class BackgroundUploadManager extends GetxService {
  final WebService _webService = Get.find<WebService>();

  /// Active upload tasks
  final RxList<UploadTask> activeTasks = <UploadTask>[].obs;

  /// Whether any upload is in progress
  bool get hasActiveUploads => activeTasks.any((t) => t.isUploading);

  /// The current/most recent task (for UI binding)
  UploadTask? get currentTask =>
      activeTasks.isNotEmpty ? activeTasks.last : null;

  // ============================================
  // START UPLOAD (MANAGER DASHBOARD)
  // ============================================

  /// Start a background upload for a project.
  /// File picker opens immediately, then upload runs in background.
  Future<void> startUpload({
    String? managerId,
    required String projectId,
    String? projectName,
  }) async {
    // 1. Pick the file first (this needs user interaction and must be awaited)
    // final pickerResult = await _webService.pickFileOnly();
    // if (pickerResult == null) return; // user cancelled
    dynamic pickerResult;

    final fileName = 'upload.xlsx'; // pickerResult.files.single.name;

    // 2. Create the task
    final task = UploadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      projectId: projectId,
      projectName: projectName,
      managerId: managerId,
    );
    activeTasks.add(task);

    // 3. Show persistent progress banner
    _showUploadBanner(task);

    // 4. Run upload in background (don't await — fire and forget)
    _executeUpload(task, pickerResult).then((_) {
      // Upload finished (success or error) — handled inside _executeUpload
    });
  }

  /// Start a background upload for the legacy flow (no project).
  Future<void> startUploadLegacy({
    required String managerId,
  }) async {
    /*
    final pickerResult = await _webService.pickFileOnly();
    if (pickerResult == null) return;

    final fileName = pickerResult.files.single.name;
    */
    final fileName = 'legacy_upload.xlsx';
    dynamic pickerResult;

    final task = UploadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: fileName,
      managerId: managerId,
    );
    activeTasks.add(task);

    _showUploadBanner(task);

    _executeUpload(task, pickerResult).then((_) {});
  }

  // ============================================
  // BACKGROUND EXECUTION
  // ============================================

  Future<void> _executeUpload(UploadTask task, dynamic pickerResult) async {
    try {
      task.message.value = 'Parsing Excel file...';
      task.progress.value = 0.1;

      LeadBatchModel? batch;

      if (task.projectId != null) {
        /*
        batch = await _webService.pickAndUploadLeadsToProjectFromResult(
          pickerResult: pickerResult,
          managerId: task.managerId,
          projectId: task.projectId!,
          onProgress: (p) {
            task.progress.value = p;
            _updateProgressMessage(task, p);
          },
        );
        */
      } else {
        /*
        batch = await _webService.pickAndUploadLeadsFromResult(
          pickerResult: pickerResult,
          managerId: task.managerId!,
          onProgress: (p) {
            task.progress.value = p;
            _updateProgressMessage(task, p);
          },
        );
        */
      }

      if (batch != null) {
        task.status.value = 'done';
        task.result.value = batch;
        task.progress.value = 1.0;
        task.message.value =
            '✅ Uploaded ${batch.totalLeads} leads${task.projectName != null ? ' to "${task.projectName}"' : ''}';

        // Show success notification
        Get.snackbar(
          'Upload Complete',
          '${batch.totalLeads} leads uploaded successfully from "${task.fileName}"',
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      } else {
        task.status.value = 'error';
        task.message.value = '❌ No leads found in the file';
      }
    } catch (e) {
      task.status.value = 'error';
      task.message.value = '❌ Upload failed: ${e.toString()}';

      Get.snackbar(
        'Upload Failed',
        e.toString(),
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }

    // Auto-remove completed tasks after a delay
    Future.delayed(const Duration(seconds: 10), () {
      activeTasks.remove(task);
      // Dismiss the banner if no more uploads
      if (!hasActiveUploads) {
        _dismissBanner();
      }
    });
  }

  void _updateProgressMessage(UploadTask task, double progress) {
    if (progress < 0.2) {
      task.message.value = 'Uploading file...';
    } else if (progress < 0.4) {
      task.message.value = 'Parsing Excel data...';
    } else if (progress < 0.6) {
      task.message.value = 'Creating lead batch...';
    } else if (progress < 0.9) {
      task.message.value =
          'Inserting leads... ${(progress * 100).toInt()}%';
    } else {
      task.message.value = 'Finishing up...';
    }
  }

  // ============================================
  // PERSISTENT BANNER UI
  // ============================================

  OverlayEntry? _bannerOverlay;

  void _showUploadBanner(UploadTask task) {
    _dismissBanner(); // Remove any existing banner

    _bannerOverlay = OverlayEntry(
      builder: (context) => _UploadBannerWidget(
        task: task,
        onDismiss: _dismissBanner,
      ),
    );

    // Insert into the overlay
    final overlay = Get.overlayContext != null
        ? Overlay.of(Get.overlayContext!)
        : null;

    if (overlay != null && _bannerOverlay != null) {
      overlay.insert(_bannerOverlay!);
    }
  }

  void _dismissBanner() {
    _bannerOverlay?.remove();
    _bannerOverlay = null;
  }
}

/// A persistent banner widget that shows upload progress.
/// Sits at the top of the screen and remains visible across navigation.
class _UploadBannerWidget extends StatelessWidget {
  final UploadTask task;
  final VoidCallback onDismiss;

  const _UploadBannerWidget({
    required this.task,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final isDone = task.isDone;
          final isError = task.isError;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError
                  ? Colors.red.shade800.withOpacity(0.95)
                  : isDone
                      ? Colors.green.shade700.withOpacity(0.95)
                      : const Color(0xFF2D201C).withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Icon
                    if (task.isUploading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    else if (isDone)
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20)
                    else
                      const Icon(Icons.error,
                          color: Colors.white, size: 20),

                    const SizedBox(width: 12),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.isUploading
                                ? 'Uploading "${task.fileName}"'
                                : isDone
                                    ? 'Upload Complete'
                                    : 'Upload Failed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.message.value,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Dismiss button (only if done/error)
                    if (!task.isUploading)
                      GestureDetector(
                        onTap: onDismiss,
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.7),
                          size: 18,
                        ),
                      ),
                  ],
                ),

                // Progress bar
                if (task.isUploading) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: task.progress.value,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 3,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}
