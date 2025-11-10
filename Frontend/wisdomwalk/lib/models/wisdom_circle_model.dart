import 'package:flutter/foundation.dart';

class WisdomCircleModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;
  final List<WisdomCircleMessage> messages;
  final List<String> pinnedMessages;
  final List<WisdomCircleEvent> events;
  final String? topicType;
  final bool isPrivate;

  WisdomCircleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.memberCount = 0,
    this.messages = const [],
    this.pinnedMessages = const [],
    this.events = const [],
    this.topicType,
    this.isPrivate = false,
  });

  factory WisdomCircleModel.fromJson(Map<String, dynamic> json) {
    // Log full JSON for debugging
    print(
      'Parsing WisdomCircleModel for ID ${json['id'] ?? json['_id']}: $json',
    );

    // Handle isPrivate safely
    bool isPrivate = false;
    if (json.containsKey('isPrivate')) {
      if (json['isPrivate'] is bool) {
        isPrivate = json['isPrivate'] as bool;
      } else {
        print(
          'Invalid isPrivate type: ${json['isPrivate']?.runtimeType}, defaulting to false',
        );
      }
    } else {
      print('isPrivate field missing, defaulting to false');
    }

    // Handle isActive safely
    bool isActive = false;
    if (json.containsKey('isActive')) {
      if (json['isActive'] is bool) {
        isActive = json['isActive'] as bool;
      } else {
        print(
          'Invalid isActive type: ${json['isActive']?.runtimeType}, defaulting to false',
        );
      }
    }

    // Handle members safely for memberCount and isMuted
    int memberCount = 0;
    if (json.containsKey('members') && json['members'] is List) {
      final members = json['members'] as List<dynamic>;
      memberCount = members.length;
      for (var i = 0; i < members.length; i++) {
        final member = members[i];
        if (member is Map<String, dynamic>) {
          if (member.containsKey('isMuted')) {
            if (member['isMuted'] is! bool) {
              print(
                'Invalid isMuted type for member $i: ${member['isMuted']?.runtimeType}, defaulting to false',
              );
            }
          }
          // Check for other potential boolean fields in member
          member.forEach((key, value) {
            if (key.startsWith('is') && value is Map<String, dynamic>) {
              print('Unexpected map in member $i field: $key = $value');
            }
          });
        } else {
          print('Invalid member format at index $i: $member');
        }
      }
    }

    // Handle settings safely
    if (json.containsKey('settings') &&
        json['settings'] is Map<String, dynamic>) {
      final settings = json['settings'] as Map<String, dynamic>;
      settings.forEach((key, value) {
        if (key.startsWith('is') && value is Map<String, dynamic>) {
          print('Unexpected map in settings field: $key = $value');
        }
      });
    }

    // Check all top-level fields for unexpected maps in boolean contexts
    json.forEach((key, value) {
      if (key.startsWith('is') && value is Map<String, dynamic>) {
        print('Unexpected map in top-level field: $key = $value');
      }
    });

    return WisdomCircleModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Circle',
      description: json['description']?.toString() ?? '',
      imageUrl:
          json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=300&fit=crop',
      memberCount:
          (json['memberCount'] as int?) ??
          (json['participantsCount'] as int?) ??
          memberCount,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((message) {
                if (message is Map<String, dynamic>) {
                  try {
                    return WisdomCircleMessage.fromJson(message);
                  } catch (e) {
                    print('Error parsing message: $e, message: $message');
                    return null;
                  }
                }
                print('Invalid message format: $message');
                return null;
              })
              .whereType<WisdomCircleMessage>()
              .toList() ??
          [],
      pinnedMessages:
          (json['pinnedMessages'] as List<dynamic>?)
              ?.map((pm) {
                if (pm is String) {
                  return pm;
                } else if (pm is Map<String, dynamic> &&
                    pm['message'] is String) {
                  return pm['message'] as String;
                } else if (pm is Map<String, dynamic> &&
                    pm['message'] is Map<String, dynamic>) {
                  final message = pm['message'] as Map<String, dynamic>;
                  return message['_id']?.toString() ?? '';
                }
                print('Invalid pinnedMessage format: $pm');
                return null;
              })
              .whereType<String>()
              .toList() ??
          [],
      events:
          (json['events'] as List<dynamic>?)
              ?.map((event) {
                if (event is Map<String, dynamic>) {
                  try {
                    return WisdomCircleEvent.fromJson(event);
                  } catch (e) {
                    print('Error parsing event: $e, event: $event');
                    return null;
                  }
                }
                print('Invalid event format: $event');
                return null;
              })
              .whereType<WisdomCircleEvent>()
              .toList() ??
          [],
      topicType: json['topicType']?.toString() ?? json['type']?.toString(),
      isPrivate: isPrivate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'memberCount': memberCount,
      'messages': messages.map((message) => message.toJson()).toList(),
      'pinnedMessages': pinnedMessages,
      'events': events.map((event) => event.toJson()).toList(),
      'topicType': topicType,
      'isPrivate': isPrivate,
    };
  }
}

class WisdomCircleMessage {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final List<String> likes;

  WisdomCircleMessage({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.likes = const [],
  });

  factory WisdomCircleMessage.fromJson(Map<String, dynamic> json) {
    // Check for unexpected maps in boolean-like fields
    json.forEach((key, value) {
      if (key.startsWith('is') && value is Map<String, dynamic>) {
        print('Unexpected map in WisdomCircleMessage field: $key = $value');
      }
    });

    return WisdomCircleMessage(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['sender']?.toString() ?? '',
      userName:
          json['userName']?.toString() ??
          (json['sender'] is Map<String, dynamic>
              ? '${json['sender']['firstName'] ?? ''} ${json['sender']['lastName'] ?? ''}'
                  .trim()
              : 'Unknown User'),
      userAvatar:
          json['userAvatar']?.toString() ??
          (json['sender'] is Map<String, dynamic>
              ? (json['sender']['profilePicture']?.toString() ?? 
                 json['sender']['avatar']?.toString())
              : null),
      content: json['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      likes:
          (json['likes'] as List<dynamic>?)
              ?.map((like) => like.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likes': likes,
    };
  }
}

class WisdomCircleEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String platform;
  final String link;

  WisdomCircleEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.platform,
    required this.link,
  });

  factory WisdomCircleEvent.fromJson(Map<String, dynamic> json) {
    // Check for unexpected maps in boolean-like fields
    json.forEach((key, value) {
      if (key.startsWith('is') && value is Map<String, dynamic>) {
        print('Unexpected map in WisdomCircleEvent field: $key = $value');
      }
    });

    return WisdomCircleEvent(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Event',
      description: json['description']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      platform: json['platform']?.toString() ?? 'Unknown Platform',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'platform': platform,
      'link': link,
    };
  }
}

extension WisdomCircleModelExtension on WisdomCircleModel {
  WisdomCircleModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? memberCount,
    List<WisdomCircleMessage>? messages,
    List<String>? pinnedMessages,
    List<WisdomCircleEvent>? events,
    String? topicType,
    bool? isPrivate,
  }) {
    return WisdomCircleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      memberCount: memberCount ?? this.memberCount,
      messages: messages ?? this.messages,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      events: events ?? this.events,
      topicType: topicType ?? this.topicType,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}

extension WisdomCircleMessageExtension on WisdomCircleMessage {
  WisdomCircleMessage copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    DateTime? createdAt,
    List<String>? likes,
  }) {
    return WisdomCircleMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }
}
