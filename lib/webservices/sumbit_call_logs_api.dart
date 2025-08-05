part of 'webservices.dart';

extension SumbitCallLogsApi on WebService {
  Future<WebResponse<SubmitCallLogModel>> submitCallLog(
      {required String status,
      required String leadId,
      required String callDuration,
      required String notes,required String callStatus,required String date,required TimeOfDay time}) async {

    String? format(String? dateStr, TimeOfDay? time) {
      if (dateStr == null || time == null) return null;

      try {
        final DateFormat dateFormat = DateFormat('d MMMM y');
        DateTime date = dateFormat.parse(dateStr);

        final combinedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

        return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(combinedDateTime);
      } catch (e) {
        print('Date parsing error: $e');
        return null;
      }
    }
    String? dateTime = format(date,time); // both could be null

    Map<String, dynamic> params = {
      "status": status,
      "lead_id": leadId,
      "call_duration": callDuration,
      "notes": notes,
      "call_status": callStatus,
      if (dateTime != null) "date_time": dateTime, // include only if not null
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
