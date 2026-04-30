
module.exports = (io, rooms, users, connections, notifications) => {
  io.on('connection', (socket) => {
    console.log(`✅ User connected: ${socket.id}`);
    
    // Track active connections
    connections.set(socket.id, {
      id: socket.id,
      userId: null,
      currentRoom: null,
      connectedAt: new Date()
    });

    // === AUTHENTICATION ===
    socket.on('authenticate', (data) => {
      const { userId, token } = data;
      const connection = connections.get(socket.id);
      
      if (connection) {
        connection.userId = userId;
        console.log(`🔐 User ${userId} authenticated`);
        socket.emit('auth-success', { userId });
      }
    });

    // === ROOM MANAGEMENT ===
    socket.on('join-room', (data) => {
      const { documentId, userId, role } = data;
      const connection = connections.get(socket.id);
      
      socket.join(documentId);
      
      if (connection) {
        connection.currentRoom = documentId;
      }

      // Update room collaborators
      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        const existingCollaborator = room.collaborators.find(c => c.userId === userId);
        
        if (!existingCollaborator) {
          room.collaborators.push({ userId, role, joinedAt: new Date() });
        }
        
        // Broadcast user joined
        io.to(documentId).emit('user-joined', {
          userId,
          role,
          collaborators: room.collaborators,
          totalUsers: room.collaborators.length
        });

        // Send current document content to joining user
        socket.emit('document-sync', {
          documentId,
          content: room.content,
          history: room.history.slice(-50), // Last 50 changes
          collaborators: room.collaborators
        });
      }
    });

    socket.on('leave-room', (data) => {
      const { documentId, userId } = data;
      socket.leave(documentId);
      
      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        room.collaborators = room.collaborators.filter(c => c.userId !== userId);
        
        io.to(documentId).emit('user-left', {
          userId,
          collaborators: room.collaborators,
          totalUsers: room.collaborators.length
        });
      }

      const connection = connections.get(socket.id);
      if (connection) {
        connection.currentRoom = null;
      }
    });

    // === REAL-TIME EDITING ===
    socket.on('text-change', (data) => {
      const { documentId, userId, change, cursorPosition, role } = data;
      
      // Permission check
      if (!hasPermission(role, 'edit')) {
        socket.emit('permission-denied', { action: 'edit' });
        return;
      }

      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        
        // Apply change
        room.content = applyChange(room.content, change);
        room.lastModified = new Date();
        
        // Record in history for CRDT/OT
        room.history.push({
          userId,
          change,
          timestamp: new Date(),
          cursorPosition,
          type: 'text-change'
        });

        // Broadcast to all users in room (including sender for confirmation)
        io.to(documentId).emit('text-update', {
          userId,
          change,
          cursorPosition,
          content: room.content,
          lastModified: room.lastModified
        });

        // Create notification for other users
        createNotification(
          documentId,
          `${userId} made changes`,
          'edit',
          userId
        );
      }
    });

    socket.on('cursor-move', (data) => {
      const { documentId, userId, position, line } = data;
      
      if (rooms.has(documentId)) {
        // Broadcast cursor position to all users in room
        io.to(documentId).emit('cursor-update', {
          userId,
          position,
          line,
          timestamp: new Date()
        });
      }
    });

    // === FORMATTING & OPERATIONS ===
    socket.on('format-text', (data) => {
      const { documentId, userId, role, format, startPos, endPos } = data;
      
      if (!hasPermission(role, 'edit')) {
        socket.emit('permission-denied', { action: 'format' });
        return;
      }

      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        
        // Record formatting action
        room.history.push({
          userId,
          action: 'format',
          format,
          startPos,
          endPos,
          timestamp: new Date(),
          type: 'formatting'
        });

        io.to(documentId).emit('format-update', {
          userId,
          format,
          startPos,
          endPos,
          timestamp: new Date()
        });
      }
    });

    socket.on('insert-element', (data) => {
      const { documentId, userId, role, elementType, position, content } = data;
      
      if (!hasPermission(role, 'edit')) {
        socket.emit('permission-denied', { action: 'insert' });
        return;
      }

      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        
        room.history.push({
          userId,
          action: 'insert-element',
          elementType,
          position,
          content,
          timestamp: new Date(),
          type: 'insertion'
        });

        io.to(documentId).emit('element-inserted', {
          userId,
          elementType,
          position,
          content,
          timestamp: new Date()
        });
      }
    });

    // === COMMENTS & COLLABORATION ===
    socket.on('add-comment', (data) => {
      const { documentId, userId, position, text } = data;
      
      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        const comment = {
          id: `comment_${Date.now()}`,
          userId,
          position,
          text,
          createdAt: new Date(),
          replies: []
        };

        if (!room.comments) room.comments = [];
        room.comments.push(comment);

        io.to(documentId).emit('comment-added', comment);

        // Notify others
        room.collaborators.forEach(collab => {
          if (collab.userId !== userId) {
            createNotification(
              documentId,
              `${userId} added a comment`,
              'comment',
              userId,
              collab.userId
            );
          }
        });
      }
    });

    socket.on('reply-comment', (data) => {
      const { documentId, commentId, userId, text } = data;
      
      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        if (room.comments) {
          const comment = room.comments.find(c => c.id === commentId);
          if (comment) {
            const reply = {
              id: `reply_${Date.now()}`,
              userId,
              text,
              createdAt: new Date()
            };
            comment.replies.push(reply);

            io.to(documentId).emit('comment-reply', {
              commentId,
              reply
            });
          }
        }
      }
    });

    // === NOTIFICATIONS ===
    socket.on('get-notifications', (data) => {
      const { userId } = data;
      const userNotifications = notifications.get(userId) || [];
      socket.emit('notifications', userNotifications);
    });

    socket.on('clear-notification', (data) => {
      const { userId, notificationId } = data;
      const userNotifications = notifications.get(userId) || [];
      const filtered = userNotifications.filter(n => n.id !== notificationId);
      notifications.set(userId, filtered);
    });

    // === SYNC & OPTIMIZATION ===
    socket.on('request-full-sync', (data) => {
      const { documentId, userId } = data;
      
      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        socket.emit('full-sync', {
          documentId,
          content: room.content,
          history: room.history,
          collaborators: room.collaborators,
          comments: room.comments || [],
          lastModified: room.lastModified
        });
      }
    });

    socket.on('undo', (data) => {
      const { documentId, userId, role } = data;
      
      if (!hasPermission(role, 'edit')) {
        socket.emit('permission-denied', { action: 'undo' });
        return;
      }

      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        if (room.history.length > 0) {
          // Simple undo - just remove last change from this user
          const lastIndex = room.history.length - 1;
          const lastChange = room.history[lastIndex];
          
          if (lastChange.userId === userId) {
            room.history.pop();
            room.content = reconstructContent(room.history);
            
            io.to(documentId).emit('undo-applied', {
              userId,
              content: room.content,
              history: room.history
            });
          }
        }
      }
    });

    // === SHARING & PERMISSIONS ===
    socket.on('share-document', (data) => {
      const { documentId, userId, role, targetUserId, targetRole } = data;
      
      if (!hasPermission(role, 'share')) {
        socket.emit('permission-denied', { action: 'share' });
        return;
      }

      if (rooms.has(documentId)) {
        const room = rooms.get(documentId);
        createNotification(
          documentId,
          `${userId} shared document "${room.title}" with you (${targetRole})`,
          'share',
          userId,
          targetUserId
        );
      }
    });

    // === DISCONNECT ===
    socket.on('disconnect', () => {
      const connection = connections.get(socket.id);
      
      if (connection) {
        const { documentId, userId } = connection;
        
        if (documentId && rooms.has(documentId)) {
          const room = rooms.get(documentId);
          room.collaborators = room.collaborators.filter(c => c.userId !== userId);
          
          io.to(documentId).emit('user-disconnected', {
            userId,
            collaborators: room.collaborators,
            totalUsers: room.collaborators.length
          });
        }
        
        connections.delete(socket.id);
        console.log(`❌ User disconnected: ${socket.id}`);
      }
    });

    // === ERROR HANDLING ===
    socket.on('error', (error) => {
      console.error(`Socket error for ${socket.id}:`, error);
      socket.emit('error-response', { message: 'An error occurred' });
    });
  });
};

