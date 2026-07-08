import 'package:http/http.dart' as http;

const Duration httpTimeout = Duration(seconds: 15);

Future<http.Response> httpGet(Uri url, {Map<String, String>? headers}) =>
    http.get(url, headers: headers).timeout(httpTimeout);

Future<http.Response> httpPost(Uri url, {Map<String, String>? headers, Object? body}) =>
    http.post(url, headers: headers, body: body).timeout(httpTimeout);

Future<http.Response> httpPut(Uri url, {Map<String, String>? headers, Object? body}) =>
    http.put(url, headers: headers, body: body).timeout(httpTimeout);

Future<http.Response> httpDelete(Uri url, {Map<String, String>? headers}) =>
    http.delete(url, headers: headers).timeout(httpTimeout);
