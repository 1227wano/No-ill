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

    // 백그라운드 메시지 핸들러
    messaging.onBackgroundMessage((payload) => {
        console.log('[SW] 백그라운드 메시지 수신:', payload);

        const data = payload.data || {};

        // 🔥 핵심: 알림 클릭을 기다리지 말고, 열린 페이지가 있으면 즉시 전달
        if (data.type === 'VIDEO_CALL' && data.sessionId) {
            notifyClientsIncomingCall(data);
        }

        const notificationTitle = payload.notification?.title || (data.type === 'VIDEO_CALL' ? '영상 통화' : '새 알림');
        const notificationOptions = {
            body: payload.notification?.body || '',
            icon: '/logo.png',
            badge: '/badge.png',
            data,
            tag: data?.type || 'default',
        };

        return self.registration.showNotification(notificationTitle, notificationOptions);
    });
}

async function notifyClientsIncomingCall(data) {
    const clientList = await clients.matchAll({type: 'window', includeUncontrolled: true});

    for (const client of clientList) {
        client.postMessage({
            type: 'VIDEO_CALL_INCOMING',
            sessionId: data.sessionId,
            callerName: data.callerName || '보호자',
        });
    }
}

// 알림 클릭 이벤트
self.addEventListener('notificationclick', (event) => {
    console.log('[SW] 알림 클릭:', event.notification.data);
    event.notification.close();

    const data = event.notification.data;

    if (data?.type === 'VIDEO_CALL' && data?.sessionId) {
        event.waitUntil(
            clients.matchAll({type: 'window', includeUncontrolled: true}).then((clientList) => {
                for (const client of clientList) {
                    if (client.url.includes(self.location.origin)) {
                        client.postMessage({
                            type: 'VIDEO_CALL_INCOMING',
                            sessionId: data.sessionId,
                            callerName: data.callerName || '보호자'
                        });
                        return client.focus();
                    }
                }
                return clients.openWindow(`/?incomingCall=${data.sessionId}`);
            })
        );
    } else {
        event.waitUntil(clients.openWindow('/'));
    }
});

// Push 이벤트
self.addEventListener('push', (event) => {
    console.log('[SW] Push 이벤트 수신:', event.data?.text());

    if (event.data) {
        const raw = event.data.json();

        const data = raw.data || {};

        // 🔥 핵심: push 이벤트로 들어온 data-only 메시지도 즉시 페이지로 전달
        if (data.type === 'VIDEO_CALL' && data.sessionId) {
            event.waitUntil(notifyClientsIncomingCall(data));
        }

        const title = raw.notification?.title || (data.type === 'VIDEO_CALL' ? '영상 통화' : '새 알림');
        const options = {
            body: raw.notification?.body || '',
            icon: '/logo.png',
            data,
        };

        event.waitUntil(self.registration.showNotification(title, options));
    }
});

// Push subscription change 이벤트
self.addEventListener('pushsubscriptionchange', (event) => {
    console.log('[SW] Push subscription 변경');
    event.waitUntil(
        self.registration.pushManager.subscribe(event.oldSubscription.options)
            .then((subscription) => {
                console.log('[SW] 구독 갱신 완료');
                return fetch('/api/notifications/update-subscription', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(subscription)
                });
            })
    );
});