import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:smart_greenhouse/l10n/app_localizations.dart';
import '../providers/friend_provider.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<FriendProvider>().fetchFriends(auth.userId!);
        context.read<FriendProvider>().fetchPendingRequests(auth.userId!);
        context.read<FriendProvider>().fetchSentRequests(auth.userId!);
      }
    });
  }

  Future<void> _addFriend() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final error = await context.read<FriendProvider>().sendFriendRequest(
      auth.userId!,
      username,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                '${AppLocalizations.of(context).friendRequestSent} $username',
          ),
        ),
      );
      if (error == null) _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendProvider = context.watch<FriendProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).friends),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      ).addFriendByUsername,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addFriend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context).add),
                ),
              ],
            ),
          ),
          if (friendProvider.pendingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context).pendingRequests,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friendProvider.pendingRequests.length,
              itemBuilder: (context, index) {
                final req = friendProvider.pendingRequests[index];
                return ListTile(
                  title: Text(req['username']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      friendProvider.acceptRequest(
                        auth.userId!,
                        int.parse(req['request_id'].toString()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                );
              },
            ),
            const Divider(),
          ],
          if (friendProvider.sentRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sent Requests',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: friendProvider.sentRequests.length,
              itemBuilder: (context, index) {
                final req = friendProvider.sentRequests[index];
                return ListTile(
                  title: Text(req['username']),
                  trailing: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Friends',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          Expanded(
            child: friendProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : friendProvider.friends.isEmpty
                ? const Center(child: Text('No friends yet'))
                : ListView.builder(
                    itemCount: friendProvider.friends.length,
                    itemBuilder: (context, index) {
                      final friend = friendProvider.friends[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            friend.username.isNotEmpty
                                ? friend.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ),
                        title: Text(friend.username),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Friend'),
                                content: Text(
                                  'Are you sure you want to delete ${friend.username}? This will also delete your chat history.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && context.mounted) {
                              await friendProvider.deleteFriend(
                                auth.userId!,
                                friend.id,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
