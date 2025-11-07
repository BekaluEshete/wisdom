import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wisdomwalk/models/wisdom_circle_model.dart';
import 'package:wisdomwalk/services/local_storage_service.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class WisdomCircleService {
  final String _baseUrl = 'https://wisdom-walk-app-7of9.onrender.com/api';
  final LocalStorageService _localStorageService = LocalStorageService();
  Map<String, dynamic>? _lastResponse; // Store last groups response

  // Helper to get auth headers
  Future<Map<String, String>> _getHeaders(BuildContext? context) async {
    final token = await _localStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      print('No auth token found');
      throw Exception('Authentication token is missing');
    }
    if (context != null) {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      print('Fetching groups for user ID: $userId');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Map backend group types to frontend circle IDs
  final Map<String, String> _groupTypeToId = {
    'single': '1',
    'marriage': '2',
    'healing': '4',
    'motherhood': '3',
    'public': '0',
  };

  // Map backend group schemas to frontend WisdomCircleModel
  WisdomCircleModel _mapToWisdomCircle(
    Map<String, dynamic> data,
    String groupType,
  ) {
    print('Mapping group data for $groupType: $data');
    try {
      return WisdomCircleModel.fromJson({
        ...data,
        'topicType': data['type']?.toString() ?? groupType,
        'imageUrl':
            data['imageUrl'] ??
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=300&fit=crop',
        'memberCount': (data['members'] as List?)?.length ?? 0,
      });
    } catch (e) {
      print('Error mapping WisdomCircleModel: $e, data: $data');
      rethrow;
    }
  }

  // Fetch all available groups (circles)
  Future<List<WisdomCircleModel>> getWisdomCircles(
    BuildContext? context,
  ) async {
    final headers = await _getHeaders(context);
    final List<WisdomCircleModel> circles = [];

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/groups'), headers: headers)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              print('Timeout fetching groups');
              throw Exception('Connection timed out for groups');
            },
          );

      print(
        'Response for groups: status=${response.statusCode}, body=${response.body}',
      );
      _lastResponse = json.decode(response.body); // Store response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] &&
            (data['groups'] is List || data['data'] is List)) {
          final groupList = (data['groups'] ?? data['data']) as List;
          print('Found ${groupList.length} groups');
          circles.addAll(
            groupList.map((item) {
              final groupType =
                  _groupTypeToId.containsKey(item['type']?.toString())
                      ? item['type']?.toString()
                      : 'public';
              return _mapToWisdomCircle(item, groupType!);
            }).toList(),
          );
          print('Fetched circles: ${circles.length}');
        } else {
          print(
            'Failed to fetch groups: ${data['message'] ?? 'Invalid response format'}',
          );
        }
      } else if (response.statusCode == 404) {
        print('Groups route not found: ${response.body}');
        throw Exception(
          'Server error: Groups route not found. Contact support.',
        );
      } else if (response.statusCode == 403) {
        print('Access denied for groups: ${response.body}');
        throw Exception('Access restricted: Join a group to view chats.');
      } else {
        print('HTTP error for groups: ${response.statusCode}');
        throw Exception('Failed to fetch groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching groups: $e');
      return circles;
    }

    if (circles.isEmpty) {
      print('No circles fetched from any group type');
    }
    return circles;
  }

  // Fetch details for a specific group (circle)
  Future<WisdomCircleModel> getWisdomCircleDetails(String circleId) async {
    final headers = await _getHeaders(null);
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/groups/$circleId'), headers: headers)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Connection timed out for circle $circleId');
            },
          );
      print(
        'Response for circle $circleId: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['group'] != null) {
          final groupType =
              _groupTypeToId.containsKey(data['group']['type']?.toString())
                  ? data['group']['type']?.toString()
                  : 'public';
          return _mapToWisdomCircle(data['group'], groupType!);
        } else {
          throw Exception(
            'Failed to fetch circle details: ${data['message'] ?? 'Invalid response'}',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Circle details route not found. Contact support.');
      } else {
        throw Exception(
          'Failed to fetch circle details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching circle details: $e');
      rethrow;
    }
  }

  // Join a group
  Future<void> joinCircle({
    required String circleId,
    required String userId,
  }) async {
    final headers = await _getHeaders(null);
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/groups/$circleId/join'),
            headers: headers,
            body: json.encode({'userId': userId}),
          )
          .timeout(Duration(seconds: 10));
      print(
        'Join circle response: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to join circle: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error joining circle: $e');
      rethrow;
    }
  }

  // Leave a group
  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    final headers = await _getHeaders(null);
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/groups/$circleId/leave'),
            headers: headers,
            body: json.encode({'userId': userId}),
          )
          .timeout(Duration(seconds: 10));
      print(
        'Leave circle response: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to leave circle: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error leaving circle: $e');
      rethrow;
    }
  }

  // Send a message to a group chat
  Future<WisdomCircleMessage> sendMessage({
    required String circleId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
  }) async {
    final headers = await _getHeaders(null);
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/groups/$circleId/chat/messages'),
            headers: headers,
            body: json.encode({
              'userId': userId,
              'userName': userName,
              'userAvatar': userAvatar,
              'content': content,
            }),
          )
          .timeout(Duration(seconds: 10));
      print(
        'Send message response: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['message'] != null) {
          print('✅ Sent message to circle $circleId');
          print('📨 Message content: $content');

          return WisdomCircleMessage.fromJson(data['message']);
        } else {
          throw Exception(
            'Failed to send message: ${data['message'] ?? 'Invalid response'}',
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('Message route not found. Contact support.');
      } else {
        throw Exception(
          'Failed to send message: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Update message likes (reactions)
  Future<void> updateMessageLikes({
    required String circleId,
    required String messageId,
    required List<String> likes,
  }) async {
    final headers = await _getHeaders(null);
    try {
      final response = await http
          .post(
            Uri.parse(
              '$_baseUrl/groups/$circleId/chat/messages/$messageId/react',
            ),
            headers: headers,
            body: json.encode({'likes': likes}),
          )
          .timeout(Duration(seconds: 10));
      print(
        'Update message likes response: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update message likes: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error updating message likes: $e');
      rethrow;
    }
  }

  // Get last groups response
  Map<String, dynamic> getLastResponse() {
    return _lastResponse ?? {};
  }
}
