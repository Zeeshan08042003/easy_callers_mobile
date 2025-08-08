import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:easy_callers_mobile/webservices/model/leadModel.dart';
import 'package:easy_callers_mobile/webservices/model/submit_call_logs_model.dart';
import 'package:easy_callers_mobile/webservices/model/submit_call_logs_model.dart';
import 'package:easy_callers_mobile/webservices/model/submit_call_logs_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/utils.dart';
import 'model/login_model.dart';


part 'login_api.dart';
part 'lead_api.dart';
part 'sumbit_call_logs_api.dart';

class WebService {
  late Response response;
  GetConnect connect = Get.find<GetConnect>();

  var testUrl = "https://fc0c9843eb5f.ngrok-free.app";
  // var baseUrl = "https://ckfood.swypeuat.co.uk";
  var baseUrl = "https://solutionwise.swypeuat.co.uk";
  // var baseUrl = "https://b7e2-2401-4900-8815-97cf-f193-16cb-3b42-3ecd.ngrok-free.app";
  Future<ApiResponse> callApi({
    required HTTP_METHODS method,
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
    required List<String> path,
    bool? isLeads,
    dynamic logParams = "",
  }) async {
    String pathStr = path.join("/");
    if (pathStr.isEmpty) pathStr = "callApi";

    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    String user_id = prefs.getString('user_id') ?? '';

    Uri requestUrl;
    if (testUrl.isNotEmpty) {
      requestUrl = Uri.parse(testUrl).replace(
        pathSegments: ['api', ...path],
        queryParameters: params,
      );
    } else {
      requestUrl = Uri.parse(baseUrl).replace(
        pathSegments: ['backend', 'api', ...path],
        queryParameters: params,
      );
    }

    String platform = Platform.isAndroid ? "Android" : "iOS";

    var headers = {
      'Authorization': 'Bearer ${path.contains("login") ? "" : token}',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json',
    };

    if (isLeads == true) {
      headers['X-App-Agent'] = platform;
    }

    print("header : $headers");

    // Perform the request
    if (method == HTTP_METHODS.GET) {
      response = await connect.get(requestUrl.toString(), headers: headers);
    } else if (method == HTTP_METHODS.POST) {
      response = await connect.post(requestUrl.toString(), body, headers: headers);
    }

    if (kDebugMode) {
      print("API LOGS ${requestUrl.toString()}");
      print("body : $body");
      print("response.body : ${response.body}");
      print("response.body : ${response}");
      print("response.status.code : ${response.status.code}");
    }



    if (response.statusCode == 401) {
      return ApiResponse(
        status: API_STATUS.FAIL,
        stringData: jsonEncode(response.body),
        error_message: "API FAIL 401",
      );
    } else if (response.statusCode == 200 || response.statusCode == 201) {
      return ApiResponse(
        status: API_STATUS.SUCCESS,
        stringData: jsonEncode((response.body)),
      );
    } else if (response.statusCode == 500) {
      return ApiResponse(status: API_STATUS.ERROR);
    } else {
      return ApiResponse(
        status: API_STATUS.FAIL,
        stringData: jsonEncode((response.body)),
        error_message: "SOMETHING_WENT_WRONG",
        exception_message: "${response.statusCode.toString()}",
      );
    }
  }


  Future<ApiResponse> callApiMultiPart({
    Map<String, dynamic>? params,
    Map<String, dynamic>? body,
    List<http.MultipartFile>? multiPartFiles, // Accept a list of files
    required List<String> path,
    dynamic? logParams,
  }) async {
    String pathStr = path.join("/");
    if (pathStr.isEmpty) pathStr = "callApi";

    var pref = await SharedPreferences.getInstance();
    var token = pref.getString('token');
    print("token for image: $token");

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'multipart/form-data',
      'ngrok-skip-browser-warning': 'true',
      'Accept': 'application/json'
    };

