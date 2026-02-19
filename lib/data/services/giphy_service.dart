import 'dart:convert';
import 'package:http/http.dart' as http;

class GiphyService {
  final String _apiKey = 'GJArd5OSgW0ODVG7tbQRPluiiRJisCFs';
  final String _baseUrl = 'https://api.giphy.com/v1';

  Future<List<String>> fetchTrendingStickers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stickers/trending?api_key=$_apiKey&limit=24&rating=g'),
    );
    return _parseGiphyResponse(response);
  }

  Future<List<String>> searchStickers(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/stickers/search?api_key=$_apiKey&q=$query&limit=24&rating=g'),
    );
    return _parseGiphyResponse(response);
  }

  Future<List<String>> fetchTrendingGifs() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/gifs/trending?api_key=$_apiKey&limit=24&rating=g'),
    );
    return _parseGiphyResponse(response);
  }

  Future<List<String>> searchGifs(String query) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/gifs/search?api_key=$_apiKey&q=$query&limit=24&rating=g'),
    );
    return _parseGiphyResponse(response);
  }

  List<String> _parseGiphyResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> images = data['data'];
      return images.map((img) => img['images']['fixed_height']['url'] as String).toList();
    }
    return [];
  }
}
