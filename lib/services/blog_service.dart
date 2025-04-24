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

  Future<bool> deleteBlog(String id) async {
    try {
      await _storageService.deleteBlog(id);
      return true;
    } catch (e) {
      print('Error deleting blog: $e');
      return false;
    }
  }
} 