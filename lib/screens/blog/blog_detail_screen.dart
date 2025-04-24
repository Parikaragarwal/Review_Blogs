import 'package:flutter/material.dart';
import '../../models/blog.dart';
import '../../models/comment.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';

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
  late Blog _blog;
  List<Comment> _comments = [];
  final _commentController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _blog = widget.blog;
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await widget.storageService.getCommentsForBlog(_blog.id);
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
        blogId: _blog.id,
        userId: currentUser.id,
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
      if (_blog.likes.contains(currentUser.id)) {
        _blog = Blog(
          id: _blog.id,
          title: _blog.title,
          content: _blog.content,
          authorId: _blog.authorId,
          authorName: _blog.authorName,
          imagePath: _blog.imagePath,
          createdAt: _blog.createdAt,
          updatedAt: DateTime.now(),
          likes: _blog.likes.where((id) => id != currentUser.id).toList(),
          dislikes: _blog.dislikes,
        );
      } else {
        _blog = Blog(
          id: _blog.id,
          title: _blog.title,
          content: _blog.content,
          authorId: _blog.authorId,
          authorName: _blog.authorName,
          imagePath: _blog.imagePath,
          createdAt: _blog.createdAt,
          updatedAt: DateTime.now(),
          likes: [..._blog.likes, currentUser.id],
          dislikes: _blog.dislikes.where((id) => id != currentUser.id).toList(),
        );
      }
    });

    await widget.storageService.updateBlog(_blog);
  }

  Future<void> _toggleDislike() async {
    final currentUser = await widget.authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      if (_blog.dislikes.contains(currentUser.id)) {
        _blog = Blog(
          id: _blog.id,
          title: _blog.title,
          content: _blog.content,
          authorId: _blog.authorId,
          authorName: _blog.authorName,
          imagePath: _blog.imagePath,
          createdAt: _blog.createdAt,
          updatedAt: DateTime.now(),
          likes: _blog.likes,
          dislikes: _blog.dislikes.where((id) => id != currentUser.id).toList(),
        );
      } else {
        _blog = Blog(
          id: _blog.id,
          title: _blog.title,
          content: _blog.content,
          authorId: _blog.authorId,
          authorName: _blog.authorName,
          imagePath: _blog.imagePath,
          createdAt: _blog.createdAt,
          updatedAt: DateTime.now(),
          likes: _blog.likes.where((id) => id != currentUser.id).toList(),
          dislikes: [..._blog.dislikes, currentUser.id],
        );
      }
    });

    await widget.storageService.updateBlog(_blog);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_blog.title)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _blog.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: widget.authService.getCurrentUser(),
                    builder: (context, snapshot) {
                      final currentUser = snapshot.data;
                      final hasLiked = currentUser != null && _blog.likes.contains(currentUser.id);
                      final hasDisliked = currentUser != null && _blog.dislikes.contains(currentUser.id);
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              color: hasLiked ? Colors.blue : Colors.grey,
                            ),
                            onPressed: currentUser != null ? _toggleLike : null,
                          ),
                          Text('${_blog.likes.length}'),
                          IconButton(
                            icon: Icon(
                              Icons.thumb_down,
                              color: hasDisliked ? Colors.red : Colors.grey,
                            ),
                            onPressed: currentUser != null ? _toggleDislike : null,
                          ),
                          Text('${_blog.dislikes.length}'),
                        ],
                      );
                    },
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
                          child: ListTile(
                            title: Text(comment.content),
                            subtitle: Text(
                              comment.createdAt.toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
} 