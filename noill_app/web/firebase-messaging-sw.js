// web/firebase-messaging-sw.js

// 1. 파이어베이스 라이브러리를 불러옵니다.
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

// 2. 파이어베이스 초기화 (아까 본진에서 확인한 설정값들을 넣습니다)
firebase.initializeApp({
  apiKey: "AIzaSy...",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef"
});

const messaging = firebase.messaging();

// 백그라운드 메시지 수신 시 처리 (선택 사항)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] 백그라운드 메시지 수신: ', payload);
});