    Uri requestUrl;
    if (testUrl.isNotEmpty) {
      requestUrl = Uri.parse(testUrl)
          .replace(pathSegments: ['api',...path], queryParameters: params);
    } else {
      requestUrl = Uri.parse(baseUrl)
          .replace(pathSegments: ['backend','api',...path], queryParameters: params);
    }

    print("Request URL: ${requestUrl.toString()}");

    var request = http.MultipartRequest('POST', requestUrl);
    request.headers.addAll(headers);

    if (body != null) {
      // Convert all `dynamic` values to `String`
      request.fields.addAll(
        body.map((key, value) => MapEntry(key, value.toString())),
      );
    }

    // Add multiple files to the request
    if (multiPartFiles != null && multiPartFiles.isNotEmpty) {
      request.files.addAll(multiPartFiles);
    }

    // print("Headers: ${request.headers}");
    // print("Fields: ${request.fields}");
    // print("Files: ${request.files}");

    try {
      var resp = await request.send().timeout(Duration(seconds: 60));
      print("Status Code: ${resp.statusCode}");

      var resBody = await resp.stream.bytesToString();
      print("Response Body: $resBody");

      if (resp.statusCode == 401) {
        return ApiResponse(
          status: API_STATUS.FAIL,
          stringData: resBody,
          error_message: "error 401",
        );
      } else if (resp.statusCode == 499) {
        return ApiResponse(status: API_STATUS.FAIL, stringData: resBody);
      } else if (resp.statusCode == 200) {
        return ApiResponse(status: API_STATUS.SUCCESS, stringData: resBody);
      } else if (resp.statusCode == 500) {
        return showSnackBar(message: "Something went wrong");
      } else if (resp.statusCode == 413) {
        return ApiResponse(
          status: API_STATUS.FAIL,
          stringData: resBody,
          error_message: "REQUEST_TOO_LARGE",
          exception_message: "${resp.statusCode.toString()}",
        );
      } else {
        return ApiResponse(
          status: API_STATUS.FAIL,
          stringData: resBody,
          error_message: "SOMETHING_WENT_WRONG",
          exception_message: "${resp.statusCode.toString()}",
        );
      }
    } catch (e) {
      print("Exception occurred: $e");
      if (e is TimeoutException) {
        print("Request timed out.");
      } else if (e is http.ClientException) {
        print("Client exception: ${e.message}");
      }
      return ApiResponse(
        status: API_STATUS.EXCEPTION,
        error_message: "SOMETHING_WENT_WRONG",
        exception_message: e.toString(),
      );
    }
  }


}


class WebResponse<T> {
  ApiResponse apiResponse;
  T? payload;

  WebResponse({this.payload, required this.apiResponse});
}


class AppUpdateResponseModel {
  bool? status;
  AppUpdateModel? data;
  String? message;
  int? customStatus;
  String? serverTime;

  AppUpdateResponseModel(
      {this.status,
        this.data,
        this.message,
        this.customStatus,
        this.serverTime});

  AppUpdateResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    data = json['data'] != null ? new AppUpdateModel.fromJson(json['data']) : null;
    message = json['message'];
    customStatus = json['custom_status'];
    serverTime = json['server_time'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['message'] = this.message;
    data['custom_status'] = this.customStatus;
    data['server_time'] = this.serverTime;
    return data;
  }
}

class AppUpdateModel {
  String? title;
  String? message;
  String? link;

  AppUpdateModel({this.title, this.message, this.link});

  AppUpdateModel.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    message = json['message'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['title'] = this.title;
    data['message'] = this.message;
    data['link'] = this.link;
    return data;
  }
}

enum HTTP_METHODS { POST, GET }

enum API_STATUS { SUCCESS, FAIL, ERROR, EXCEPTION }

class ApiResponse {
  API_STATUS status;
  String? stringData;
  String? exception_message;
  String? error_message;
  dynamic exception;

  ApiResponse(
      {required this.status,
        this.stringData,
        this.exception_message,
        this.exception,
        this.error_message});
}