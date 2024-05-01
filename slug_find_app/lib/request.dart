import 'package:http/http.dart';

Future putMarker(uri, body) async {
Response response = await put(uri, headers: {'Content-Type': 'application/json'}, body: body);
return response.body;
} 