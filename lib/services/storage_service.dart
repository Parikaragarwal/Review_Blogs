import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/user.dart';
import '../models/blog.dart';
import '../models/comment.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _blogsKey = 'blogs';
  static const String _commentsKey = 'comments';
  static const String _imagesDir = 'blog_images';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Get the directory for storing images
  Future<Directory> get _imagesDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, _imagesDir));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  // Save an image file and return its path
  Future<String> saveImage(File imageFile) async {
    final imagesDir = await _imagesDirectory;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
    final savedImage = await imageFile.copy(path.join(imagesDir.path, fileName));
    return savedImage.path;
  }

  // Delete an image file
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Users
  Future<List<User>> getUsers() async {
    final usersJson = _prefs.getStringList(_usersKey) ?? [];
    return usersJson
        .map((json) => User.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveUser(User user) async {
    final users = await getUsers();
    final existingIndex = users.indexWhere((u) => u.id == user.id);
    
    if (existingIndex >= 0) {
      users[existingIndex] = user;
    } else {
      users.add(user);
    }

    await _prefs.setStringList(
      _usersKey,
      users.map((u) => jsonEncode(u.toJson())).toList(),
    );
  }

  // Blogs
  Future<List<Blog>> getBlogs() async {
    final blogsJson = _prefs.getStringList(_blogsKey) ?? [];
    return blogsJson
        .map((json) => Blog.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<Blog?> saveBlog(Blog blog) async {
    try {
      final blogs = await getBlogs();
      final existingIndex = blogs.indexWhere((b) => b.id == blog.id);
      
      if (existingIndex >= 0) {
        blogs[existingIndex] = blog;
      } else {
        blogs.add(blog);
      }

      final blogJsonList = blogs.map((b) {
        try {
          final json = b.toJson();
          // Validate required fields
          if (json['id'] == null || json['title'] == null || json['content'] == null || 
              json['authorId'] == null || json['authorName'] == null) {
            print('Blog missing required fields: $json');
            return null;
          }
          return jsonEncode(json);
        } catch (e) {
          print('Error encoding blog: $e');
          return null;
        }
      }).whereType<String>().toList();

      await _prefs.setStringList(_blogsKey, blogJsonList);
      return blog;
    } catch (e) {
      print('Error saving blog: $e');
      return null;
    }
  }

  Future<void> updateBlog(Blog updatedBlog) async {
    final blogs = await getBlogs();
    final index = blogs.indexWhere((blog) => blog.id == updatedBlog.id);
    if (index != -1) {
      // If there's a new image and an old image, delete the old one
      if (updatedBlog.imagePath != null && 
          blogs[index].imagePath != null && 
          updatedBlog.imagePath != blogs[index].imagePath) {
        await deleteImage(blogs[index].imagePath!);
      }
      blogs[index] = updatedBlog;
      await _prefs.setStringList(
        _blogsKey,
        blogs.map((blog) => jsonEncode(blog.toJson())).toList(),
      );
    }
  }

  Future<void> deleteBlog(String id) async {
    final blogs = await getBlogs();
    blogs.removeWhere((blog) => blog.id == id);
    
    await _prefs.setStringList(
      _blogsKey,
      blogs.map((b) => jsonEncode(b.toJson())).toList(),
    );
  }

  // Comments
  Future<List<Comment>> getComments() async {
    final commentsJson = _prefs.getStringList(_commentsKey) ?? [];
    return commentsJson.map((json) => Comment.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveComment(Comment comment) async {
    final comments = await getComments();
    comments.add(comment);
    await _prefs.setStringList(
      _commentsKey,
      comments.map((comment) => jsonEncode(comment.toJson())).toList(),
    );
  }

  Future<List<Comment>> getCommentsForBlog(String blogId) async {
    final comments = await getComments();
    return comments.where((comment) => comment.blogId == blogId).toList();
  }
} 