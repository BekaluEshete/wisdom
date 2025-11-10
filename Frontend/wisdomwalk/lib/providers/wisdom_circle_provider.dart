import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisdomwalk/models/wisdom_circle_model.dart';
import 'package:wisdomwalk/services/wisdom_circle_service.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';
import 'package:wisdomwalk/utils/error_messages.dart';

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
      _circles = await _service.getWisdomCircles(context);
      
      // Get the last response to check membership
      final response = _service.getLastResponse();
      final groups = response['groups'] as List<dynamic>? ?? [];
      
      // Use isMember flag from backend response
      // The backend correctly sets isMember based on the authenticated user
      _joinedCircles = groups
          .where((group) {
            final isMember = group['isMember'] == true;
            return isMember;
          })
          .map((group) => group['_id']?.toString() ?? group['id']?.toString())
          .whereType<String>()
          .toList();
    } catch (e) {
      _error = ErrorMessages.fromException(e);
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
      
      // If circle is joined, fetch messages
      if (_joinedCircles.contains(circleId)) {
        try {
          final messages = await _service.getCircleMessages(circleId: circleId);
          if (_selectedCircle != null) {
            _selectedCircle = _selectedCircle!.copyWith(messages: messages);
          }
        } catch (e) {
          // Don't fail the whole operation if messages can't be fetched
        }
      }
    } catch (e) {
      _error = ErrorMessages.fromException(e);
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
        } catch (e) {
          // Don't fail the join operation if messages can't be fetched
        }
      }
      notifyListeners();
    } catch (e) {
      _error = ErrorMessages.fromException(e);
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
      notifyListeners();
    } catch (e) {
      _error = ErrorMessages.fromException(e);
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
      notifyListeners();
    } catch (e) {
      _error = ErrorMessages.fromException(e);
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
      notifyListeners();
    } catch (e) {
      _error = ErrorMessages.fromException(e);
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

}
