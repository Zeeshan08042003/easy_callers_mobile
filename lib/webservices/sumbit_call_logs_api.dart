part of 'webservices.dart';

extension SumbitCallLogsApi on WebService {
  Future<WebResponse<SubmitCallLogModel>> submitCallLog(
      {required String status,
      required String leadId,
      required String callDuration,
      required String notes}) async {
    Map<String, dynamic> params = {
      "status":status,
      "lead_id":leadId,
      "call_duration":callDuration,
      "notes":notes
    };

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.POST,
        isLeads: true,
        path: ['callers','add-call-log'],
        body: params,
        logParams: params
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      SubmitCallLogModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<SubmitCallLogModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }
}
