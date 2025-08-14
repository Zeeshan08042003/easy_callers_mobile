part of 'webservices.dart';

extension ResetFirstPassword on WebService{
  Future<WebResponse<MessageModel>> getPasswordReset(
      String confirmPassword, String password) async {
    Map<String, dynamic> params = {"password": password,"confirm_password": confirmPassword};

    final apiResponse = await callApi(
        method: HTTP_METHODS.POST,
        path: ['users','reset-first-password'],
        body: params,
        logParams: params
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      MessageModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<MessageModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }

}