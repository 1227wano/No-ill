// src/features/videocall/hooks/useCallNotification.js

import { useEffect, useRef, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { onForegroundMessage } from '../services/fcmService';
import { CALL_TYPE, CALL_STATE } from '../constants/callConstants';

/**
 * 전화 알림 수신 Hook (FCM + Service Worker + URL)
 * @param {boolean} isAuthenticated - 인증 여부
 * @param {string} callState - 현재 통화 상태
 * @param {Function} onIncomingCall - 수신 전화 콜백
 */
const useCallNotification = (isAuthenticated, callState, onIncomingCall) => {
    const [searchParams, setSearchParams] = useSearchParams();
    const processedCallsRef = useRef(new Set()); // 중복 방지

    /**
     * 수신 전화 처리 (중복 방지)
     */
    const handleIncomingCall = useCallback(
        (callInfo, source) => {
            const { sessionId, callerName } = callInfo;

            // 유효성 검증
            if (!sessionId || typeof sessionId !== 'string') {
                console.warn(`⚠️ [${source}] 잘못된 sessionId:`, sessionId);
                return;
            }

            // 통화 중이면 무시
            if (callState !== CALL_STATE.IDLE) {
                console.warn(`⚠️ [${source}] 통화 중이므로 무시:`, callState);
                return;
            }

            // 중복 호출 방지 (5초 내 같은 sessionId)
            if (processedCallsRef.current.has(sessionId)) {
                console.warn(`⚠️ [${source}] 중복 호출 무시:`, sessionId);
                return;
            }

            console.log(`📞 [${source}] 수신 전화 처리:`, sessionId);

            // 중복 방지 Set에 추가
            processedCallsRef.current.add(sessionId);

            // 5초 후 제거 (같은 전화가 재시도될 수 있음)
            setTimeout(() => {
                processedCallsRef.current.delete(sessionId);
            }, 5000);

            // 콜백 실행
            onIncomingCall({
                sessionId,
                callerName: callerName || '보호자',
            });
        },
        [callState, onIncomingCall]
    );

    // 1️⃣ FCM 포그라운드 메시지 리스너
    useEffect(() => {
        if (!isAuthenticated) return;

        let unsubscribe;

        const setupFcmListener = async () => {
            try {
                unsubscribe = await onForegroundMessage((payload) => {
                    console.log('📞 [FCM] 포그라운드 메시지:', payload);

                    const data = payload.data || {};

                    if (data.type === CALL_TYPE.VIDEO_CALL && data.sessionId) {
                        handleIncomingCall(
                            {
                                sessionId: data.sessionId,
                                callerName: data.callerName,
                            },
                            'FCM'
                        );
                    }
                });

                console.log('✅ [FCM] 리스너 등록 완료');
            } catch (error) {
                console.error('❌ [FCM] 리스너 등록 실패:', error);
            }
        };

        setupFcmListener();

        return () => {
            if (typeof unsubscribe === 'function') {
                unsubscribe();
                console.log('🧹 [FCM] 리스너 제거');
            }
        };
    }, [isAuthenticated, handleIncomingCall]);

    // 2️⃣ Service Worker 메시지 리스너
    useEffect(() => {
        if (!isAuthenticated) return;

        // Service Worker 지원 확인
        if (!('serviceWorker' in navigator)) {
            console.warn('⚠️ [SW] Service Worker 미지원');
            return;
        }

        const handleServiceWorkerMessage = (event) => {
            console.log('📞 [SW] 메시지 수신:', event.data);

            const data = event.data || {};

            if (data.type === CALL_TYPE.VIDEO_CALL_INCOMING && data.sessionId) {
                handleIncomingCall(
                    {
                        sessionId: data.sessionId,
                        callerName: data.callerName,
                    },
                    'SW'
                );
            }
        };

        navigator.serviceWorker.addEventListener('message', handleServiceWorkerMessage);
        console.log('✅ [SW] 리스너 등록 완료');

        return () => {
            navigator.serviceWorker.removeEventListener('message', handleServiceWorkerMessage);
            console.log('🧹 [SW] 리스너 제거');
        };
    }, [isAuthenticated, handleIncomingCall]);

    // 3️⃣ URL 파라미터 리스너 (백그라운드 푸시 클릭)
    useEffect(() => {
        if (!isAuthenticated) return;

        const incomingSessionId = searchParams.get('incomingCall');
        const callerName = searchParams.get('callerName');

        if (incomingSessionId) {
            console.log('📞 [URL] 수신 전화 파라미터:', incomingSessionId);

            handleIncomingCall(
                {
                    sessionId: incomingSessionId,
                    callerName: callerName || '보호자',
                },
                'URL'
            );

            // URL 파라미터 제거
            searchParams.delete('incomingCall');
            searchParams.delete('callerName');
            setSearchParams(searchParams, { replace: true });
        }
    }, [isAuthenticated, searchParams, setSearchParams, handleIncomingCall]);

    // Cleanup: 컴포넌트 언마운트 시
    useEffect(() => {
        const processedCalls = processedCallsRef.current;
        return () => {
            processedCalls.clear();
        };
    }, []);
};

export default useCallNotification;
