const WS_BASE_URL = import.meta.env.VITE_WS_URL || 'ws://localhost:8080';

class FallWebSocketService {
    constructor() {
        this.socket = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.reconnectDelay = 3000;
        this.listeners = new Set();
    }

    connect(token) {
        if (this.socket?.readyState === WebSocket.OPEN) {
            console.log('WebSocket already connected');
            return;
        }

        const wsUrl = `${WS_BASE_URL}/ws/fall-alert?token=${token}`;
        console.log('Connecting to WebSocket:', wsUrl.replace(token, '***'));

        this.socket = new WebSocket(wsUrl);

        this.socket.onopen = () => {
            console.log('WebSocket connected');
            this.reconnectAttempts = 0;
        };

        this.socket.onmessage = (event) => {
            try {
                const message = JSON.parse(event.data);
                console.log('WebSocket message received:', message.type);
                this.notifyListeners(message);
            } catch (error) {
                console.error('Failed to parse WebSocket message:', error);
            }
        };

        this.socket.onclose = (event) => {
            console.log('WebSocket disconnected:', event.code, event.reason);
            this.handleReconnect(token);
        };

        this.socket.onerror = (error) => {
            console.error('WebSocket error:', error);
        };
    }

    handleReconnect(token) {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`Reconnecting... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
            setTimeout(() => this.connect(token), this.reconnectDelay);
        } else {
            console.error('Max reconnection attempts reached');
        }
    }

    disconnect() {
        if (this.socket) {
            this.socket.close();
            this.socket = null;
        }
        this.reconnectAttempts = this.maxReconnectAttempts; // 재연결 방지
    }

    addListener(callback) {
        this.listeners.add(callback);
        return () => this.listeners.delete(callback);
    }

    notifyListeners(message) {
        this.listeners.forEach((callback) => {
            try {
                callback(message);
            } catch (error) {
                console.error('Error in WebSocket listener:', error);
            }
        });
    }

    isConnected() {
        return this.socket?.readyState === WebSocket.OPEN;
    }
}

const fallWebSocketService = new FallWebSocketService();
export default fallWebSocketService;
