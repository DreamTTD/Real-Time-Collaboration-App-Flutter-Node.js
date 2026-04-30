
const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const cors = require('cors');
require('dotenv').config();
const socketHandler = require('./utils/socketHandler');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: { origin: '*' },
  transports: ['websocket', 'polling']
});

// Middleware
app.use(cors());
app.use(express.json());

// Store for rooms and users (in production, use Redis)
const rooms = new Map();
const users = new Map();
const connections = new Map();

// In-memory notification store
const notifications = new Map();

// Initialize socket handler
socketHandler(io, rooms, users, connections, notifications);

// REST API Endpoints
app.post('/api/auth/signup', (req, res) => {
  const { username, email, password, role = 'editor' } = req.body;
  const userId = `user_${Date.now()}`;
  users.set(userId, {
    id: userId,
    username,
    email,
    password,
    role, // admin, editor, viewer
    createdAt: new Date(),
    status: 'online'
  });
  res.json({ userId, username, role, token: `token_${userId}` });
});

app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body;
  let user = Array.from(users.values()).find(u => u.username === username);
  if (user) {
    res.json({ userId: user.id, username: user.username, role: user.role, token: `token_${user.id}` });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

app.post('/api/documents/create', (req, res) => {
  const { title, creatorId } = req.body;
  const docId = `doc_${Date.now()}`;
  
  if (!rooms.has(docId)) {
    rooms.set(docId, {
      id: docId,
      title,
      content: '',
      creatorId,
      collaborators: [{ userId: creatorId, role: 'admin' }],
      createdAt: new Date(),
      lastModified: new Date(),
      history: []
    });
  }
  
  res.json({ documentId: docId, title });
});

app.get('/api/documents/:docId', (req, res) => {
  const { docId } = req.params;
  const room = rooms.get(docId);
  
  if (room) {
    res.json({
      id: room.id,
      title: room.title,
      content: room.content,
      collaborators: room.collaborators,
      lastModified: room.lastModified
    });
  } else {
    res.status(404).json({ error: 'Document not found' });
  }
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date(),
    activeConnections: connections.size,
    activeRooms: rooms.size
  });
});

// Start server
const PORT = process.env.PORT || 3001;
server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📡 WebSocket ready for real-time collaboration`);
});
