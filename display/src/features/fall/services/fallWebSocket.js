// src/features/fall/services/fallWebSocket.js

const WS_BASE_URL = import.meta.env.VITE_WS_URL || 'ws://localhost:8080';

// WebSocket 상태
const WS_STATUS = {
    CONNECTING: 0,
    OPEN: 1,
    CLOSING: 2,
    CLOSED: 3,
};

// 메시지 타입
export const FALL_MESSAGE_TYPE = {
    FALL_DETECTED: 'FALL_DETECTED',
    FALL_RESOLVED: 'FALL_RESOLVED',
    CONNECTION_STATUS: 'CONNECTION_STATUS',
};

/**
 * 낙상 감지 WebSocket 서비스 (싱글톤)
 */
class FallWebSocketService {
    constructor() {
        this.socket = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.baseReconnectDelay = 3000; // 기본 3초
        this.listeners = new Set();
        this.token = null;
        this.reconnectTimer = null;
    }

    /**
     * WebSocket 연결
     * @param {string} token - 인증 토큰
     */
    connect(token) {
        if (!token) {
            console.error('Token is required for WebSocket connection');
            return;
        }

        if (this.socket?.readyState === WebSocket.OPEN) {
            console.log('✅ WebSocket already connected');
            return;
        }

        this.token = token;
        const wsUrl = `${WS_BASE_URL}/ws/fall-alert?token=${token}`;

        console.log('🔌 Connecting to WebSocket:', wsUrl.replace(token, '***'));

        try {
            this.socket = new WebSocket(wsUrl);
            this.setupEventHandlers();
        } catch (error) {
            console.error('❌ WebSocket connection failed:', error);
            this.handleReconnect();
        }
    }

    /**
     * WebSocket 이벤트 핸들러 설정
     */
    setupEventHandlers() {
        if (!this.socket) return;

        this.socket.onopen = () => {
            console.log('✅ WebSocket connected');
            this.reconnectAttempts = 0;

            // 연결 성공 알림
            this.notifyListeners({
                type: FALL_MESSAGE_TYPE.CONNECTION_STATUS,
                connected: true,
            });
        };

        this.socket.onmessage = (event) => {
            try {
                const message = JSON.parse(event.data);
                console.log('📨 WebSocket message:', message.type);
                this.notifyListeners(message);
            } catch (error) {
                console.error('❌ Failed to parse message:', error);
            }
        };

        this.socket.onclose = (event) => {
            console.log('🔌 WebSocket disconnected:', {
                code: event.code,
                reason: event.reason,
                wasClean: event.wasClean,
            });

            // 연결 종료 알림
            this.notifyListeners({
                type: FALL_MESSAGE_TYPE.CONNECTION_STATUS,
                connected: false,
            });

            // 정상 종료가 아니면 재연결
            if (!event.wasClean && this.reconnectAttempts < this.maxReconnectAttempts) {
                this.handleReconnect();
            }
        };

        this.socket.onerror = (error) => {
            console.error('❌ WebSocket error:', error);
        };
    }

    /**
     * 재연결 처리 (지수 백오프)
     */
    handleReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('❌ Max reconnection attempts reached');
            return;
        }

        // 지수 백오프: 3초 → 6초 → 12초 → 24초 → 48초
        const delay = this.baseReconnectDelay * Math.pow(2, this.reconnectAttempts);
        this.reconnectAttempts++;

        console.log(
            `🔄 Reconnecting in ${delay / 1000}s... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`
        );

        this.reconnectTimer = setTimeout(() => {
            if (this.token) {
                this.connect(this.token);
            }
        }, delay);
    }

    /**
     * WebSocket 연결 종료
     * @param {boolean} preventReconnect - 재연결 방지 여부
     */
    disconnect(preventReconnect = true) {
        console.log('🔌 Disconnecting WebSocket');

        // 재연결 타이머 취소
        if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
        }

        // 재연결 방지
        if (preventReconnect) {
            this.reconnectAttempts = this.maxReconnectAttempts;
        }

        // 소켓 닫기
        if (this.socket) {
            this.socket.close(1000, 'User disconnected');
            this.socket = null;
        }

        this.token = null;
    }

    /**
     * 메시지 리스너 추가
     * @param {Function} callback - 메시지 수신 콜백
     * @returns {Function} 리스너 제거 함수
     */
    addListener(callback) {
        if (typeof callback !== 'function') {
            console.error('Listener must be a function');
            return () => {};
        }

        this.listeners.add(callback);

        // 리스너 제거 함수 반환
        return () => this.listeners.delete(callback);
    }

    /**
     * 모든 리스너에게 메시지 전달
     * @param {Object} message - 메시지 객체
     */
    notifyListeners(message) {
        this.listeners.forEach((callback) => {
            try {
                callback(message);
            } catch (error) {
                console.error('❌ Error in listener:', error);
            }
        });
    }

    /**
     * WebSocket 연결 상태 확인
     * @returns {boolean}
     */
    isConnected() {
        return this.socket?.readyState === WebSocket.OPEN;
    }

    /**
     * 현재 연결 상태 반환
     * @returns {number} WebSocket readyState
     */
    getReadyState() {
        return this.socket?.readyState ?? WS_STATUS.CLOSED;
    }

    /**
     * 재연결 초기화 (수동 재연결 시 사용)
     */
    resetReconnection() {
        this.reconnectAttempts = 0;
        if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
        }
    }
}

// 싱글톤 인스턴스
const fallWebSocketService = new FallWebSocketService();

export default fallWebSocketService;
export { WS_STATUS };
