// src/features/videocall/services/fcmService.js

import { initializeApp, getApps } from 'firebase/app';
import { getMessaging, getToken, onMessage, deleteToken } from 'firebase/messaging';
import client from '../../../api/client';

// ==================== 상수 ====================

const NOTIFICATION_PERMISSION = {
    GRANTED: 'granted',
    DENIED: 'denied',
    DEFAULT: 'default',
};

const ERROR_MESSAGES = {
    PERMISSION_DENIED: '알림이 차단되어 있습니다.',
    PERMISSION_REQUIRED: '알림 권한이 필요합니다.',
    TOKEN_FAILED: 'FCM 토큰 발급에 실패했습니다.',
    REGISTRATION_FAILED: 'FCM 토큰 등록에 실패했습니다.',
    SERVICE_WORKER_FAILED: 'Service Worker 등록에 실패했습니다.',
    BROWSER_NOT_SUPPORTED: '이 브라우저는 알림을 지원하지 않습니다.',
    CONFIG_MISSING: 'Firebase 설정이 누락되었습니다.',
};

const PERMISSION_GUIDE = `
알림이 차단되어 있습니다. 다음 방법으로 허용해주세요:

1. 주소창 왼쪽의 자물쇠/정보 아이콘 클릭
2. "알림" 항목 찾기
3. "허용"으로 변경
4. 페이지 새로고침
`;

const TOKEN_STORAGE_KEY = 'fcm_token';
const TOKEN_TIMESTAMP_KEY = 'fcm_token_timestamp';
const TOKEN_REFRESH_INTERVAL = 7 * 24 * 60 * 60 * 1000; // 7일

// ==================== Firebase 설정 ====================

const requiredConfigKeys = [
    'VITE_FIREBASE_API_KEY',
    'VITE_FIREBASE_AUTH_DOMAIN',
    'VITE_FIREBASE_PROJECT_ID',
    'VITE_FIREBASE_MESSAGING_SENDER_ID',
    'VITE_FIREBASE_APP_ID',
    'VITE_FIREBASE_VAPID_KEY',
];

/**
 * Firebase 설정 검증
 * @throws {Error} 필수 설정 누락 시
 */
const validateFirebaseConfig = () => {
    const missing = requiredConfigKeys.filter((key) => !import.meta.env[key]);

    if (missing.length > 0) {
        throw new Error(
            `Firebase 설정이 누락되었습니다: ${missing.map((k) => k.replace('VITE_', '')).join(', ')}`
        );
    }
};

const getFirebaseConfig = () => {
    validateFirebaseConfig();

    return {
        apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
        authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
        projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
        messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
        appId: import.meta.env.VITE_FIREBASE_APP_ID,
    };
};

let app = null;
let messaging = null;
let serviceWorkerRegistration = null;

// ==================== Firebase 초기화 ====================

/**
 * Firebase 앱 초기화
 * @returns {Promise<void>}
 */
const initFirebase = async () => {
    if (app) return;

    try {
        const firebaseConfig = getFirebaseConfig();

        // 기존 앱 확인
        if (getApps().length > 0) {
            app = getApps()[0];
        } else {
            app = initializeApp(firebaseConfig);
        }

        messaging = getMessaging(app);
        console.log('✅ Firebase 초기화 완료');
    } catch (error) {
        console.error('❌ Firebase 초기화 실패:', error);
        throw error;
    }
};

/**
 * Service Worker 등록
 * @returns {Promise<ServiceWorkerRegistration>}
 */
