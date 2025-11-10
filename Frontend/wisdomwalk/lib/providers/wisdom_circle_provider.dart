import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisdomwalk/models/wisdom_circle_model.dart';
import 'package:wisdomwalk/services/wisdom_circle_service.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';

class WisdomCircleProvider with ChangeNotifier {
  final WisdomCircleService _service = WisdomCircleService();
  List<WisdomCircleModel> _circles = [];
  List<String> _joinedCircles = [];
  WisdomCircleModel? _selectedCircle;
  bool _isLoading = false;
  String? _error;

  List<WisdomCircleModel> get circles => _circles;
  List<String> get joinedCircles => _joinedCircles;
  WisdomCircleModel? get selectedCircle => _selectedCircle;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCircles(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      print('Fetching circles for user ID: $userId');
      _circles = await _service.getWisdomCircles(context);
      
      // Get the last response to check membership
      final response = _service.getLastResponse();
      final groups = response['groups'] as List<dynamic>? ?? [];
      
      print('Backend response groups count: ${groups.length}');
      print('Sample group data: ${groups.isNotEmpty ? groups.first : "none"}');
      
      // Use isMember flag from backend response
      // The backend correctly sets isMember based on the authenticated user
      _joinedCircles = groups
          .where((group) {
            final isMember = group['isMember'] == true;
            final groupId = group['_id']?.toString() ?? group['id']?.toString();
            if (isMember) {
              print('User is member of circle: $groupId (${group['name']})');
            }
            return isMember;
          })
          .map((group) => group['_id']?.toString() ?? group['id']?.toString())
          .whereType<String>()
          .toList();
      
      print(
        'Fetched ${_circles.length} circles, joined: ${_joinedCircles.length}',
      );
      print('Joined circle IDs: $_joinedCircles');
    } catch (e) {
      _error = e.toString();
      print('Error fetching circles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCircleDetails(String circleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedCircle = await _service.getWisdomCircleDetails(circleId);
      print('Fetched details for circle $circleId');
      
      // If circle is joined, fetch messages
      if (_joinedCircles.contains(circleId)) {
        try {
          final messages = await _service.getCircleMessages(circleId: circleId);
          if (_selectedCircle != null) {
            _selectedCircle = _selectedCircle!.copyWith(messages: messages);
            print('Fetched ${messages.length} messages for circle $circleId');
          }
        } catch (e) {
          print('Error fetching messages for circle $circleId: $e');
          // Don't fail the whole operation if messages can't be fetched
        }
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching circle details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinCircle({
    required String circleId,
    required String userId,
  }) async {
    try {
      await _service.joinCircle(circleId: circleId, userId: userId);
      if (!_joinedCircles.contains(circleId)) {
        _joinedCircles.add(circleId);
      }
      if (_selectedCircle?.id == circleId) {
        _selectedCircle = _selectedCircle!.copyWith(
          memberCount: _selectedCircle!.memberCount + 1,
        );
        // Fetch messages after joining
        try {
          final messages = await _service.getCircleMessages(circleId: circleId);
          _selectedCircle = _selectedCircle!.copyWith(messages: messages);
          print('Fetched ${messages.length} messages after joining circle $circleId');
        } catch (e) {
          print('Error fetching messages after joining: $e');
          // Don't fail the join operation if messages can't be fetched
        }
      }
      print('Joined circle $circleId for user $userId');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error joining circle: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    try {
      await _service.leaveCircle(circleId: circleId, userId: userId);
      _joinedCircles.remove(circleId);
      if (_selectedCircle?.id == circleId) {
        _selectedCircle = _selectedCircle!.copyWith(
          memberCount: _selectedCircle!.memberCount > 0 
              ? _selectedCircle!.memberCount - 1 
              : 0,
          messages: [], // Clear messages when leaving
        );
      }
      print('Left circle $circleId for user $userId');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error leaving circle: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String circleId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
  }) async {
    try {
      final message = await _service.sendMessage(
        circleId: circleId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
      );
      if (_selectedCircle?.id == circleId) {
        _selectedCircle = _selectedCircle!.copyWith(
          messages: [..._selectedCircle!.messages, message],
        );
      }
      print('Sent message to circle $circleId');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error sending message: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleLikeMessage({
    required String circleId,
    required String messageId,
    required String userId,
    required bool isLiked,
  }) async {
    try {
      await _service.updateMessageLikes(
        circleId: circleId,
        messageId: messageId,
        likes:
            isLiked
                ? _selectedCircle!.messages
                    .firstWhere((m) => m.id == messageId)
                    .likes
                    .where((id) => id != userId)
                    .toList()
                : [
                  ..._selectedCircle!.messages
                      .firstWhere((m) => m.id == messageId)
                      .likes,
                  userId,
                ],
      );
      if (_selectedCircle?.id == circleId) {
        final updatedMessages =
            _selectedCircle!.messages.map((m) {
              if (m.id == messageId) {
                return WisdomCircleMessage(
                  id: m.id,
                  userId: m.userId,
                  userName: m.userName,
                  userAvatar: m.userAvatar,
                  content: m.content,
                  createdAt: m.createdAt,
                  likes:
                      isLiked
                          ? m.likes.where((id) => id != userId).toList()
                          : [...m.likes, userId],
                );
              }
              return m;
            }).toList();
        _selectedCircle = _selectedCircle!.copyWith(messages: updatedMessages);
      }
      print('Toggled like for message $messageId in circle $circleId');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error toggling like: $e');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}
