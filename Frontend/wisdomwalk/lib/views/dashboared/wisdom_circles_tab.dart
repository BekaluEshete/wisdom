import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:wisdomwalk/models/wisdom_circle_model.dart';
import 'package:wisdomwalk/providers/auth_provider.dart';
import 'package:wisdomwalk/providers/wisdom_circle_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:wisdomwalk/services/local_storage_service.dart';
import 'package:wisdomwalk/widgets/wisdom_circle_card.dart';

class WisdomCirclesTab extends StatefulWidget {
  const WisdomCirclesTab({Key? key}) : super(key: key);

  @override
  State<WisdomCirclesTab> createState() => _WisdomCirclesTabState();
}

class _WisdomCirclesTabState extends State<WisdomCirclesTab>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  List<WisdomCircleEvent> _upcomingEvents = [];
  String? _eventsError;
  bool _isFetchingCircles = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
    _fetchUpcomingEvents();
    _fetchCirclesIfNeeded();
  }

  Future<void> _fetchCirclesIfNeeded() async {
    if (!_isFetchingCircles) {
      setState(() => _isFetchingCircles = true);
      try {
        await Provider.of<WisdomCircleProvider>(
          context,
          listen: false,
        ).fetchCircles(context);
      } finally {
        setState(() => _isFetchingCircles = false);
      }
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://wisdom-walk-app.onrender.com/api/events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization':
                  'Bearer ${await LocalStorageService().getAuthToken()}',
            },
          )
          .timeout(Duration(seconds: 10));

      print(
        'Events response: status=${response.statusCode}, body=${response.body}',
      ); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _upcomingEvents =
                (data['data'] as List)
                    .map((event) => WisdomCircleEvent.fromJson(event))
                    .toList();
            _eventsError = null;
          });
        } else {
          setState(() {
            _eventsError = data['message'] ?? 'Failed to fetch events';
          });
        }
      } else {
        setState(() {
          _eventsError = 'HTTP ${response.statusCode}: Failed to fetch events';
        });
      }
    } catch (e) {
      setState(() {
        _eventsError = 'Error fetching events: ${e.toString()}';
      });
      print('Error fetching events: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF74B9FF), Color(0xFF0984E3), Color(0xFF6C5CE7)],
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFF8F9FA)],
              ).createShader(bounds),
          child: const Text(
            'Wisdom Circles',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed:
                _isFetchingCircles
                    ? null
                    : () {
                      _fetchCirclesIfNeeded();
                      _fetchUpcomingEvents();
                    },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FA), Color(0xFFFFFFFF)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F4FD), Color(0xFFF0F8FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF74B9FF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Join topic-based communities for deeper connection',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D3436),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'My Circles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer<WisdomCircleProvider>(
                    builder: (context, provider, child) {
                      final myCircles =
                          provider.circles
                              .where(
                                (circle) =>
                                    provider.joinedCircles.contains(circle.id),
                              )
                              .toList();

                      if (provider.isLoading || _isFetchingCircles) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[100]!, Colors.grey[50]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF74B9FF),
                              ),
                            ),
                          ),
                        );
                      }

                      if (provider.error != null) {
                        String errorMessage =
                            provider.error!.contains('timed out')
                                ? 'Network issue: Unable to connect to server. Please check your internet.'
                                : provider.error!.contains('403')
                                ? 'Access restricted: Join a group to view chats.'
                                : 'Error loading circles: ${provider.error}';
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[50]!, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 32,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF636E72),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchCirclesIfNeeded,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF74B9FF),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (myCircles.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[50]!, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF74B9FF),
                                      Color(0xFF0984E3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.people_outline,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No circles joined yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF636E72),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Discover and join circles below',
                                style: TextStyle(color: Color(0xFF636E72)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children:
                            myCircles.map((circle) {
                              return WisdomCircleCard(
                                circle: circle,
                                isJoined: true,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/wisdom-circle/${circle.id}');
                                },
                              );
                            }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Discover New Circles',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer<WisdomCircleProvider>(
                    builder: (context, provider, child) {
                      final discoverCircles =
                          provider.circles
                              .where(
                                (circle) =>
                                    !provider.joinedCircles.contains(circle.id),
                              )
                              .toList();

                      if (provider.isLoading || _isFetchingCircles) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[100]!, Colors.grey[50]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF74B9FF),
                              ),
                            ),
                          ),
                        );
                      }

                      if (provider.error != null) {
                        String errorMessage =
                            provider.error!.contains('timed out')
                                ? 'Network issue: Unable to connect to server. Please check your internet.'
                                : provider.error!.contains('403')
                                ? 'Access restricted: Some groups require membership to view.'
                                : 'Error loading circles: ${provider.error}';
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[50]!, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 32,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF636E72),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchCirclesIfNeeded,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF74B9FF),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (discoverCircles.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[50]!, Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.explore,
                                size: 32,
                                color: Color(0xFF636E72),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No circles available to discover',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF636E72),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check back later or ensure you have an active internet connection',
                                style: TextStyle(color: Color(0xFF636E72)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children:
                            discoverCircles.map((circle) {
                              return WisdomCircleCard(
                                circle: circle,
                                isJoined: false,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final provider =
                                      Provider.of<WisdomCircleProvider>(
                                        context,
                                        listen: false,
                                      );
                                  provider.joinCircle(
                                    circleId: circle.id,
                                    userId:
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        ).currentUser?.id ??
                                        'user123',
                                  );
                                },
                              );
                            }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Upcoming Live Chats',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_eventsError != null)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[50]!, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 32,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _eventsError!.contains('timed out')
                                ? 'Network issue: Unable to connect to server. Please check your internet.'
                                : _eventsError!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF636E72),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchUpcomingEvents,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF74B9FF),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_upcomingEvents.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[50]!, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event,
                            size: 32,
                            color: Color(0xFF636E72),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming live chats',
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color(0xFF636E72),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check back later for new events',
                            style: TextStyle(color: Color(0xFF636E72)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._upcomingEvents.map(
                      (event) => _buildLiveChatItem(
                        event.title,
                        event.description,
                        _formatEventTime(event.date),
                        const LinearGradient(
                          colors: [Color(0xFF74B9FF), Color(0xFF0984E3)],
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveChatItem(
    String title,
    String subtitle,
    String time,
    LinearGradient gradient,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
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
            HapticFeedback.lightImpact();
            // Handle live chat tap (e.g., open event.link)
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatEventTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays > 1) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${dateTime.hour}:${dateTime.minute}';
    } else if (difference.inHours > 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute}';
    } else {
      return 'Soon';
    }
  }
}
