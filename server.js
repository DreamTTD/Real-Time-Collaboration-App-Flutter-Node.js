import { createServer } from 'http';
import express from 'express';
import { Server } from 'socket.io';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*' },
  path: '/socket.io',
});

let docText = '';

io.on('connection', (socket) => {
  socket.on('join-doc', () => {
    socket.join('doc-main');
    socket.emit('doc:sync', docText);
    io.to('doc-main').emit('presence', io.sockets.adapter.rooms.get('doc-main')?.size || 0);
  });

  socket.on('doc:update', (text) => {
    docText = typeof text === 'string' ? text : '';
    socket.to('doc-main').emit('doc:sync', docText);
    io.to('doc-main').emit('presence', io.sockets.adapter.rooms.get('doc-main')?.size || 0);
  });

  socket.on('disconnecting', () => {
    socket.once('disconnect', () => {
      io.to('doc-main').emit('presence', io.sockets.adapter.rooms.get('doc-main')?.size || 0);
    });
  });
});

const PORT = 3001;
httpServer.listen(PORT, () => {
  console.log(`[02-realtime-collaboration] http://localhost:${PORT} (Socket.io)`);
});
