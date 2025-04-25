import 'comment.dart';

class Blog {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> likes;
  final List<String> dislikes;
  final List<Comment> comments;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    List<String>? likes,
    List<String>? dislikes,
    List<Comment>? comments,
  }) : likes = likes ?? [],
       dislikes = dislikes ?? [],
       comments = comments ?? [];

  Blog copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likes,
    List<String>? dislikes,
    List<Comment>? comments,
  }) {
    return Blog(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      imagePath: json['imagePath']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      likes: List<String>.from(json['likes'] ?? []),
      dislikes: List<String>.from(json['dislikes'] ?? []),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((comment) => Comment.fromJson(comment))
          .toList() ?? [],
    );
  }
} 