part of 'webservices.dart';

extension LeadApi on WebService {
  Future<WebResponse<LeadModel>> getLeadData(
      {String? status, int? page, int? perPage}) async {

    Map<String, dynamic> params = {
      'status':status,
      'page':page.toString(),
      'per_page':perPage.toString()
    };

    final apiResponse =
    await callApi(
        method: HTTP_METHODS.GET,
        path: ['callers','my-leads'],
        isLeads: true,
        params: params,
        logParams: params
    );

    if (apiResponse.status == API_STATUS.SUCCESS) {
      var apiData =
      LeadModel.fromJson(jsonDecode(apiResponse.stringData ?? ''));
      WebResponse<LeadModel> webResponse =
      WebResponse(apiResponse: apiResponse);
      webResponse.payload = apiData;
      return webResponse;
    } else {
      return WebResponse(apiResponse: apiResponse);
    }
  }
}
