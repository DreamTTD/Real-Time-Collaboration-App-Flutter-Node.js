// ============ MODELS ============

class User {
  final String id;
  final String username;
  final String email;
  final String role; // admin, editor, viewer
  final DateTime createdAt;
  final String status; // online, offline, away

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    this.status = 'offline',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'editor',
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };
}

class Document {
  final String id;
  final String title;
  final String content;
  final String creatorId;
  final List<Collaborator> collaborators;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<TextChange> history;
  final List<Comment>? comments;

  Document({
    required this.id,
    required this.title,
    required this.content,
    required this.creatorId,
    required this.collaborators,
    required this.createdAt,
    required this.lastModified,
    required this.history,
    this.comments,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      content: json['content'] ?? '',
      creatorId: json['creatorId'],
      collaborators: (json['collaborators'] as List?)
          ?.map((c) => Collaborator.fromJson(c))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: DateTime.parse(json['lastModified']),
      history: (json['history'] as List?)
          ?.map((h) => TextChange.fromJson(h))
          .toList() ?? [],
      comments: (json['comments'] as List?)
          ?.map((c) => Comment.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'creatorId': creatorId,
    'collaborators': collaborators.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'history': history.map((h) => h.toJson()).toList(),
    'comments': comments?.map((c) => c.toJson()).toList(),
  };
}

class Collaborator {
  final String userId;
  final String role; // admin, editor, viewer
  final DateTime joinedAt;

  Collaborator({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      userId: json['userId'],
      role: json['role'] ?? 'editor',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'role': role,
    'joinedAt': joinedAt.toIso8601String(),
  };
}

class TextChange {
  final String userId;
  final Change change;
  final DateTime timestamp;
  final int? cursorPosition;
  final String type; // text-change, formatting, insertion

  TextChange({
    required this.userId,
    required this.change,
    required this.timestamp,
    this.cursorPosition,
    required this.type,
  });

  factory TextChange.fromJson(Map<String, dynamic> json) {
    return TextChange(
      userId: json['userId'],
      change: Change.fromJson(json['change']),
      timestamp: DateTime.parse(json['timestamp']),
      cursorPosition: json['cursorPosition'],
      type: json['type'] ?? 'text-change',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'change': change.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'cursorPosition': cursorPosition,
    'type': type,
  };
}

class Change {
  final String type; // insert, delete, replace
  final int position;
  final String? text;
  final int? length;

  Change({
    required this.type,
    required this.position,
    this.text,
    this.length,
  });

  factory Change.fromJson(Map<String, dynamic> json) {
    return Change(
      type: json['type'],
      position: json['position'],
      text: json['text'],
      length: json['length'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'position': position,
    'text': text,
    'length': length,
  };
}

class Comment {
  final String id;
  final String userId;
  final int position;
  final String text;
  final DateTime createdAt;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.userId,
    required this.position,
    required this.text,
    required this.createdAt,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['userId'],
      position: json['position'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      replies: (json['replies'] as List?)
          ?.map((r) => Reply.fromJson(r))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'position': position,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'replies': replies.map((r) => r.toJson()).toList(),
  };
}

class Reply {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;

  Reply({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['id'],
      userId: json['userId'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

class Notification {
  final String id;
  final String documentId;
  final String message;
  final String type; // edit, comment, share, mention
  final String fromUserId;
  final DateTime createdAt;
  final bool read;

  Notification({
    required this.id,
    required this.documentId,
    required this.message,
    required this.type,
    required this.fromUserId,
    required this.createdAt,
    this.read = false,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      documentId: json['documentId'],
      message: json['message'],
      type: json['type'],
      fromUserId: json['fromUserId'],
      createdAt: DateTime.parse(json['createdAt']),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'documentId': documentId,
    'message': message,
    'type': type,
    'fromUserId': fromUserId,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };
}

class CursorPosition {
  final String userId;
  final int position;
  final int line;
  final DateTime timestamp;

  CursorPosition({
    required this.userId,
    required this.position,
    required this.line,
    required this.timestamp,
  });

  factory CursorPosition.fromJson(Map<String, dynamic> json) {
    return CursorPosition(
      userId: json['userId'],
      position: json['position'],
      line: json['line'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'position': position,
    'line': line,
    'timestamp': timestamp.toIso8601String(),
  };
}
