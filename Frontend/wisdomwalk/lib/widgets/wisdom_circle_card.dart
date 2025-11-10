import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:wisdomwalk/models/wisdom_circle_model.dart';
import 'package:wisdomwalk/providers/wisdom_circle_provider.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';
import 'package:wisdomwalk/services/local_storage_service.dart';

class WisdomCircleCard extends StatefulWidget {
  final WisdomCircleModel circle;
  final bool isJoined;
  final VoidCallback onTap;

  const WisdomCircleCard({
    Key? key,
    required this.circle,
    required this.isJoined,
    required this.onTap,
  }) : super(key: key);

  @override
  State<WisdomCircleCard> createState() => _WisdomCircleCardState();
}

class _WisdomCircleCardState extends State<WisdomCircleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _recentMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchRecentMessage();
  }

  Future<void> _fetchRecentMessage() async {
    // First, check if we have messages in the circle model
    if (widget.circle.messages.isNotEmpty) {
      final lastMessage = widget.circle.messages.last;
      setState(() {
        _recentMessage = '${lastMessage.userName}: "${lastMessage.content}"';
        _unreadCount = widget.circle.messages
            .where(
              (msg) => msg.createdAt.isAfter(
                DateTime.now().subtract(Duration(days: 1)),
              ),
            )
            .length;
      });
      return;
    }

    // If no messages in model, try fetching from API
    try {
      final token = await LocalStorageService().getAuthToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://wisdom-walk-app-7of9.onrender.com/api/groups/${widget.circle.id}/chat/messages?limit=1',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Handle different response structures
          final messagesList = data['messages'] ?? data['data'] ?? [];
          if (messagesList.isNotEmpty && messagesList is List) {
            final message = WisdomCircleMessage.fromJson(messagesList[0]);
            setState(() {
              _recentMessage = '${message.userName}: "${message.content}"';
              _unreadCount = 0; // Reset unread count since we only fetched 1 message
            });
          }
        }
      }
    } catch (e) {
      // Silently fail - not critical for card display
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WisdomCircleProvider>(context, listen: false);
    final hasNewMessages = _unreadCount > 0;
    final sampleMessage = _recentMessage ?? 'No recent messages';

    LinearGradient cardGradient = _getCardGradient();
    LinearGradient iconGradient = _getIconGradient();
    String buttonText = widget.isJoined ? 'Open' : 'Join';
    LinearGradient buttonGradient =
        widget.isJoined
            ? const LinearGradient(
              colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
            )
            : const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
            );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _animationController.forward().then((_) {
                    _animationController.reverse();
                  });
                  widget.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: iconGradient,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: iconGradient.colors.first.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.circle.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.circle.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.circle.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF636E72),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: buttonGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: buttonGradient.colors.first
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                if (widget.isJoined) {
                                  widget.onTap();
                                } else {
                                  final authProvider =
                                      Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  final userId = authProvider.currentUser?.id;
                                  if (userId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please log in to join circles',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await provider.joinCircle(
                                      circleId: widget.circle.id,
                                      userId: userId,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '✅ Joined ${widget.circle.name}!',
                                          ),
                                          backgroundColor:
                                              const Color(0xFF00B894),
                                          behavior:
                                              SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to join circle: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                buttonText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 14,
                                  color: Color(0xFF636E72),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.circle.memberCount} members',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF636E72),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasNewMessages) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE84393),
                                    Color(0xFFD63031),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '⭕ $_unreadCount new messages',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sampleMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3436),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getCardGradient() {
    // Use topicType to determine gradient, fallback to name if topicType is null
    final type = widget.circle.topicType?.toLowerCase() ?? 
                 widget.circle.name.toLowerCase();
    
    if (type.contains('single') || type.contains('purposeful')) {
      return const LinearGradient(
        colors: [Color(0xFFFFE4E6), Color(0xFFFFF0F2)],
      );
    } else if (type.contains('marriage') || type.contains('ministry')) {
      return const LinearGradient(
        colors: [Color(0xFFE8E4FF), Color(0xFFF0EDFF)],
      );
    } else if (type.contains('motherhood') || type.contains('mother')) {
      return const LinearGradient(
        colors: [Color(0xFFE4F3FF), Color(0xFFF0F9FF)],
      );
    } else if (type.contains('healing') || type.contains('forgiveness')) {
      return const LinearGradient(
        colors: [Color(0xFFE4FFE8), Color(0xFFF0FFF2)],
      );
    } else if (type.contains('mental') || type.contains('health') || type.contains('faith')) {
      return const LinearGradient(
        colors: [Color(0xFFFFF4E4), Color(0xFFFFF9F0)],
      );
    } else {
      // Default gradient based on circle name hash for consistency
      return const LinearGradient(
        colors: [Color(0xFFF5F5F5), Color(0xFFFAFAFA)],
      );
    }
  }

  LinearGradient _getIconGradient() {
    // Use topicType to determine gradient, fallback to name if topicType is null
    final type = widget.circle.topicType?.toLowerCase() ?? 
                 widget.circle.name.toLowerCase();
    
    if (type.contains('single') || type.contains('purposeful')) {
      return const LinearGradient(
        colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
      );
    } else if (type.contains('marriage') || type.contains('ministry')) {
      return const LinearGradient(
        colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
      );
    } else if (type.contains('motherhood') || type.contains('mother')) {
      return const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
      );
    } else if (type.contains('healing') || type.contains('forgiveness')) {
      return const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      );
    } else if (type.contains('mental') || type.contains('health') || type.contains('faith')) {
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFE65100)],
      );
    } else {
      // Default gradient
      return const LinearGradient(
        colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
      );
    }
  }
}
