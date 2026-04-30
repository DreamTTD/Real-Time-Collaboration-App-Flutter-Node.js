# 📡 API Documentation

Complete reference for all Backend endpoints and Socket.io events.

---

## 🔑 REST API Endpoints

### Base URL
```
http://localhost:3001
```

---

## Authentication

### Sign Up
Create a new user account.

**Endpoint**: `POST /api/auth/signup`

**Headers**:
```json
{
  "Content-Type": "application/json"
}
```

**Request Body**:
```json
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "securepassword123",
  "role": "editor"
}
```

**Response** (200 OK):
```json
{
  "userId": "user_1704067200000",
  "username": "alice",
  "role": "editor",
  "token": "token_user_1704067200000"
}
```

**Error** (400 Bad Request):
```json
{
  "error": "Username already exists"
}
```

---

### Login
Authenticate user credentials.

**Endpoint**: `POST /api/auth/login`

**Headers**:
```json
{
  "Content-Type": "application/json"
}
```

**Request Body**:
```json
{
  "username": "alice",
  "password": "securepassword123"
}
```

**Response** (200 OK):
```json
{
  "userId": "user_1704067200000",
  "username": "alice",
  "role": "editor",
  "token": "token_user_1704067200000"
}
```

**Error** (401 Unauthorized):
```json
{
  "error": "Invalid credentials"
}
```

---

## Documents

### Create Document
Create a new collaborative document.

**Endpoint**: `POST /api/documents/create`

**Headers**:
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer token_xxx"
}
```

**Request Body**:
```json
{
  "title": "Q1 Planning",
  "creatorId": "user_1704067200000"
}
```

**Response** (200 OK):
```json
{
  "documentId": "doc_1704067200000",
  "title": "Q1 Planning",
  "creatorId": "user_1704067200000",
  "createdAt": "2024-01-01T12:00:00Z"
}
```

---

### Get Document
Retrieve document content and metadata.

**Endpoint**: `GET /api/documents/:docId`

**Headers**:
```json
{
  "Authorization": "Bearer token_xxx"
}
```

**Path Parameters**:
- `docId` (string): Document ID

**Response** (200 OK):
```json
{
  "id": "doc_1704067200000",
  "title": "Q1 Planning",
  "content": "# Meeting Notes\nDiscussed Q1 goals...",
  "collaborators": [
    {
      "userId": "user_1704067200000",
      "role": "admin",
      "joinedAt": "2024-01-01T12:00:00Z"
    }
  ],
  "lastModified": "2024-01-01T13:45:00Z"
}
```

**Error** (404 Not Found):
```json
{
  "error": "Document not found"
}
```

---

### Get Document List
Retrieve all documents for a user.

**Endpoint**: `GET /api/documents`

**Headers**:
```json
{
  "Authorization": "Bearer token_xxx"
}
```

**Query Parameters**:
- `limit` (number, optional): Number of documents to return (default: 10)
- `skip` (number, optional): Number of documents to skip for pagination (default: 0)

**Response** (200 OK):
```json
{
  "documents": [
    {
      "id": "doc_1",
      "title": "Document 1",
      "lastModified": "2024-01-01T13:45:00Z",
      "collaborators": 3
    }
  ],
  "total": 15
}
```

---

### Update Document
Update document metadata (title, etc).

**Endpoint**: `PUT /api/documents/:docId`

**Headers**:
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer token_xxx"
}
```

**Request Body**:
```json
{
  "title": "Updated Title"
}
```

**Response** (200 OK):
```json
{
  "id": "doc_1704067200000",
  "title": "Updated Title",
  "lastModified": "2024-01-01T14:00:00Z"
}
```

---

### Delete Document
Remove a document (admin only).

**Endpoint**: `DELETE /api/documents/:docId`

**Headers**:
```json
{
  "Authorization": "Bearer token_xxx"
}
```

**Response** (200 OK):
```json
{
  "message": "Document deleted successfully"
}
```

---

## Health & Status

### Health Check
Check server status.

**Endpoint**: `GET /api/health`

