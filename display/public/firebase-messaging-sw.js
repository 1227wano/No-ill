/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

let messaging = null;

self.addEventListener('message', (event) => {
    if (event.data && event.data.type === 'FIREBASE_CONFIG') {
        const config = event.data.config;
        if (!firebase.apps.length) {
            firebase.initializeApp(config);
        }
        messaging = firebase.messaging();

        messaging.onBackgroundMessage((payload) => {
            console.log('[SW] Background message received:', payload);

            const data = payload.data || {};

            if (data.type === 'VIDEO_CALL') {
                self.registration.showNotification('영상 통화', {
                    body: '보호자님이 영상 통화를 요청합니다.',
                    icon: '/favicon.ico',
                    data: { sessionId: data.sessionId },
                });
            }
        });
    }
});
