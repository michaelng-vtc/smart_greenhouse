import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
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
        SnackBar(content: Text(error ?? 'Friend request sent to $username')),
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
        title: const Text('Friends'),
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
                    decoration: const InputDecoration(
                      hintText: 'Add friend by username',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (friendProvider.pendingRequests.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pending Requests',
                  style: TextStyle(
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
                        req['request_id'],
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
