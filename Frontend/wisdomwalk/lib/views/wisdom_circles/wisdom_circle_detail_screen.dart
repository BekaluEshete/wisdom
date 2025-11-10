import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:wisdomwalk/providers/wisdom_circle_provider.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';
import 'package:wisdomwalk/utils/error_messages.dart';

class WisdomCircleDetailScreen extends StatefulWidget {
  final String circleId;

  const WisdomCircleDetailScreen({super.key, required this.circleId});

  @override
  State<WisdomCircleDetailScreen> createState() =>
      _WisdomCircleDetailScreenState();
}

class _WisdomCircleDetailScreenState extends State<WisdomCircleDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WisdomCircleProvider>();
      if (provider.selectedCircle == null ||
          provider.selectedCircle!.id != widget.circleId) {
        provider.fetchCircleDetails(widget.circleId);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Consumer<WisdomCircleProvider>(
          builder: (context, provider, child) {
            final circle = provider.selectedCircle;
            return Text(
              circle?.name ?? 'Wisdom Circle',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 18,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: _showCircleOptions,
          ),
        ],
      ),
      body: Consumer<WisdomCircleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE91E63)),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading circle: ${provider.error}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.fetchCircleDetails(widget.circleId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final circle = provider.selectedCircle;
          if (circle == null) {
            return const Center(child: Text('Circle not found'));
          }

          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final isJoined = provider.joinedCircles.contains(widget.circleId);
          final user = authProvider.currentUser;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Please log in to view this circle',
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                    ),
                    child: const Text('Log In'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(circle.imageUrl),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                circle.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${circle.memberCount} members',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              () => _toggleJoinStatus(provider, authProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isJoined
                                    ? Colors.grey[400]
                                    : const Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isJoined ? 'Joined' : 'Join'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      circle.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    circle.messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to start a conversation',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: circle.messages.length,
                          itemBuilder: (context, index) {
                            final message = circle.messages[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage:
                                            message.userAvatar != null
                                                ? NetworkImage(
                                                  message.userAvatar!,
                                                )
                                                : null,
                                        child:
                                            message.userAvatar == null
                                                ? Text(message.userName[0])
                                                : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              _formatTime(message.createdAt),
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    message.content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
              if (isJoined)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _sendMessage(provider, authProvider),
                        icon: const Icon(Icons.send, color: Color(0xFFE91E63)),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _toggleJoinStatus(
    WisdomCircleProvider provider,
    AuthProvider authProvider,
  ) async {
    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join or leave circles'),
          backgroundColor: Colors.red,
        ),
      );
      context.push('/login');
      return;
    }

    final isJoined = provider.joinedCircles.contains(widget.circleId);
    try {
      if (isJoined) {
        await provider.leaveCircle(circleId: widget.circleId, userId: user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👋 Left the circle'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await provider.joinCircle(circleId: widget.circleId, userId: user.id);
        // Refresh circle details to get updated messages
        await provider.fetchCircleDetails(widget.circleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Joined the circle!'),
              backgroundColor: Color(0xFFE91E63),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isJoined 
              ? ErrorMessages.circleLeaveFailed
              : ErrorMessages.circleJoinFailed
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendMessage(
    WisdomCircleProvider provider,
    AuthProvider authProvider,
  ) async {
    if (_messageController.text.trim().isEmpty) return;

    final user = authProvider.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send messages'),
          backgroundColor: Colors.red,
        ),
      );
      context.push('/login');
      return;
    }

    if (!provider.joinedCircles.contains(widget.circleId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please join the circle to send messages'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await provider.sendMessage(
        circleId: widget.circleId,
        userId: user.id,
        userName: user.fullName.isNotEmpty ? user.fullName : 'You',
        userAvatar: user.avatarUrl,
        content: _messageController.text.trim(),
      );
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorMessages.circleMessageSendFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCircleOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Circle Info'),
                  onTap: () {
                    Navigator.pop(context);
                    // Show circle info
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Members'),
                  onTap: () {
                    Navigator.pop(context);
                    // Show members
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Report'),
                  onTap: () {
                    Navigator.pop(context);
                    // Report circle
                  },
                ),
              ],
            ),
          ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
