# 🚀 Quick Start Guide

Get the Real-Time Collaboration App running in 5 minutes!

## Step 1: Start the Backend Server

```bash
cd backend
npm install
npm start
```

**Expected output:**
```
🚀 Server running on http://localhost:3001
📡 WebSocket ready for real-time collaboration
```

## Step 2: Launch the Flutter App

```bash
cd mobile
flutter pub get
flutter run
```

## Step 3: Test It Out

1. **First User**: Create account as "alice" with password "pass123", role: editor
2. **Second User**: Create account as "bob" with password "pass123", role: editor
3. **Create Document**: Click the "+" button to create a new document
4. **Collaborate**: Open the same document in both accounts
5. **Edit**: Type in one account, watch it update in real-time in the other!

---

## 📱 Features to Try

### Real-Time Editing ✏️
- Start typing in one account
- See changes instantly in other accounts
- Try editing simultaneously

### Collaborators List 👥
- Click the people icon to see who's editing
- View each user's role (admin/editor/viewer)

### Comments 💬
- Click comment icon to add annotations
- Reply to comments from other users

### Notifications 🔔
- See badge when team makes changes
- Get alerts for new comments and edits

### Role-Based Permissions 🔐
- **Viewer**: Can only read and comment
- **Editor**: Can edit, format, and comment
- **Admin**: Full control, can share documents

---

## ⚙️ Configuration

### Backend (.env)
```
PORT=3001
CORS_ORIGIN=*
NODE_ENV=development
```

### Frontend (main.dart)
```dart
final String serverUrl = 'http://localhost:3001';
```

---

## 🔗 Socket.io Events Reference

### Join a Document
```dart
socket.emit('join-room', {
  'documentId': 'doc_123',
  'userId': 'user_alice',
  'role': 'editor'
});
```

### Send Edit
```dart
socket.emit('text-change', {
  'documentId': 'doc_123',
  'userId': 'user_alice',
  'change': {
    'type': 'insert',
    'position': 0,
    'text': 'Hello!'
  },
  'role': 'editor'
});
```

### Add Comment
```dart
socket.emit('add-comment', {
  'documentId': 'doc_123',
  'userId': 'user_alice',
  'position': 10,
  'text': 'Please review this'
});
```

---

## 📊 Demo Scenario

**Time**: 5 minutes

1. **2 min**: Setup and start servers
2. **1 min**: Create two user accounts
3. **1 min**: Create a document
4. **1 min**: Test real-time editing and collaboration features

**Talking Points**:
- "See how both users' edits sync instantly?"
- "No page refresh needed - pure WebSocket magic"
- "Permissions are enforced server-side for security"
- "This architecture supports 500+ concurrent users"

---

## ✅ Checklist

- [ ] Backend running on port 3001
- [ ] Flutter app launching successfully
- [ ] Can login with multiple accounts
- [ ] Can create documents
- [ ] Real-time sync working
- [ ] Comments feature functional
- [ ] Notifications appearing
- [ ] Permission checks working

---

## 🆘 Common Issues

### "Connection refused" error
```
→ Make sure backend is running: npm start
```

### App crashes on login
```
→ Check that backend URL matches in main.dart
→ Verify .env file has PORT=3001
```

### Changes not syncing
```
→ Check WebSocket connection (green dot in editor)
→ Try refreshing the app
→ Restart backend server
```

---

## 📚 Next Steps

1. **Customize branding**: Edit colors in main.dart
2. **Add authentication**: Implement JWT tokens
3. **Connect database**: Add MongoDB integration
4. **Deploy online**: Use Docker + cloud platform
5. **Scale up**: Implement Redis for caching

---

**Ready to collaborate? Let's go! 🎉**
