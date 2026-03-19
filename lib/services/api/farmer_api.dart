import 'dart:convert';
import 'package:goathub/models/user.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class FarmerApi {
  static Future<List<Farmer>> getFarmers() async {
    try {
      final response = await http.get(
        Uri.parse('/api/farmers/'),
        headers: ApiClient.headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Farmer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching farmers: ');
      return [];
    }
  }
}
