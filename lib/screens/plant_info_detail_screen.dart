import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/plant_info.dart';
import '../providers/plant_info_provider.dart';
import '../providers/auth_provider.dart';

class PlantInfoDetailScreen extends StatefulWidget {
  final PlantInfo plantInfo;

  const PlantInfoDetailScreen({super.key, required this.plantInfo});

  @override
  State<PlantInfoDetailScreen> createState() => _PlantInfoDetailScreenState();
}

class _PlantInfoDetailScreenState extends State<PlantInfoDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantInfoProvider>().fetchComments(widget.plantInfo.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to post comments')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) return;

    final success = await context.read<PlantInfoProvider>().addComment(
      widget.plantInfo.id,
      auth.userId!,
      _commentController.text.trim(),
    );

    if (success && mounted) {
      _commentController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment posted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plantInfo.title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(
                '${widget.plantInfo.title}\n\n${widget.plantInfo.content}',
                subject: widget.plantInfo.title,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.plantInfo.imageUrl != null &&
                      widget.plantInfo.imageUrl!.isNotEmpty)
                    Image.network(
                      widget.plantInfo.imageUrl!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plantInfo.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy',
                          ).format(widget.plantInfo.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.plantInfo.content,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Consumer<PlantInfoProvider>(
                          builder: (context, provider, child) {
                            if (provider.isLoading &&
                                provider.comments.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (provider.comments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('No comments yet. Be the first!'),
                              );
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: provider.comments.length,
                              itemBuilder: (context, index) {
                                final comment = provider.comments[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      comment.username[0].toUpperCase(),
                                    ),
                                  ),
                                  title: Text(comment.username),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(comment.content),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'MMM dd, HH:mm',
                                        ).format(comment.createdAt),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