**Response** (200 OK):
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00Z",
  "activeConnections": 42,
  "activeRooms": 15
}
```

---

---

## 🔌 Socket.io Events

### Connection Events

#### Connect
Emitted when client connects to server.

**Client-side listener**:
```dart
socket.onConnect((_) {
  print('Connected to server');
});
```

#### Authenticate
Authenticate user with server.

**Emit**:
```dart
socket.emit('authenticate', {
  'userId': 'user_1704067200000',
  'token': 'token_user_1704067200000'
});
```

**Listen for response**:
```dart
socket.on('auth-success', (data) {
  print('Authentication successful: ${data['userId']}');
});
```

---

### Room Management Events

#### Join Room
Join a document collaboration room.

**Emit**:
```dart
socket.emit('join-room', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'role': 'editor'
});
```

**Server broadcasts** to all users in room:
```dart
socket.on('user-joined', (data) {
  print('${data['userId']} joined');
  print('Total users: ${data['totalUsers']}');
});
```

**Server sends current document state** to joining user:
```dart
socket.on('document-sync', (data) {
  print('Document content: ${data['content']}');
  print('Collaborators: ${data['collaborators']}');
});
```

---

#### Leave Room
Leave a document collaboration room.

**Emit**:
```dart
socket.emit('leave-room', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000'
});
```

**Server broadcasts** to remaining users:
```dart
socket.on('user-left', (data) {
  print('${data['userId']} left');
});
```

---

### Real-Time Editing Events

#### Text Change
Send text modification (insert, delete, replace).

**Emit**:
```dart
socket.emit('text-change', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'role': 'editor',
  'change': {
    'type': 'insert',  // 'insert', 'delete', or 'replace'
    'position': 45,
    'text': 'new text',
    'length': null  // For delete operations
  },
  'cursorPosition': 54
});
```

**Server broadcasts**:
```dart
socket.on('text-update', (data) {
  print('${data['userId']} made changes');
  print('New content: ${data['content']}');
});
```

---

#### Cursor Movement
Broadcast cursor position to other users.

**Emit**:
```dart
socket.emit('cursor-move', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'position': 54,
  'line': 3
});
```

**Server broadcasts**:
```dart
socket.on('cursor-update', (data) {
  print('${data['userId']} cursor at ${data['position']}');
});
```

---

#### Format Text
Apply formatting (bold, italic, etc).

**Emit**:
```dart
socket.emit('format-text', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'role': 'editor',
  'format': 'bold',  // 'bold', 'italic', 'underline', 'code'
  'startPos': 10,
  'endPos': 20
});
```

**Server broadcasts**:
```dart
socket.on('format-update', (data) {
  print('${data['userId']} applied ${data['format']}');
});
```

---

#### Insert Element
Insert special elements (images, tables, etc).

**Emit**:
```dart
socket.emit('insert-element', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'role': 'editor',
  'elementType': 'image',  // 'image', 'table', 'code-block'
  'position': 100,
  'content': {
    'url': 'https://example.com/image.jpg'
  }
});
```

**Server broadcasts**:
```dart
socket.on('element-inserted', (data) {
  print('${data['userId']} inserted ${data['elementType']}');
});
```

---

### Collaboration Events

#### Add Comment
Add an inline comment at a position.

**Emit**:
```dart
socket.emit('add-comment', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'position': 45,
  'text': 'This needs review'
});
```

**Server broadcasts**:
```dart
socket.on('comment-added', (comment) {
  print('Comment: ${comment['text']}');
  print('By: ${comment['userId']}');
});
```

---

#### Reply to Comment
Add a reply to an existing comment.

**Emit**:
```dart
socket.emit('reply-comment', {
  'documentId': 'doc_1704067200000',
  'commentId': 'comment_1704067200000',
  'userId': 'user_1704067200000',
  'text': 'Agreed, I can fix this.'
});
```

**Server broadcasts**:
```dart
socket.on('comment-reply', (data) {
  print('Reply to ${data['commentId']}: ${data['reply']['text']}');
});
```

---

### Synchronization Events

#### Request Full Sync
Request complete document state (useful after reconnection).

**Emit**:
```dart
socket.emit('request-full-sync', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000'
});
```

**Server responds**:
```dart
socket.on('full-sync', (data) {
  print('Content: ${data['content']}');
  print('History: ${data['history'].length} changes');
  print('Collaborators: ${data['collaborators'].length}');
});
```

---

#### Undo Operation
Undo last change by current user.

**Emit**:
```dart
socket.emit('undo', {
  'documentId': 'doc_1704067200000',
  'userId': 'user_1704067200000',
  'role': 'editor'
});
```

**Server broadcasts**:
```dart
socket.on('undo-applied', (data) {
  print('Undo by ${data['userId']}');
  print('New content: ${data['content']}');
});
```

---

### Notification Events

#### Get Notifications
Retrieve pending notifications.

**Emit**:
```dart
socket.emit('get-notifications', {
  'userId': 'user_1704067200000'
});
```

**Server responds**:
```dart
socket.on('notifications', (notifications) {
  // List of notification objects
});
```

---

#### Clear Notification
Mark a notification as read/clear it.

**Emit**:
```dart
socket.emit('clear-notification', {
  'userId': 'user_1704067200000',
  'notificationId': 'notif_1704067200000'
});
```

---

### Permission Events

#### Permission Denied
Server response when action is not permitted.

**Listen**:
```dart
socket.on('permission-denied', (data) {
  print('Action denied: ${data['action']}');
  print('Your role: ${userRole}');
});
```

---

### Error Handling

#### Socket Error
Handle socket errors.

**Listen**:
```dart
socket.onError((error) {
  print('Socket error: $error');
});
```

**Server sends error**:
```dart
socket.on('error-response', (data) {
  print('Error: ${data['message']}');
});
```

---

#### Disconnection
Handle disconnection events.

**Listen**:
```dart
socket.onDisconnect((_) {
  print('Disconnected from server');
  // Attempt reconnection logic
});
```

---

## 📊 Data Models

### User
```json
{
  "id": "user_1704067200000",
  "username": "alice",
  "email": "alice@example.com",
  "role": "editor",
  "status": "online",
  "createdAt": "2024-01-01T12:00:00Z"
}
```

### Document
```json
{
  "id": "doc_1704067200000",
  "title": "Meeting Notes",
  "content": "# Notes from today...",
  "creatorId": "user_1704067200000",
  "collaborators": [
    {
      "userId": "user_1704067200000",
      "role": "admin"
    }
  ],
  "createdAt": "2024-01-01T12:00:00Z",
  "lastModified": "2024-01-01T13:45:00Z"
}
```

### Notification
```json
{
  "id": "notif_1704067200000",
  "documentId": "doc_1704067200000",
  "message": "Alice made changes",
  "type": "edit",
  "fromUserId": "user_1704067200000",
  "createdAt": "2024-01-01T13:45:00Z",
  "read": false
}
```

---

## 🔐 Permission Matrix

| Action | Admin | Editor | Viewer |
|--------|-------|--------|--------|
| Edit | ✅ | ✅ | ❌ |
| Format | ✅ | ✅ | ❌ |
| Insert Elements | ✅ | ✅ | ❌ |
| Delete | ✅ | ✅ | ❌ |
| Comment | ✅ | ✅ | ✅ |
| Share | ✅ | ❌ | ❌ |
| Change Roles | ✅ | ❌ | ❌ |
| Delete Doc | ✅ | ❌ | ❌ |

---

## 🧪 Example: Complete Workflow

```dart
// 1. Connect to server
socket = IO.io('http://localhost:3001');

// 2. Authenticate
socket.emit('authenticate', {
  'userId': 'user_123',
  'token': 'token_xxx'
});

// 3. Join document
socket.emit('join-room', {
  'documentId': 'doc_456',
  'userId': 'user_123',
  'role': 'editor'
});

// 4. Listen for document state
socket.on('document-sync', (data) {
  print('Collaborators: ${data['collaborators']}');
});

// 5. Listen for other users' edits
socket.on('text-update', (data) {
  print('Update from ${data['userId']}: ${data['content']}');
});

// 6. Send your edit
socket.emit('text-change', {
  'documentId': 'doc_456',
  'userId': 'user_123',
  'change': {
    'type': 'insert',
    'position': 0,
    'text': 'Hello!'
  },
  'role': 'editor'
});

// 7. Add a comment
socket.emit('add-comment', {
  'documentId': 'doc_456',
  'userId': 'user_123',
  'position': 0,
  'text': 'FYI'
});

// 8. Leave when done
socket.emit('leave-room', {
  'documentId': 'doc_456',
  'userId': 'user_123'
});
```

---

**API Version**: 1.0.0  
**Last Updated**: January 2024
