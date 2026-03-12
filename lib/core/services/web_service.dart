import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebService {
  /// ================================
  /// CONFIGURATION
  /// ================================

  // For Android emulator it must be 10.0.2.2. For iOS simulator it can be 127.0.0.1.
  // We can adjust this if testing on real devices in the future.
  static final String baseUrl = Platform.isAndroid 
      ? 'http://10.0.2.2:8000/api'
      : 'http://127.0.0.1:8000/api';

  /// ================================
  /// HELPERS
  /// ================================

  String getDeviceType() {
    if (Platform.isIOS) return "ios";
    if (Platform.isAndroid) return "android";
    return "";
  }

  Future<String> getVersionCode() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.buildNumber;
    } catch (e) {
      return "1";
    }
  }

  void showSnackBar({required String message}) {
    // Uses GetX for simple snackbars
    Get.snackbar("Notice", message, snackPosition: SnackPosition.BOTTOM);
  }

  String convertExceptionAsString(dynamic e) {
    if (e is SocketException) return "No Internet connection";
    if (e is TimeoutException) return "Connection timed out";
    return e.toString();
  }

  /// Centralized URL builder
  Uri buildRequestUrl({
    required List<String> path,
    Map<String, dynamic>? params,
  }) {
    // Construct path from base url
    final baseUri = Uri.parse(baseUrl);
    
    // Combine base path with new path segments
    final List<String> pathSegments = [...baseUri.pathSegments, ...path];
    // Remove empty segments
    pathSegments.removeWhere((element) => element.isEmpty);

    return baseUri.replace(
      pathSegments: pathSegments,
      queryParameters: params,
    );
  }

  /// ================================
  /// NORMAL API CALL
  /// ================================

  Future<ApiResponse> callApi({
    required HTTP_METHODS method,
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
    required List<String> path,
    dynamic logParams = "",
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final timeZone = DateTime.now().timeZoneOffset.inMinutes.toString();

      final headers = {
        "User-Timezone-Offset": timeZone,
        if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
        'device-type': getDeviceType(),
        'version-code': await getVersionCode(),
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      };

      final requestUrl = buildRequestUrl(
        path: path,
        params: params,
      );

      http.Response resp;

      if (method == HTTP_METHODS.GET) {
        resp = await http.get(requestUrl, headers: headers).timeout(const Duration(seconds: 30));
      } else if (method == HTTP_METHODS.POST) {
        resp = await http.post(
          requestUrl,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 30));
      } else if (method == HTTP_METHODS.PUT) {
        resp = await http.put(
          requestUrl,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 30));
      } else {
        resp = await http.delete(
          requestUrl,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 30));
      }

      if (kDebugMode) {
        print("--- API CALL ---");
        print("METHOD: ${method.name}");
        print("URL: $requestUrl");
        if (body != null) print("Request Body: $body");
        print("Status Code: ${resp.statusCode}");
        print("Response: ${resp.body}");
        print("----------------");
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResponse(
          status: API_STATUS.SUCCESS,
          stringData: resp.body,
        );
      }

      if ([401, 403, 404, 409, 422, 500].contains(resp.statusCode)) {
        return ApiResponse(
          status: API_STATUS.ERROR,
          stringData: resp.body,
        );
      }

      return ApiResponse(
        status: API_STATUS.FAIL,
        stringData: resp.body,
        error_message: "Something went wrong",
        exception_message: resp.statusCode.toString(),
      );
    } catch (e) {
      if (e is SocketException) {
        showSnackBar(message: "Please check your internet connection");
      }

      return ApiResponse(
        status: API_STATUS.EXCEPTION,
        error_message: "Something went wrong",
        exception_message: convertExceptionAsString(e),
      );
    }
  }

  /// ================================
  /// MULTIPART API CALL
  /// ================================

  Future<ApiResponse> callApiMultiPart({
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
    List<http.MultipartFile>? multiPartFiles,
    required List<String> path,
    dynamic logParams,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final headers = {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'device-type': getDeviceType(),
        'Accept': 'application/json',
      };

      final requestUrl = buildRequestUrl(
        path: path,
        params: params,
      );

      final request = http.MultipartRequest('POST', requestUrl);
      request.headers.addAll(headers);

      if (body != null) {
        request.fields.addAll(
          body.map((k, v) => MapEntry(k, v.toString())),
        );
      }

      if (multiPartFiles != null) {
        request.files.addAll(multiPartFiles);
      }

      if (kDebugMode) {
        print("--- MULTIPART CALL ---");
        print("URL: $requestUrl");
      }

      final resp = await request.send().timeout(const Duration(seconds: 60));
      final resBody = await resp.stream.bytesToString();

      if (kDebugMode) {
        print("Status Code: ${resp.statusCode}");
        print("Response: $resBody");
        print("--------------------");
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return ApiResponse(
          status: API_STATUS.SUCCESS,
          stringData: resBody,
        );
      }

      if ([401, 403, 404, 409, 422, 500].contains(resp.statusCode)) {
        return ApiResponse(
          status: API_STATUS.ERROR,
          stringData: resBody,
        );
      }

      return ApiResponse(
        status: API_STATUS.FAIL,
        stringData: resBody,
        error_message: "Something went wrong",
        exception_message: resp.statusCode.toString(),
      );
    } catch (e) {
      if (e is SocketException) {
        showSnackBar(message: "Please check your internet connection");
      }

      return ApiResponse(
        status: API_STATUS.EXCEPTION,
        error_message: "Something went wrong",
        exception_message: e.toString(),
      );
    }
  }
}

/// ================================
/// ENUMS & MODELS
/// ================================

enum HTTP_METHODS { POST, GET, PUT, DELETE }

enum API_STATUS { SUCCESS, FAIL, ERROR, EXCEPTION }

class ApiResponse {
  API_STATUS status;
  String? stringData;
  String? exception_message;
  String? error_message;
  dynamic exception;

  ApiResponse({
    required this.status,
    this.stringData,
    this.exception_message,
    this.exception,
    this.error_message,
  });
}

class WebResponse<T> {
  ApiResponse apiResponse;
  T? payload;

  WebResponse({this.payload, required this.apiResponse});
}
