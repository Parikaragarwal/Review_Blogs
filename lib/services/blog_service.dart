import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/blog.dart';
import 'storage_service.dart';

class BlogService {
  final StorageService _storageService;
  final _uuid = const Uuid();

  BlogService(this._storageService);

  Future<List<Blog>> getBlogs() async {
    return _storageService.getBlogs();
  }

  Future<Blog?> getBlog(String id) async {
    final blogs = await _storageService.getBlogs();
    return blogs.firstWhere((blog) => blog.id == id);
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/blog_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<Blog?> createBlog({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    File? imageFile,
  }) async {
    try {
      String? imagePath;
      if (imageFile != null) {
        imagePath = await uploadImage(imageFile);
        if (imagePath == null) {
          throw Exception('Failed to upload image');
        }
      }

      final blog = Blog(
        id: _uuid.v4(),
        title: title,
        content: content,
        authorId: authorId,
        authorName: authorName,
        imagePath: imagePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likes: [],
        dislikes: [],
      );

      await _storageService.saveBlog(blog);
      return blog;
    } catch (e) {
      print('Error creating blog: $e');
      return null;
    }
  }

  Future<bool> updateBlog(Blog blog) async {
    try {
      await _storageService.saveBlog(blog);
      return true;
    } catch (e) {
      print('Error updating blog: $e');
      return false;
    }
  }

  Future<bool> deleteBlog(String blogId, String userId) async {
    try {
      print('BlogService: Attempting to delete blog $blogId by user $userId'); // Debug log
      
      // Get all blogs
      final blogs = await _storageService.getBlogs();
      final blogIndex = blogs.indexWhere((blog) => blog.id == blogId);
      
      if (blogIndex == -1) {
        print('BlogService: Blog not found'); // Debug log
        return false;
      }

      // Check if the user is the author of the blog
      if (blogs[blogIndex].authorId != userId) {
        print('BlogService: User is not the author'); // Debug log
        return false;
      }

      // Delete the blog's image if it exists
      if (blogs[blogIndex].imagePath != null) {
        await _storageService.deleteImage(blogs[blogIndex].imagePath!);
      }

      // Delete all comments associated with this blog
      final comments = await _storageService.getComments();
      final blogComments = comments.where((comment) => comment.blogId == blogId).toList();
      for (var comment in blogComments) {
        await _storageService.deleteComment(comment.id);
      }

      // Remove the blog
      blogs.removeAt(blogIndex);
      await _storageService.saveBlogs(blogs);
      
      print('BlogService: Blog and associated comments deleted successfully'); // Debug log
      return true;
    } catch (e) {
      print('BlogService: Error deleting blog: $e'); // Debug log
      return false;
    }
  }

  Future<bool> deleteComment(String blogId, String commentId, String userId) async {
    try {
      print('BlogService: Attempting to delete comment $commentId by user $userId'); // Debug log
      
      // Get all comments
      final comments = await _storageService.getComments();
      final commentIndex = comments.indexWhere((comment) => comment.id == commentId);
      
      if (commentIndex == -1) {
        print('BlogService: Comment not found in comments list'); // Debug log
        return false;
      }

      // Check if the user is the author of the comment
      if (comments[commentIndex].userId != userId) {
        print('BlogService: User is not the comment author'); // Debug log
        return false;
      }

      // Remove the comment from the comments list
      comments.removeAt(commentIndex);
      
      // Update the comments in storage
      await _storageService.saveComments(comments);
      
      print('BlogService: Comment deleted successfully'); // Debug log
      return true;
    } catch (e) {
      print('BlogService: Error deleting comment: $e'); // Debug log
      return false;
    }
  }
} 