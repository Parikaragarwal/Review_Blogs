import 'package:flutter/material.dart';
import '../../models/blog.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import 'blog_detail_screen.dart';
import 'create_blog_screen.dart';
import 'dart:io';

class BlogListScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;

  const BlogListScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<Blog> _blogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlogs();
  }

  Future<void> _loadBlogs() async {
    setState(() => _isLoading = true);
    try {
      final blogs = await widget.storageService.getBlogs();
      setState(() => _blogs = blogs);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blogs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await widget.authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blogs.isEmpty
              ? const Center(child: Text('No blogs yet'))
              : ListView.builder(
                  itemCount: _blogs.length,
                  itemBuilder: (context, index) {
                    final blog = _blogs[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (blog.imagePath != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              child: Image.file(
                                File(blog.imagePath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ListTile(
                            title: Text(blog.title),
                            subtitle: Text(
                              blog.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: SizedBox(
                              width: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.thumb_up, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${blog.likes.length}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.thumb_down, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${blog.dislikes.length}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlogDetailScreen(
                                    blog: blog,
                                    storageService: widget.storageService,
                                    authService: widget.authService,
                                  ),
                                ),
                              ).then((_) => _loadBlogs());
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBlogScreen(
                storageService: widget.storageService,
                authService: widget.authService,
              ),
            ),
          ).then((_) => _loadBlogs());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 