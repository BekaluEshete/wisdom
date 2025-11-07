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
      _joinedCircles =
          _circles
              .where((circle) {
                // Check if user is in members list (based on backend response structure)
                final response =
                    _service
                        .getLastResponse(); // Assume service stores last response
                final group = response['groups']?.firstWhere(
                  (g) => g['_id'] == circle.id,
                  orElse: () => null,
                );
                if (group == null || userId == null) return false;
                final members = group['members'] as List<dynamic>? ?? [];
                return members.any((m) => m['user']?['_id'] == userId);
              })
              .map((circle) => circle.id)
              .toList();
      print(
        'Fetched ${_circles.length} circles, joined: ${_joinedCircles.length}',
      );
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
      _joinedCircles.add(circleId);
      if (_selectedCircle?.id == circleId) {
        _selectedCircle = WisdomCircleModel(
          id: _selectedCircle!.id,
          name: _selectedCircle!.name,
          description: _selectedCircle!.description,
          imageUrl: _selectedCircle!.imageUrl,
          memberCount: _selectedCircle!.memberCount + 1,
          messages: _selectedCircle!.messages,
          pinnedMessages: _selectedCircle!.pinnedMessages,
          events: _selectedCircle!.events,
          topicType: _selectedCircle!.topicType,
          isPrivate: _selectedCircle!.isPrivate,
        );
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
        _selectedCircle = WisdomCircleModel(
          id: _selectedCircle!.id,
          name: _selectedCircle!.name,
          description: _selectedCircle!.description,
          imageUrl: _selectedCircle!.imageUrl,
          memberCount: _selectedCircle!.memberCount - 1,
          messages: _selectedCircle!.messages,
          pinnedMessages: _selectedCircle!.pinnedMessages,
          events: _selectedCircle!.events,
          topicType: _selectedCircle!.topicType,
          isPrivate: _selectedCircle!.isPrivate,
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
        _selectedCircle = WisdomCircleModel(
          id: _selectedCircle!.id,
          name: _selectedCircle!.name,
          description: _selectedCircle!.description,
          imageUrl: _selectedCircle!.imageUrl,
          memberCount: _selectedCircle!.memberCount,
          messages: [..._selectedCircle!.messages, message],
          pinnedMessages: _selectedCircle!.pinnedMessages,
          events: _selectedCircle!.events,
          topicType: _selectedCircle!.topicType,
          isPrivate: _selectedCircle!.isPrivate,
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
        _selectedCircle = WisdomCircleModel(
          id: _selectedCircle!.id,
          name: _selectedCircle!.name,
          description: _selectedCircle!.description,
          imageUrl: _selectedCircle!.imageUrl,
          memberCount: _selectedCircle!.memberCount,
          messages: updatedMessages,
          pinnedMessages: _selectedCircle!.pinnedMessages,
          events: _selectedCircle!.events,
          topicType: _selectedCircle!.topicType,
          isPrivate: _selectedCircle!.isPrivate,
        );
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

  // Temporary method to access last response (replace with proper backend fix)
  Map<String, dynamic> getLastResponse() {
    // Assume service stores last response; implement in WisdomCircleService
    return {};
  }
}
