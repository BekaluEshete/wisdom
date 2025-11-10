import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wisdomwalk/models/wisdom_circle_model.dart';
import 'package:wisdomwalk/services/local_storage_service.dart';
import 'package:wisdomwalk/utils/error_messages.dart';

class WisdomCircleService {
  final String _baseUrl = 'https://wisdom-walk-app-7of9.onrender.com/api';
  final LocalStorageService _localStorageService = LocalStorageService();
  Map<String, dynamic> _lastResponse = {}; // Store last groups response

  // Helper to get auth headers
  Future<Map<String, String>> _getHeaders(BuildContext? context) async {
    final token = await _localStorageService.getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception(ErrorMessages.tokenMissing);
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get last API response
  Map<String, dynamic> getLastResponse() {
    return _lastResponse;
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
    try {
      // Handle both _id and id fields
      final id = data['_id']?.toString() ?? data['id']?.toString() ?? '';
      
      // Map avatar to imageUrl if imageUrl is not present
      final imageUrl = data['imageUrl']?.toString() ?? 
                      data['avatar']?.toString() ??
                      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=300&fit=crop';
      
      // Get member count from members array or memberCount field
      final members = data['members'] as List? ?? [];
      final memberCount = data['memberCount'] ?? members.length;
      
      // Get topicType from backend (if available), otherwise infer from name
      String? topicType = data['topicType']?.toString();
      if (topicType == null || topicType.isEmpty) {
        // Fallback: infer from name if topicType not provided
        final name = (data['name']?.toString() ?? '').toLowerCase();
        if (name.contains('single') || name.contains('purposeful')) {
          topicType = 'single';
        } else if (name.contains('marriage') || name.contains('ministry')) {
          topicType = 'marriage';
        } else if (name.contains('motherhood') || name.contains('mother')) {
          topicType = 'motherhood';
        } else if (name.contains('healing') || name.contains('forgiveness')) {
          topicType = 'healing';
        } else {
          // Default to groupType if nothing matches
          topicType = groupType;
        }
      }
      
      return WisdomCircleModel.fromJson({
        ...data,
        'id': id,
        '_id': id,
        'topicType': topicType,
        'imageUrl': imageUrl,
        'memberCount': memberCount is int ? memberCount : (memberCount as num?)?.toInt() ?? 0,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Fetch all available groups (circles)
  Future<List<WisdomCircleModel>> getWisdomCircles(
    BuildContext? context,
  ) async {
    final headers = await _getHeaders(null);
    final List<WisdomCircleModel> circles = [];

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/groups'), headers: headers)
          .timeout(
            Duration(seconds: 10),
            onTimeout: () {
              throw Exception(ErrorMessages.connectionTimeout);
            },
          );

      _lastResponse = json.decode(response.body); // Store response

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] &&
            (data['groups'] is List || data['data'] is List)) {
          final groupList = (data['groups'] ?? data['data']) as List;
          circles.addAll(
            groupList.map((item) {
              final groupType =
                  _groupTypeToId.containsKey(item['type']?.toString())
                      ? item['type']?.toString()
                      : 'public';
              return _mapToWisdomCircle(item, groupType!);
            }).toList(),
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception(ErrorMessages.circlesLoadFailed);
      } else if (response.statusCode == 403) {
        throw Exception(ErrorMessages.authenticationRequired);
      } else {
        throw Exception(ErrorMessages.fromStatusCode(response.statusCode));
      }
    } catch (e) {
      if (e is Exception && e.toString().contains(ErrorMessages.connectionTimeout)) {
        rethrow;
      }
      return circles;
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
              throw Exception(ErrorMessages.connectionTimeout);
            },
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
          throw Exception(ErrorMessages.circleDetailsFailed);
        }
      } else if (response.statusCode == 404) {
        throw Exception(ErrorMessages.circleDetailsFailed);
      } else {
        throw Exception(ErrorMessages.fromStatusCode(response.statusCode));
      }
    } catch (e) {
      rethrow;
    }
  }

  // Join a group
  Future<void> joinCircle({
    required String circleId,
    required String userId, // Keep for compatibility but backend uses auth token
  }) async {
    final headers = await _getHeaders(null);
    try {
      // Backend uses authenticated user from token, so we don't need to send userId in body
      final response = await http
          .post(
            Uri.parse('$_baseUrl/groups/$circleId/join'),
            headers: headers,
            // Empty body - backend uses authenticated user from token
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(ErrorMessages.circleJoinFailed);
      }
    } catch (e) {
      if (e is Exception && e.toString().contains(ErrorMessages.connectionTimeout)) {
        rethrow;
      }
      throw Exception(ErrorMessages.circleJoinFailed);
    }
  }

  // Leave a group
  Future<void> leaveCircle({
    required String circleId,
    required String userId, // Keep for compatibility but backend uses auth token
  }) async {
    final headers = await _getHeaders(null);
    try {
      // Backend uses authenticated user from token
      final response = await http
          .post(
            Uri.parse('$_baseUrl/groups/$circleId/leave'),
            headers: headers,
            // Empty body - backend uses authenticated user from token
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(ErrorMessages.circleLeaveFailed);
      }
    } catch (e) {
      if (e is Exception && e.toString().contains(ErrorMessages.connectionTimeout)) {
        rethrow;
      }
      throw Exception(ErrorMessages.circleLeaveFailed);
    }
  }

  // Fetch messages for a group chat
  Future<List<WisdomCircleMessage>> getCircleMessages({
    required String circleId,
    int limit = 50,
    int offset = 0,
  }) async {
    final headers = await _getHeaders(null);
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/groups/$circleId/chat/messages?limit=$limit&offset=$offset',
            ),
            headers: headers,
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final messagesList = data['messages'] ?? data['data'] ?? [];
          if (messagesList is List) {
            return messagesList
                .map((msg) => WisdomCircleMessage.fromJson(msg))
                .toList();
          }
          return [];
        } else {
          throw Exception(ErrorMessages.circleMessageLoadFailed);
        }
      } else if (response.statusCode == 404) {
        throw Exception(ErrorMessages.circleMessageLoadFailed);
      } else {
        throw Exception(ErrorMessages.fromStatusCode(response.statusCode));
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send a message to a group chat
  Future<WisdomCircleMessage> sendMessage({
    required String circleId,
    required String userId, // Keep for compatibility but backend uses auth token
    required String userName, // Keep for compatibility but backend uses auth token
    String? userAvatar, // Keep for compatibility but backend uses auth token
    required String content,
  }) async {
    final headers = await _getHeaders(null);
    try {
      // Backend uses authenticated user from token, so we only send content
      final response = await http
          .post(
            Uri.parse('$_baseUrl/groups/$circleId/chat/messages'),
            headers: headers,
            body: json.encode({
              'content': content,
              // Note: Backend uses authenticated user from token, not from body
            }),
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // The backend returns the message object in data['data']
          return WisdomCircleMessage.fromJson(data['data']);
        } else {
          throw Exception(ErrorMessages.circleMessageSendFailed);
        }
      } else if (response.statusCode == 404) {
        throw Exception(ErrorMessages.circleMessageSendFailed);
      } else {
        throw Exception(ErrorMessages.fromStatusCode(response.statusCode));
      }
    } catch (e) {
      if (e is Exception && e.toString().contains(ErrorMessages.connectionTimeout)) {
        rethrow;
      }
      throw Exception(ErrorMessages.circleMessageSendFailed);
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

      if (response.statusCode != 200) {
        throw Exception(ErrorMessages.actionFailed);
      }
    } catch (e) {
      throw Exception(ErrorMessages.actionFailed);
    }
  }
}
