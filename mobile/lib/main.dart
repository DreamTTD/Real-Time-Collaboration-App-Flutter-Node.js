
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:badges/badges.dart' as badges;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Collaboration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

// ============ AUTHENTICATION SCREEN ============
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;
  bool isLoading = false;
  String? selectedRole = 'editor';

  final String serverUrl = 'http://localhost:3001';

  Future<void> handleAuth() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final endpoint = isLogin ? '/api/auth/login' : '/api/auth/signup';
      final body = {
        'username': usernameController.text,
        'password': passwordController.text,
        if (!isLogin) 'role': selectedRole,
      };

      final response = await http.post(
        Uri.parse('$serverUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                userId: data['userId'],
                username: data['username'],
                role: data['role'],
                token: data['token'],
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.people_alt, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Real-Time Collaboration',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'editor', 'viewer']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => selectedRole = value,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : handleAuth,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLogin ? 'Login' : 'Sign Up'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? 'Create new account'
                      : 'Already have an account?',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ HOME SCREEN ============
class HomeScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String role;
  final String token;

  const HomeScreen({
    Key? key,
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;

  final String serverUrl = 'http://localhost:3001';

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    setState(() => isLoading = true);
    try {
      // Simulate fetching documents
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        documents = [
          {
            'id': 'doc_1',
            'title': 'Project Proposal',
            'lastModified': DateTime.now(),
            'collaborators': 3,
          },
          {
            'id': 'doc_2',
            'title': 'Meeting Notes',
            'lastModified': DateTime.now().subtract(const Duration(hours: 2)),
            'collaborators': 2,
          },
          {
            'id': 'doc_3',
            'title': 'API Documentation',
            'lastModified': DateTime.now().subtract(const Duration(days: 1)),
            'collaborators': 5,
          },
        ];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void createDocument() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        return AlertDialog(
          title: const Text('New Document'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Document title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  try {
                    final response = await http.post(
                      Uri.parse('$serverUrl/api/documents/create'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'title': titleController.text,
                        'creatorId': widget.userId,
                      }),
                    );

                    if (response.statusCode == 200) {
                      final data = jsonDecode(response.body);
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditorScreen(
                              documentId: data['documentId'],
                              documentTitle: data['title'],
                              userId: widget.userId,
                              username: widget.username,
                              role: widget.role,
                              token: widget.token,
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration Hub'),
        actions: [
          badges.Badge(
            badgeContent: Text(
              notifications.length.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => NotificationsPanel(
                    notifications: notifications,
                    onClear: () => setState(() => notifications.clear()),
                  ),
                );
              },
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Profile'),
                onTap: () => showProfile(context),
              ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                ),
              ),
            ],
          ),
        ],
      ),
      body: [
        DocumentsTab(
          documents: documents,
          isLoading: isLoading,
          onRefresh: fetchDocuments,
          userId: widget.userId,
          username: widget.username,
          role: widget.role,
          token: widget.token,
        ),
        TeamsTab(username: widget.username, role: widget.role),
        ProfileTab(
          username: widget.username,
          userId: widget.userId,
          role: widget.role,
        ),
      ][currentIndex],
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              onPressed: createDocument,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: CurvedNavigationBar(
        index: currentIndex,
        items: const [
          Icon(Icons.description),
          Icon(Icons.group),
          Icon(Icons.person),
        ],
        onTap: (index) => setState(() => currentIndex = index),
      ),
    );
  }

  void showProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${widget.username}'),
            const SizedBox(height: 8),
            Text('Role: ${widget.role.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('User ID: ${widget.userId}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ============ DOCUMENTS TAB ============
class DocumentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> documents;
  final bool isLoading;
  final VoidCallback onRefresh;
  final String userId;
  final String username;
  final String role;
  final String token;

  const DocumentsTab({
    Key? key,
    required this.documents,
    required this.isLoading,
    required this.onRefresh,
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: (_) => Future.value(onRefresh()),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No documents yet'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Document'),
                        onPressed: () {},
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return DocumentCard(
                      document: doc,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditorScreen(
                              documentId: doc['id'],
                              documentTitle: doc['title'],
                              userId: userId,
                              username: username,
                              role: role,
                              token: token,
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

// ============ DOCUMENT CARD ============
class DocumentCard extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onTap;

  const DocumentCard({
    Key? key,
    required this.document,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(document['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modified: ${DateFormat('MMM dd, HH:mm').format(document['lastModified'])}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${document['collaborators']} collaborators',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}

// ============ EDITOR SCREEN ============
class EditorScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final String userId;
  final String username;
  final String role;
  final String token;

  const EditorScreen({
    Key? key,
    required this.documentId,
    required this.documentTitle,
    required this.userId,
    required this.username,
    required this.role,
    required this.token,
  }) : super(key: key);

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late IO.Socket socket;
  final contentController = TextEditingController();
  List<Map<String, dynamic>> collaborators = [];
  List<Map<String, dynamic>> comments = [];
  bool isConnected = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeSocket();
  }

  void initializeSocket() {
    try {
      socket = IO.io(
        'http://localhost:3001',
        IO.OptionBuilder().setTransports(['websocket']).build(),
      );

      socket.onConnect((_) {
        if (mounted) {
          setState(() => isConnected = true);
          socket.emit('authenticate', {
            'userId': widget.userId,
            'token': widget.token,
          });
          socket.emit('join-room', {
            'documentId': widget.documentId,
            'userId': widget.userId,
            'role': widget.role,
          });
        }
      });

      socket.on('document-sync', (data) {
        if (mounted) {
          setState(() {
            contentController.text = data['content'] ?? '';
            collaborators = List<Map<String, dynamic>>.from(
              (data['collaborators'] ?? []).map((c) => Map<String, dynamic>.from(c)),
            );
          });
        }
      });

      socket.on('text-update', (data) {
        if (mounted && data['userId'] != widget.userId) {
          setState(() => contentController.text = data['content'] ?? '');
        }
      });

      socket.on('user-joined', (data) {
        if (mounted) {
          setState(() {
            collaborators = List<Map<String, dynamic>>.from(
              (data['collaborators'] ?? []).map((c) => Map<String, dynamic>.from(c)),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data['userId']} joined')),
          );
        }
      });

      socket.on('user-left', (data) {
        if (mounted) {
          setState(() {
            collaborators = List<Map<String, dynamic>>.from(
              (data['collaborators'] ?? []).map((c) => Map<String, dynamic>.from(c)),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data['userId']} left')),
          );
        }
      });

      socket.on('error-response', (data) {
        if (mounted) {
          setState(() => errorMessage = data['message']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${data['message']}')),
          );
        }
      });

      socket.onError((error) {
        if (mounted) {
          setState(() => errorMessage = error.toString());
        }
      });

      socket.onDisconnect((_) {
        if (mounted) {
          setState(() => isConnected = false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = e.toString());
      }
    }
  }

  void sendTextChange() {
    if (isConnected && widget.role != 'viewer') {
      socket.emit('text-change', {
        'documentId': widget.documentId,
        'userId': widget.userId,
        'change': {
          'type': 'insert',
          'position': 0,
          'text': contentController.text,
        },
        'role': widget.role,
      });
    }
  }

  void addComment(String text) {
    if (isConnected) {
      socket.emit('add-comment', {
        'documentId': widget.documentId,
        'userId': widget.userId,
        'position': contentController.selection.baseOffset,
        'text': text,
      });
    }
  }

  @override
  void dispose() {
    socket.emit('leave-room', {
      'documentId': widget.documentId,
      'userId': widget.userId,
    });
    socket.disconnect();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.documentTitle),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  isConnected ? 'Connected' : 'Offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => CollaboratorsPanel(
                  collaborators: collaborators,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.comment),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    title: const Text('Add Comment'),
                    content: TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter your comment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          addComment(controller.text);
                          Navigator.pop(context);
                        },
                        child: const Text('Post'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (errorMessage != null)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(errorMessage!)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => errorMessage = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: widget.role == 'viewer'
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      contentController.text.isEmpty
                          ? 'Document content will appear here...'
                          : contentController.text,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  )
                : TextField(
                    controller: contentController,
                    onChanged: (_) => sendTextChange(),
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: 'Start typing...',
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.zero,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============ COLLABORATORS PANEL ============
class CollaboratorsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> collaborators;

  const CollaboratorsPanel({
    Key? key,
    required this.collaborators,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Collaborators (${collaborators.length})',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...collaborators.map((collab) => ListTile(
            leading: CircleAvatar(
              child: Text(collab['userId'].toString()[0].toUpperCase()),
            ),
            title: Text(collab['userId']),
            subtitle: Text(collab['role'] ?? 'member'),
            trailing: Badge(
              label: Text(collab['role'] ?? ''),
            ),
          )),
        ],
      ),
    );
  }
}

// ============ NOTIFICATIONS PANEL ============
class NotificationsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final VoidCallback onClear;

  const NotificationsPanel({
    Key? key,
    required this.notifications,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (notifications.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No notifications'),
              ),
            )
          else
            ...notifications.map((notif) => ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(notif['message'] ?? ''),
              subtitle: Text(
                DateFormat('HH:mm').format(
                  DateTime.parse(notif['createdAt'] ?? DateTime.now().toString()),
                ),
              ),
            )),
        ],
      ),
    );
  }
}

// ============ TEAMS TAB ============
class TeamsTab extends StatelessWidget {
  final String username;
  final String role;

  const TeamsTab({
    Key? key,
    required this.username,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: ListTile(
            leading: Icon(Icons.group, color: Colors.blue),
            title: Text('Engineering Team'),
            subtitle: Text('8 members'),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            leading: Icon(Icons.group, color: Colors.green),
            title: Text('Design Team'),
            subtitle: Text('5 members'),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            leading: Icon(Icons.group, color: Colors.orange),
            title: Text('Management'),
            subtitle: Text('3 members'),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Create Team'),
          onPressed: () {},
        ),
      ],
    );
  }
}

// ============ PROFILE TAB ============
class ProfileTab extends StatelessWidget {
  final String username;
  final String userId;
  final String role;

  const ProfileTab({
    Key? key,
    required this.username,
    required this.userId,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Information',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Username: $username'),
                  const SizedBox(height: 8),
                  Text('Role: ${role.toUpperCase()}'),
                  const SizedBox(height: 8),
                  Text('User ID: $userId'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statistics',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Documents: 12'),
                      Text('Collaborations: 8'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Active Now'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
