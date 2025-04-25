import 'package:flutter/material.dart';
import '../../models/blog.dart';
import '../../models/comment.dart';
import '../../models/user.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/blog_service.dart';
import 'dart:io';

class BlogDetailScreen extends StatefulWidget {
  final Blog blog;
  final StorageService storageService;
  final AuthService authService;

  const BlogDetailScreen({
    super.key,
    required this.blog,
    required this.storageService,
    required this.authService,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  late final BlogService _blogService;
  late final AuthService _authService;
  late Blog blog;
  bool isLiked = false;
  bool isDisliked = false;
  final TextEditingController _commentController = TextEditingController();
  User? currentUser;
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _blogService = BlogService(widget.storageService);
    _authService = widget.authService;
    blog = widget.blog;
    _loadUserData();
    _loadComments();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      currentUser = user;
      isLiked = blog.likes.contains(user?.id ?? '');
      isDisliked = blog.dislikes.contains(user?.id ?? '');
    });
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await widget.storageService.getCommentsForBlog(blog.id);
      setState(() => _comments = comments);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;

    final currentUser = await widget.authService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to comment')),
        );
      }
      return;
    }

    try {
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        blogId: blog.id,
        userId: currentUser.id,
        authorName: currentUser.username,
        content: _commentController.text,
        createdAt: DateTime.now(),
      );

      await widget.storageService.saveComment(comment);
      _commentController.clear();
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = await widget.authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      if (blog.likes.contains(currentUser.id)) {
        blog = Blog(
          id: blog.id,
          title: blog.title,
          content: blog.content,
          authorId: blog.authorId,
          authorName: blog.authorName,
          imagePath: blog.imagePath,
          createdAt: blog.createdAt,
          updatedAt: DateTime.now(),
          likes: blog.likes.where((id) => id != currentUser.id).toList(),
          dislikes: blog.dislikes,
        );
      } else {
        blog = Blog(
          id: blog.id,
          title: blog.title,
          content: blog.content,
          authorId: blog.authorId,
          authorName: blog.authorName,
          imagePath: blog.imagePath,
          createdAt: blog.createdAt,
          updatedAt: DateTime.now(),
          likes: [...blog.likes, currentUser.id],
          dislikes: blog.dislikes.where((id) => id != currentUser.id).toList(),
        );
      }
    });

    await widget.storageService.updateBlog(blog);
  }

  Future<void> _toggleDislike() async {
    final currentUser = await widget.authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      if (blog.dislikes.contains(currentUser.id)) {
        blog = Blog(
          id: blog.id,
          title: blog.title,
          content: blog.content,
          authorId: blog.authorId,
          authorName: blog.authorName,
          imagePath: blog.imagePath,
          createdAt: blog.createdAt,
          updatedAt: DateTime.now(),
          likes: blog.likes,
          dislikes: blog.dislikes.where((id) => id != currentUser.id).toList(),
        );
      } else {
        blog = Blog(
          id: blog.id,
          title: blog.title,
          content: blog.content,
          authorId: blog.authorId,
          authorName: blog.authorName,
          imagePath: blog.imagePath,
          createdAt: blog.createdAt,
          updatedAt: DateTime.now(),
          likes: blog.likes.where((id) => id != currentUser.id).toList(),
          dislikes: [...blog.dislikes, currentUser.id],
        );
      }
    });

    await widget.storageService.updateBlog(blog);
  }

  Future<void> _deleteBlog() async {
    if (currentUser?.id != blog.authorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete this blog')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blog'),
        content: const Text('Are you sure you want to delete this blog? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        print('Attempting to delete blog: ${blog.id}'); // Debug log
        final success = await _blogService.deleteBlog(blog.id, currentUser?.id ?? '');
        print('Delete result: $success'); // Debug log
        
        if (success) {
          if (mounted) {
            Navigator.pop(context, true); // Return true to indicate blog was deleted
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blog deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete blog. You may not have permission.')),
            );
          }
        }
      } catch (e) {
        print('Error deleting blog: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred while deleting the blog')),
          );
        }
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    if (currentUser?.id != comment.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to delete this comment')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        print('Attempting to delete comment: ${comment.id}'); // Debug log
        final success = await _blogService.deleteComment(blog.id, comment.id, currentUser?.id ?? '');
        print('Delete result: $success'); // Debug log
        
        if (success) {
          setState(() {
            _comments.removeWhere((c) => c.id == comment.id);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Comment deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete comment. You may not have permission.')),
            );
          }
        }
      } catch (e) {
        print('Error deleting comment: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred while deleting the comment')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blog.title),
        actions: [
          if (currentUser?.id == blog.authorId)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteBlog,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (blog.imagePath != null)
                    Image.file(
                      File(blog.imagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    blog.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: isLiked ? Colors.blue : Colors.grey,
                        ),
                        onPressed: currentUser != null ? _toggleLike : null,
                      ),
                      Text('${blog.likes.length}'),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_down,
                          color: isDisliked ? Colors.red : Colors.grey,
                        ),
                        onPressed: currentUser != null ? _toggleDislike : null,
                      ),
                      Text('${blog.dislikes.length}'),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(comment.content),
                            subtitle: Text(
                              '${comment.authorName} • ${_formatDate(comment.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: currentUser?.id == comment.userId
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteComment(comment),
                                )
                              : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
} 