const registerServiceWorker = async () => {
    if (serviceWorkerRegistration) {
        return serviceWorkerRegistration;
    }

    if (!('serviceWorker' in navigator)) {
        throw new Error('Service Worker를 지원하지 않는 브라우저입니다.');
    }

    try {
        // Service Worker 경로 (환경변수로 설정 가능)
        const swPath = import.meta.env.VITE_SW_PATH || '/firebase-messaging-sw.js';

        // Service Worker 등록
        const registration = await navigator.serviceWorker.register(swPath, {
            scope: '/',
        });

        console.log('✅ Service Worker 등록 완료');

        // Service Worker 활성화 대기
        await navigator.serviceWorker.ready;

        // Firebase 설정 전달
        if (registration.active) {
            registration.active.postMessage({
                type: 'FIREBASE_CONFIG',
                config: getFirebaseConfig(),
            });
        }

        serviceWorkerRegistration = registration;
        return registration;
    } catch (error) {
        console.error('❌ Service Worker 등록 실패:', error);
        throw new Error(ERROR_MESSAGES.SERVICE_WORKER_FAILED);
    }
};

// ==================== 권한 관리 ====================

/**
 * 알림 권한 확인
 * @returns {NotificationPermission}
 */
export const getNotificationPermission = () => {
    if (!('Notification' in window)) {
        throw new Error(ERROR_MESSAGES.BROWSER_NOT_SUPPORTED);
    }
    return Notification.permission;
};

/**
 * 알림 권한 요청
 * @returns {Promise<{granted: boolean, permission: NotificationPermission, message?: string}>}
 */
export const requestNotificationPermission = async () => {
    const currentPermission = getNotificationPermission();

    // 이미 차단됨
    if (currentPermission === NOTIFICATION_PERMISSION.DENIED) {
        console.warn('⚠️ 알림 권한이 차단되어 있습니다.');
        return {
            granted: false,
            permission: currentPermission,
            message: PERMISSION_GUIDE,
        };
    }

    // 이미 허용됨
    if (currentPermission === NOTIFICATION_PERMISSION.GRANTED) {
        return {
            granted: true,
            permission: currentPermission,
        };
    }

    // 권한 요청
    try {
        const permission = await Notification.requestPermission();
        const granted = permission === NOTIFICATION_PERMISSION.GRANTED;

        if (!granted) {
            console.warn('⚠️ 사용자가 알림 권한을 거부했습니다.');
        }

        return {
            granted,
            permission,
            message: granted ? null : ERROR_MESSAGES.PERMISSION_REQUIRED,
        };
    } catch (error) {
        console.error('❌ 알림 권한 요청 실패:', error);
        return {
            granted: false,
            permission: NOTIFICATION_PERMISSION.DENIED,
            message: error.message,
        };
    }
};

// ==================== 토큰 캐싱 ====================

/**
 * 캐시된 FCM 토큰 가져오기
 * @returns {{token: string|null, timestamp: number|null}}
 */
const getCachedToken = () => {
    try {
        const token = localStorage.getItem(TOKEN_STORAGE_KEY);
        const timestamp = localStorage.getItem(TOKEN_TIMESTAMP_KEY);

        return {
            token,
            timestamp: timestamp ? parseInt(timestamp, 10) : null,
        };
    } catch {
        return { token: null, timestamp: null };
    }
};

/**
 * FCM 토큰 캐시 저장
 * @param {string} token
 */
const setCachedToken = (token) => {
    try {
        localStorage.setItem(TOKEN_STORAGE_KEY, token);
        localStorage.setItem(TOKEN_TIMESTAMP_KEY, Date.now().toString());
    } catch (error) {
        console.warn('⚠️ 토큰 캐시 저장 실패:', error);
    }
};

/**
 * 토큰 갱신 필요 여부 확인
 * @returns {boolean}
 */
const shouldRefreshToken = () => {
    const { token, timestamp } = getCachedToken();

    if (!token || !timestamp) return true;

    const age = Date.now() - timestamp;
    return age > TOKEN_REFRESH_INTERVAL;
};

// ==================== FCM 토큰 ====================

/**
 * FCM 토큰 요청
 * @param {boolean} forceRefresh - 강제 갱신 여부
 * @returns {Promise<string|null>} FCM 토큰
 */
