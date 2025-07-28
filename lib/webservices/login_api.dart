part of "webservices.dart";


extension LoginApi on WebService {
  Future<WebResponse<LoginModel>> getLogin(
      String email, String password) async {
    Map<String, dynamic> params = {"email": email, "password": password};

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.POST,
        path: ['auth','login'],
        body: params,
        logParams: params
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      LoginModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<LoginModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }
}
