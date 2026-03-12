import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/core/services/web_service.dart';

/// Service for handling lead file uploads and parsing.
/// Supports Excel (.xlsx, .xls) files via Laravel Backend.
class LeadUploadService extends GetxService {
  final WebService _webService = Get.find<WebService>();

  final RxBool isUploading = false.obs;
  final RxBool isParsing = false.obs;
  final RxString error = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;

  // ============================================
  // FILE PICKING
  // ============================================

  /// Pick an Excel or PDF file from the device
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv', 'pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;
      return result.files.first;
    } catch (e) {
      error.value = 'Error picking file: $e';
      return null;
    }
  }

  // ============================================
  // UPLOAD & SAVE TO DATABASE
  // ============================================

  /// Full upload flow via Laravel Backend:
  /// Passes the file to the unified `/api/manager/batches/upload` endpoint
  Future<LeadBatchModel?> uploadAndSaveLeads({
    required PlatformFile file,
  }) async {
    try {
      isUploading.value = true;
      error.value = '';
      uploadProgress.value = 0.3; // Initial progress representing prepare
      
      List<http.MultipartFile> multipartFiles = [];
      String fieldName = 'file';
      
      if (file.bytes != null) {
        multipartFiles.add(
           http.MultipartFile.fromBytes(
             fieldName, 
             file.bytes!, 
             filename: file.name
           )
        );
      } else if (file.path != null) {
        multipartFiles.add(
           await http.MultipartFile.fromPath(
             fieldName, 
             file.path!, 
             filename: file.name
           )
        );
      } else {
        error.value = "Cannot read file.";
        return null;
      }

      uploadProgress.value = 0.6; // Request prepared, sending...

      final response = await _webService.callApiMultiPart(
        path: ['manager', 'batches', 'upload'],
        multiPartFiles: multipartFiles,
      );

      uploadProgress.value = 1.0; 

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final batchMap = data['data']['batch'];
        return LeadBatchModel.fromJson(batchMap);
      } else {
        // Try parsing the error format
        try {
           final decoded = jsonDecode(response.stringData!);
           error.value = decoded['message'] ?? decoded['error'] ?? "Failed to upload file.";
        } catch (_) {
           error.value = response.error_message ?? "Failed to upload file.";
        }
        return null;
      }
    } catch (e) {
      error.value = 'Error uploading leads: $e';
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  /// Same operation, but assigns directly to a project
  Future<LeadBatchModel?> uploadToProject({
    required PlatformFile file,
    required String projectId,
  }) async {
    try {
      isUploading.value = true;
      error.value = '';
      uploadProgress.value = 0.3; 
      
      List<http.MultipartFile> multipartFiles = [];
      String fieldName = 'file';
      
      if (file.bytes != null) {
        multipartFiles.add(http.MultipartFile.fromBytes(fieldName, file.bytes!, filename: file.name));
      } else if (file.path != null) {
        multipartFiles.add(await http.MultipartFile.fromPath(fieldName, file.path!, filename: file.name));
      } else {
        error.value = "Cannot read file.";
        return null;
      }

      uploadProgress.value = 0.6;

      final response = await _webService.callApiMultiPart(
        path: ['manager', 'batches', 'project-upload'],
        body: {'project_id': projectId},
        multiPartFiles: multipartFiles,
      );

      uploadProgress.value = 1.0; 

      if (response.status == API_STATUS.SUCCESS) {
        final data = jsonDecode(response.stringData!);
        final batchMap = data['data']['batch'];
        return LeadBatchModel.fromJson(batchMap);
      } else {
        try {
           final decoded = jsonDecode(response.stringData!);
           error.value = decoded['message'] ?? decoded['error'] ?? "Failed to upload file.";
        } catch (_) {
           error.value = response.error_message ?? "Failed to upload file.";
        }
        return null;
      }
    } catch (e) {
      error.value = 'Error uploading leads to project: $e';
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  // ============================================
  // LOCAL EXCEL PARSING (FALLBACK)
  // ============================================
  
  /// (Deprecated) We now send the raw file to Laravel Excel matcher, but keep this if local previews are needed
  Future<List<Map<String, dynamic>>> parseExcelFile(PlatformFile file) async {
     return []; // Stub since Laravel backend handles extraction in this architecture
  }
}
