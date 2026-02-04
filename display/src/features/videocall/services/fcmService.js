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
        const permission = Notification.permission;
        console.log('현재 알림 권한 상태:', permission);

        // 이미 차단된 경우
        if (permission === 'denied') {
            const message = `
알림이 차단되어 있습니다. 다음 방법으로 허용해주세요:

1. 주소창 왼쪽의 자물쇠 아이콘 클릭
2. "알림" 항목 찾기
3. "허용"으로 변경
4. 페이지 새로고침
            `;
            alert(message);

            // 설정 페이지로 이동하는 UI 표시
            return null;
        }

        // 권한 요청 (사용자 제스처 필요)
        if (permission === 'default') {
            const newPermission = await Notification.requestPermission();

            if (newPermission !== 'granted') {
                alert('알림 권한이 필요합니다. 브라우저 설정에서 허용해주세요.');
                return null;
            }
        }

        // 권한 허용된 경우 토큰 발급
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


export const registerFcmToken = async (fcmToken) => {
    try {
        console.log('📤 FCM 토큰 등록 요청');

        const response = await client.post('/api/notifications/token', {
            token: fcmToken
            // petId 제거 - 서버에서 User로부터 가져옴
        });

        console.log('✅ FCM 토큰 서버 등록 완료');
        return response.data;

    } catch (error) {
        console.error('❌ FCM 토큰 서버 등록 실패:', error.response?.data || error.message);
        // 에러를 던지지 않고 로그만 남김 (앱 계속 작동)
        return null;
    }
};


export const onForegroundMessage = async (callback) => {
    await initFirebase();
    return onMessage(messaging, (payload) => {
        console.log('FCM foreground message:', payload);
        callback(payload);
    });
};
