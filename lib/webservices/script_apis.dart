part of 'webservices.dart';


extension ScriptApis on WebService {
  Future<WebResponse<GetScriptModel>> getAllScript(
      {String? status, int? page, int? perPage}) async {

    var pref = await SharedPreferences.getInstance();
    var callerId = pref.getString("userId");

    Map<String, dynamic> params = {
      'caller_id':callerId,
    };

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.GET,
        path: ['callers','get-scripts'],
        isLeads: true,
        body: params,
        logParams: params
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      GetScriptModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<GetScriptModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }


  Future<WebResponse<AddScriptModel>> addNewScript(
      String title, String script) async {

    var pref = await SharedPreferences.getInstance();
    var callerId = pref.getString("userId");
    Map<String, dynamic> body = {"title": title, "script": script, "caller_id":callerId};

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.POST,
        path: ['callers','add-script'],
        body: body,
        logParams: body
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      AddScriptModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<AddScriptModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }


  Future<WebResponse<DeleteScriptModel>> deleteScript({
    List<String?>? scriptId
}) async {
    Map<String, dynamic> body = {
      "ids": scriptId
    };

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.POST,
        path: ['callers','delete-script'],
        body: body,
        logParams: body
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      DeleteScriptModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<DeleteScriptModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }


  Future<WebResponse<DeleteScriptModel>> updateScript({
    String? scriptId,String? title,String? script
}) async {
    Map<String, dynamic> body = {
      "title": title,
      "script": script,
      "id": scriptId
    };

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.POST,
        path: ['callers','update-script'],
        body: body,
        logParams: body
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      DeleteScriptModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<DeleteScriptModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }




}
