import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../models/item.dart';

class ApiService {
  static const String baseUrl = 'https://kiosk.prasklatechnology.com/api/v1';
  final http.Client _client = http.Client();

  // Helper to fetch authorization headers automatically with the current Firebase token
  Future<Map<String, String>> _getHeaders() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }
    
    // Force token refresh if expired
    final token = await user.getIdToken(true);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-Requested-With': 'XMLHttpRequest'
    };
  }

  // Handle standard response checks and throw clear error objects
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'success') {
        return body['data'];
      }
      throw Exception(body['message'] ?? 'Unknown error occurred');
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'HTTP Error ${response.statusCode}');
    }
  }

  // Perform HTTP queries with timeout and retry logic
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn, {
    int retries = 2,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await requestFn().timeout(const Duration(seconds: 10));
      } catch (e) {
        attempt++;
        if (attempt >= retries) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  // --- AUTHENTICATION & STAFF API ---

  Future<Map<String, dynamic>> registerAdmin(String name, String companyName, String? phoneNumber) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'companyName': companyName,
        'phoneNumber': phoneNumber ?? ''
      }),
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: headers,
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerStaff(String uid, String name, String email, String? phoneNumber) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('$baseUrl/users/staff'),
      headers: headers,
      body: jsonEncode({
        'uid': uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber ?? ''
      }),
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listStaff() async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('$baseUrl/users/staff'),
      headers: headers,
    ));
    return _processResponse(response) as List<dynamic>;
  }

  // --- CATEGORIES API ---

  Future<List<Category>> getCategories() async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
    ));
    final List<dynamic> data = _processResponse(response);
    return data.map((json) => Category.fromMap(json)).toList();
  }

  Future<Map<String, dynamic>> createCategory(Category category) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
      body: jsonEncode(category.toMap()),
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<void> updateCategory(Category category) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.put(
      Uri.parse('$baseUrl/categories/${category.id}'),
      headers: headers,
      body: jsonEncode(category.toMap()),
    ));
    _processResponse(response);
  }

  Future<void> deleteCategory(String id) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
    ));
    _processResponse(response);
  }

  // --- PRODUCTS API ---

  Future<List<Item>> getProducts({String? categoryId, String? search}) async {
    final headers = await _getHeaders();
    String query = '';
    if (categoryId != null || search != null) {
      final params = <String>[];
      if (categoryId != null) params.add('categoryId=$categoryId');
      if (search != null) params.add('search=${Uri.encodeComponent(search)}');
      query = '?' + params.join('&');
    }

    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('$baseUrl/products$query'),
      headers: headers,
    ));
    final List<dynamic> data = _processResponse(response);
    return data.map((json) => Item.fromMap(json, json['id'])).toList();
  }

  Future<Map<String, dynamic>> createProduct(Item item) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('$baseUrl/products'),
      headers: headers,
      body: jsonEncode({
        'name': item.name,
        'categoryId': item.categoryId,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
        'barcode': item.barcode,
        'minLevel': item.minLevel,
        'imageUrl': item.imageUrl
      }),
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<void> updateProduct(Item item) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.put(
      Uri.parse('$baseUrl/products/${item.id}'),
      headers: headers,
      body: jsonEncode({
        'name': item.name,
        'categoryId': item.categoryId,
        'quantity': item.quantity,
        'unit': item.unit,
        'price': item.price,
        'barcode': item.barcode,
        'minLevel': item.minLevel,
        'imageUrl': item.imageUrl
      }),
    ));
    _processResponse(response);
  }

  Future<void> deleteProduct(String id) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: headers,
    ));
    _processResponse(response);
  }

  // --- TRANSACTIONS API ---

  Future<Map<String, dynamic>> recordTransaction(String productId, int quantity, String type) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.post(
      Uri.parse('$baseUrl/transactions'),
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'type': type
      }),
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStats(String dateStr) async {
    final headers = await _getHeaders();
    final response = await _requestWithRetry(() => _client.get(
      Uri.parse('$baseUrl/transactions/stats?date=$dateStr'),
      headers: headers,
    ));
    return _processResponse(response) as Map<String, dynamic>;
  }
}