export const requestFcmToken = async (forceRefresh = false) => {
    try {
        // 1. 캐시 확인
        if (!forceRefresh && !shouldRefreshToken()) {
            const { token } = getCachedToken();
            if (token) {
                console.log('✅ 캐시된 FCM 토큰 사용');
                return token;
            }
        }

        // 2. 알림 권한 확인/요청
        const { granted, message } = await requestNotificationPermission();

        if (!granted) {
            console.warn('⚠️ 알림 권한 없음:', message);
            return null;
        }

        // 3. Firebase 초기화
        await initFirebase();

        // 4. Service Worker 등록
        await registerServiceWorker();

        // 5. FCM 토큰 발급
        const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY;

        const token = await getToken(messaging, { vapidKey });

        if (!token) {
            throw new Error('FCM 토큰을 받을 수 없습니다.');
        }

        // 6. 토큰 캐시 저장
        setCachedToken(token);

        console.log('✅ FCM 토큰 발급 완료');
        return token;
    } catch (error) {
        console.error('❌ FCM 토큰 요청 실패:', error);
        return null;
    }
};

/**
 * FCM 토큰 갱신
 * @returns {Promise<string|null>}
 */
export const refreshFcmToken = async () => {
    console.log('🔄 FCM 토큰 갱신 시작');

    try {
        // 기존 토큰 삭제
        if (messaging) {
            await deleteToken(messaging);
        }

        // 캐시 삭제
        localStorage.removeItem(TOKEN_STORAGE_KEY);
        localStorage.removeItem(TOKEN_TIMESTAMP_KEY);

        // 새 토큰 발급
        return await requestFcmToken(true);
    } catch (error) {
        console.error('❌ FCM 토큰 갱신 실패:', error);
        return null;
    }
};

/**
 * FCM 토큰 서버 등록
 * @param {string} fcmToken - FCM 토큰
 * @param {number} retryCount - 재시도 횟수
 * @returns {Promise<Object|null>}
 */
export const registerFcmToken = async (fcmToken, retryCount = 0) => {
    if (!fcmToken) {
        console.warn('⚠️ FCM 토큰이 없습니다.');
        return null;
    }

    try {
        console.log('📤 FCM 토큰 서버 등록 요청');

        const response = await client.post('/api/pets/fcm-token', {
            fcmToken: fcmToken,
        });

        console.log('✅ FCM 토큰 서버 등록 완료');
        return response.data;
    } catch (error) {
        console.error('❌ FCM 토큰 서버 등록 실패:', error.response?.data || error.message);

        // 401 에러 시 토큰 갱신 시도
        if (error.response?.status === 401 && retryCount === 0) {
            console.log('🔄 토큰 갱신 후 재시도...');
            const newToken = await refreshFcmToken();
            if (newToken) {
                return registerFcmToken(newToken, retryCount + 1);
            }
        }

        // 앱 계속 작동하도록 에러를 던지지 않음
        return null;
    }
};

// ==================== 메시지 수신 ====================

/**
 * Foreground 메시지 리스너 등록
 * @param {Function} callback - 메시지 수신 콜백
 * @returns {Promise<Function>} 리스너 해제 함수
 */
export const onForegroundMessage = async (callback) => {
    if (typeof callback !== 'function') {
        throw new Error('Callback must be a function');
    }

    await initFirebase();

    const unsubscribe = onMessage(messaging, (payload) => {
        console.log('📨 FCM foreground message:', payload);
        try {
            callback(payload);
        } catch (error) {
            console.error('❌ Message callback error:', error);
        }
    });

    return unsubscribe;
};

// ==================== Export ====================

export const fcmService = {
    initFirebase,
    registerServiceWorker,
    getNotificationPermission,
    requestNotificationPermission,
    requestFcmToken,
    refreshFcmToken,
    registerFcmToken,
    onForegroundMessage,
};

export { NOTIFICATION_PERMISSION, ERROR_MESSAGES };
