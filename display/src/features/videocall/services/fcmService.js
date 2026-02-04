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

    // Service Worker 등록
    if ('serviceWorker' in navigator) {
        try {
            const registration = await navigator.serviceWorker.register(
                '/firebase-messaging-sw.js',
                { scope: '/' }
            );

            console.log('✅ Service Worker 등록 완료');

            // 등록 완료 후 설정 전달
            await navigator.serviceWorker.ready;

            if (registration.active) {
                registration.active.postMessage({
                    type: 'FIREBASE_CONFIG',
                    config: firebaseConfig,
                });
            }
        } catch (error) {
            console.error('❌ Service Worker 등록 실패:', error);
        }
    }
};


export const requestFcmToken = async () => {
    try {
        // 현재 권한 상태 확인
        let permission = Notification.permission;
        console.log('현재 알림 권한:', permission);

        // 권한이 없으면 요청
        if (permission === 'default') {
            permission = await Notification.requestPermission();
        }

        if (permission !== 'granted') {
            console.warn('⚠️ 알림 권한이 거부되었습니다');
            alert('화상통화 알림을 받으려면 알림 권한이 필요합니다.\n브라우저 설정에서 알림을 허용해주세요.');
            return null;
        }

        await initFirebase();
        const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY;
        const token = await getToken(messaging, { vapidKey });

        console.log('✅ FCM token 발급 완료');
        return token;

    } catch (error) {
        console.error('❌ FCM 토큰 발급 실패:', error);
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
