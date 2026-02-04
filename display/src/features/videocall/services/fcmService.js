import { initializeApp, getApps } from 'firebase/app';
import { getMessaging, getToken, onMessage } from 'firebase/messaging';
import client from '../../../api/client';

const firebaseConfig = {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
    messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
    appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

let app = null;
let messaging = null;

const initFirebase = async () => {
    if (app) return;
    if (getApps().length > 0) {
        app = getApps()[0];
    } else {
        app = initializeApp(firebaseConfig);
    }
    messaging = getMessaging(app);

    // Service Worker 등록 후 Firebase config을 postMessage로 전달
    if ('serviceWorker' in navigator) {
        const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');
        await navigator.serviceWorker.ready;
        registration.active.postMessage({
            type: 'FIREBASE_CONFIG',
            config: firebaseConfig,
        });
    }
};

export const requestFcmToken = async () => {
    try {
        // 1. 알림 권한 확인
        const permission = await Notification.requestPermission();

        if (permission !== 'granted') {
            console.warn('⚠️ 알림 권한이 거부되었습니다');
            return null;
        }

        console.log('✅ 알림 권한 허용됨');

        // 2. Firebase 초기화
        await initFirebase();

        // 3. FCM 토큰 발급
        const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY;
        const token = await getToken(messaging, { vapidKey });

        console.log('✅ FCM token:', token);
        return token;

    } catch (error) {
        console.error('❌ FCM 토큰 발급 실패:', error);

        // 권한이 막혀있는 경우 사용자에게 안내
        if (error.code === 'messaging/permission-blocked') {
            alert('알림이 차단되었습니다. 브라우저 설정에서 알림을 허용해주세요.');
        }

        return null;
    }
};

export const registerFcmToken = async (fcmToken, petId) => {
    try {
        await client.post('/api/notifications/token', { token: fcmToken, petId });
        console.log('FCM 토큰 서버 등록 완료');
    } catch (error) {
        console.error('FCM 토큰 서버 등록 실패:', error);
    }
};

export const onForegroundMessage = async (callback) => {
    await initFirebase();
    return onMessage(messaging, (payload) => {
        console.log('FCM foreground message:', payload);
        callback(payload);
    });
};
