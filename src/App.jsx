import { useEffect, useRef, useState } from 'react';
import { io } from 'socket.io-client';

export default function App() {
  const [text, setText] = useState('');
  const [connected, setConnected] = useState(false);
  const [peers, setPeers] = useState(0);
  const fromRemote = useRef(false);
  const socketRef = useRef(null);

  useEffect(() => {
    const socket = io({
      path: '/socket.io',
      transports: ['websocket', 'polling'],
    });
    socketRef.current = socket;
    socket.on('connect', () => setConnected(true));
    socket.on('disconnect', () => setConnected(false));
    socket.on('doc:sync', (t) => {
      fromRemote.current = true;
      setText(t);
    });
    socket.on('presence', (n) => setPeers(n));
    socket.emit('join-doc');
    return () => socket.close();
  }, []);

  function onChange(e) {
    const v = e.target.value;
    setText(v);
    if (fromRemote.current) {
      fromRemote.current = false;
      return;
    }
    socketRef.current?.emit('doc:update', v);
  }

  return (
    <div style={{ maxWidth: 800, margin: '0 auto', padding: 24 }}>
      <img src="/assets/images/project-2.png" alt="" style={heroImg} />
      <h1 style={{ fontSize: 22 }}>Real-time document (Notion-style demo)</h1>
      <p style={{ color: '#9ca3af', marginBottom: 8 }}>
        Open this page in two browser windows — edits sync live via Socket.io.
      </p>
      <p style={{ fontSize: 14, marginBottom: 16 }}>
        <span style={{ color: connected ? '#86efac' : '#f87171' }}>
          {connected ? '● Connected' : '○ Disconnected'}
        </span>
        <span style={{ marginLeft: 16, color: '#9ca3af' }}>Active in room: {peers}</span>
      </p>
      <textarea
        value={text}
        onChange={onChange}
        placeholder="Start typing…"
        style={{
          width: '100%',
          minHeight: 360,
          padding: 16,
          borderRadius: 12,
          border: '1px solid #374151',
          background: '#111827',
          color: '#f3f4f6',
          fontSize: 15,
          lineHeight: 1.6,
          resize: 'vertical',
        }}
      />
    </div>
  );
}

const heroImg = {
  width: '100%',
  maxHeight: 200,
  objectFit: 'cover',
  borderRadius: 12,
  marginBottom: 16,
  border: '1px solid #374151',
};
