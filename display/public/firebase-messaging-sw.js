/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Firebase 설정 (하드코딩 또는 postMessage로 받기)
let firebaseConfig = null;

// postMessage로 설정 받기
self.addEventListener('message', (event) => {
    if (event.data && event.data.type === 'FIREBASE_CONFIG') {
        firebaseConfig = event.data.config;
        initializeFirebase();
    }
});

function initializeFirebase() {
    if (!firebaseConfig) return;

    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    // 백그라운드 메시지 핸들러 (초기 평가 시점에 등록)
    messaging.onBackgroundMessage((payload) => {
        console.log('[SW] 백그라운드 메시지 수신:', payload);

        const notificationTitle = payload.notification?.title || '새 알림';
        const notificationOptions = {
            body: payload.notification?.body || '',
            icon: '/logo.png',
            badge: '/badge.png',
            data: payload.data,
            tag: payload.data?.type || 'default',
        };

        return self.registration.showNotification(notificationTitle, notificationOptions);
    });
}

// 알림 클릭 이벤트 (초기 평가 시점에 등록)
self.addEventListener('notificationclick', (event) => {
    console.log('[SW] 알림 클릭:', event.notification.data);
    event.notification.close();

    const data = event.notification.data;

    // 화상통화 알림인 경우
    if (data?.type === 'VIDEO_CALL') {
        event.waitUntil(
            clients.openWindow(`/call?sessionId=${data.sessionId}`)
        );
    } else {
        event.waitUntil(clients.openWindow('/'));
    }
});

// Push 이벤트 (초기 평가 시점에 등록)
self.addEventListener('push', (event) => {
    console.log('[SW] Push 이벤트 수신:', event.data?.text());

    if (event.data) {
        const data = event.data.json();
        const title = data.notification?.title || '새 알림';
        const options = {
            body: data.notification?.body || '',
            icon: '/logo.png',
            data: data.data,
        };

        event.waitUntil(
            self.registration.showNotification(title, options)
        );
    }
});

// Push subscription change 이벤트
self.addEventListener('pushsubscriptionchange', (event) => {
    console.log('[SW] Push subscription 변경');
    event.waitUntil(
        self.registration.pushManager.subscribe(event.oldSubscription.options)
            .then((subscription) => {
                console.log('[SW] 구독 갱신 완료');
                // 서버에 새 구독 정보 전송
                return fetch('/api/notifications/update-subscription', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(subscription)
                });
            })
    );
});