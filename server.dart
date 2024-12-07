import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

const String serverRoot = "lrh40x7k-5222.use.devtunnels.ms";

class Server {
  static dynamic getResponseBody(http.Response response) {
    String responseBody = response.body;
    responseBody = responseBody.replaceAll(":NaN", ":0");
    return jsonDecode(responseBody);
  }

  // Makes a post request to url with body
  static Future<http.Response> post(
      String url, Map body, Map<String, String> headers) async {
    headers['Content-type'] = 'application/json';
    headers['Accept'] = 'application/json';
    http.Response response = await http.post(
      Uri.https(serverRoot, url),
      headers: headers,
      body: jsonEncode(body),
    );

    return response;
  }
}