// UTILITY FUNCTIONS

function hasPermission(role, action) {
  const permissions = {
    admin: ['edit', 'format', 'insert', 'delete', 'share', 'comment', 'undo'],
    editor: ['edit', 'format', 'insert', 'delete', 'comment', 'undo'],
    viewer: ['comment']
  };

  return permissions[role]?.includes(action) || false;
}

function applyChange(content, change) {
  const { type, position, text } = change;
  
  if (type === 'insert') {
    return content.slice(0, position) + text + content.slice(position);
  } else if (type === 'delete') {
    const { length } = change;
    return content.slice(0, position) + content.slice(position + length);
  } else if (type === 'replace') {
    const { length } = change;
    return content.slice(0, position) + text + content.slice(position + length);
  }
  
  return content;
}

function reconstructContent(history) {
  let content = '';
  
  for (const entry of history) {
    if (entry.type === 'text-change') {
      content = applyChange(content, entry.change);
    }
  }
  
  return content;
}

function createNotification(documentId, message, type, fromUserId, toUserId = null) {
  const notification = {
    id: `notif_${Date.now()}`,
    documentId,
    message,
    type, // 'edit', 'comment', 'share', 'mention'
    fromUserId,
    createdAt: new Date(),
    read: false
  };

  if (toUserId) {
    const userNotifications = notifications.get(toUserId) || [];
    userNotifications.push(notification);
    notifications.set(toUserId, userNotifications.slice(-100)); // Keep last 100
  }

  return notification;
}
