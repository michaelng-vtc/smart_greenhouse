import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
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
        context.read<ChatProvider>().fetchUsers(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();

    if (!auth.isAuthenticated) {
      return const Center(child: Text('Please login to chat'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
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
      body: chat.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chat.users.isEmpty
          ? const Center(child: Text('No other users found'))
          : ListView.builder(
              itemCount: chat.users.length,
              itemBuilder: (context, index) {
                final user = chat.users[index];
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
