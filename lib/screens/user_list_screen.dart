import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';
import 'package:smart_greenhouse/l10n/app_localizations.dart';
import 'chat_screen.dart';
import 'friend_list_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.userId != null) {
        context.read<FriendProvider>().fetchFriends(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final friendProvider = context.watch<FriendProvider>();

    if (!auth.isAuthenticated) {
      return Center(child: Text(AppLocalizations.of(context).pleaseLoginChat));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).chats),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: friendProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : friendProvider.friends.isEmpty
          ? Center(child: Text(AppLocalizations.of(context).noFriendsFound))
          : ListView.builder(
              itemCount: friendProvider.friends.length,
              itemBuilder: (context, index) {
                final user = friendProvider.friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                  title: Text(user.username),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          otherUserId: user.id,
                          otherUserName: user.username,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
