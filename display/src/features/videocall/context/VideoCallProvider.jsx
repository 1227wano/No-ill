import React, { useState, useCallback, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import { OpenVidu } from 'openvidu-browser';
import { VideoCallContext } from './VideoCallContext';
import { createSession, createConnection, callUser } from '../services/openviduApi';
import { onForegroundMessage } from '../services/fcmService';
import { useAuth } from '../../auth';

const VideoCallProvider = ({ children }) => {
    const { isAuthenticated } = useAuth();
    const [searchParams, setSearchParams] = useSearchParams();
    const [callState, setCallState] = useState('idle');
    const [incomingCall, setIncomingCall] = useState(null);
    const [localStream, setLocalStream] = useState(null);
    const [remoteStream, setRemoteStream] = useState(null);
    const [isMicOn, setIsMicOn] = useState(true);
    const [isCameraOn, setIsCameraOn] = useState(true);

    const ovRef = useRef(null);
    const sessionRef = useRef(null);
    const publisherRef = useRef(null);

    const cleanup = useCallback(() => {
        if (sessionRef.current) {
            sessionRef.current.disconnect();
        }
        sessionRef.current = null;
        publisherRef.current = null;
        ovRef.current = null;
        setLocalStream(null);
        setRemoteStream(null);
        setIsMicOn(true);
        setIsCameraOn(true);
    }, []);

    const connectToSession = useCallback(async (token) => {
        const OV = new OpenVidu();
        OV.enableProdMode();
        ovRef.current = OV;

        const session = OV.initSession();
        sessionRef.current = session;

        session.on('streamCreated', (event) => {
            const subscriber = session.subscribe(event.stream, undefined);
            setRemoteStream(subscriber);
            setCallState('connected');
        });

        session.on('streamDestroyed', () => {
            setRemoteStream(null);
            setCallState('ended');
            setTimeout(() => {
                cleanup();
                setCallState('idle');
            }, 2000);
        });

        session.on('sessionDisconnected', () => {
            setCallState('ended');
            setTimeout(() => {
                cleanup();
                setCallState('idle');
            }, 2000);
        });

        await session.connect(token);

        const publisher = await OV.initPublisherAsync(undefined, {
            audioSource: undefined,
            videoSource: undefined,
            publishAudio: true,
            publishVideo: true,
            resolution: '640x480',
            frameRate: 30,
            mirror: true,
        });

        session.publish(publisher);
        publisherRef.current = publisher;
        setLocalStream(publisher);
    }, [cleanup]);

    // 발신: 디스플레이 → 보호자
    const startCall = useCallback(async (userId) => {
        try {
            console.log('📞 [Step 1] 전화 걸기 시작, userId:', userId);
            setCallState('calling');

            console.log('📞 [Step 2] 세션 생성 요청...');
            const sessionData = await createSession();
            const sessionId = sessionData.sessionId || sessionData;
            console.log('✅ [Step 2] 세션 생성 완료:', sessionId);

            console.log('📞 [Step 3] 토큰 발급 요청...');
            const connectionData = await createConnection(sessionId);
            const token = connectionData.token || connectionData;
            console.log('✅ [Step 3] 토큰 발급 완료:', token?.substring(0, 20) + '...');

            console.log('📞 [Step 4] 상대방 호출...');
            await callUser(userId, sessionId);
            console.log('✅ [Step 4] 상대방 호출 완료');

            console.log('📞 [Step 5] OpenVidu 연결...');
            await connectToSession(token);
            console.log('✅ [Step 5] OpenVidu 연결 완료');

            setCallState('ringing');
        } catch (error) {
            console.error('❌ 영상 통화 발신 실패:', error);
            console.error('❌ Error stack:', error.stack);
            cleanup();
            setCallState('idle');
        }
    }, [connectToSession, cleanup]);

    // 수신 수락
    const acceptCall = useCallback(async () => {
        if (!incomingCall) {
            console.log('❌ [acceptCall] incomingCall이 없음');
            return;
        }

        try {
            console.log('📞 [acceptCall] 수신 수락 시작, sessionId:', incomingCall.sessionId);
            setCallState('calling');

            console.log('📞 [acceptCall] 토큰 발급 요청...');
            const connectionData = await createConnection(incomingCall.sessionId);
            const token = connectionData.token || connectionData;
            console.log('✅ [acceptCall] 토큰 발급 완료');

            console.log('📞 [acceptCall] OpenVidu 연결 시작...');
            await connectToSession(token);
            console.log('✅ [acceptCall] OpenVidu 연결 완료');

            setIncomingCall(null);
        } catch (error) {
            console.error('❌ 영상 통화 수락 실패:', error);
            cleanup();
            setCallState('idle');
            setIncomingCall(null);
        }
    }, [incomingCall, connectToSession, cleanup]);

    // 수신 거절
    const rejectCall = useCallback(() => {
        setIncomingCall(null);
        setCallState('idle');
    }, []);

    // 통화 종료
    const endCall = useCallback(() => {
        cleanup();
        setCallState('idle');
        setIncomingCall(null);
    }, [cleanup]);

    // 마이크 토글
    const toggleMic = useCallback(() => {
        if (publisherRef.current) {
            const newState = !isMicOn;
            publisherRef.current.publishAudio(newState);
            setIsMicOn(newState);
        }
    }, [isMicOn]);

    // 카메라 토글
    const toggleCamera = useCallback(() => {
        if (publisherRef.current) {
            const newState = !isCameraOn;
            publisherRef.current.publishVideo(newState);
            setIsCameraOn(newState);
        }
    }, [isCameraOn]);

    // FCM 포그라운드 메시지 리스너
    useEffect(() => {
        if (!isAuthenticated) return;

        let unsubscribe;
        const setupFcmListener = async () => {
            try {
                unsubscribe = await onForegroundMessage((payload) => {
                    console.log('📞 [FCM] 포그라운드 메시지 수신:', payload);
                    const data = payload.data || {};
                    if (data.type === 'VIDEO_CALL' && data.sessionId) {
                        if (callState === 'idle') {
                            console.log('📞 [FCM] 수신 전화 설정:', data.sessionId);
                            setIncomingCall({
                                sessionId: data.sessionId,
                                callerName: data.callerName || '보호자',
                            });
                            setCallState('ringing');
                        }
                    }
                });
            } catch (error) {
                console.error('FCM 리스너 등록 실패:', error);
            }
        };

        setupFcmListener();

        return () => {
            if (typeof unsubscribe === 'function') {
                unsubscribe();
            }
        };
    }, [isAuthenticated, callState]);

    // Service Worker 메시지 리스너 (백그라운드 알림 클릭 시)
    useEffect(() => {
        if (!isAuthenticated) return;

        const handleServiceWorkerMessage = (event) => {
            console.log('📞 [SW] 메시지 수신:', event.data);
            if (event.data?.type === 'VIDEO_CALL_INCOMING' && event.data?.sessionId) {
                if (callState === 'idle') {
                    console.log('📞 [SW] 수신 전화 설정:', event.data.sessionId);
                    setIncomingCall({
                        sessionId: event.data.sessionId,
                        callerName: event.data.callerName || '보호자',
                    });
                    setCallState('ringing');
                }
            }
        };

        navigator.serviceWorker?.addEventListener('message', handleServiceWorkerMessage);

        return () => {
            navigator.serviceWorker?.removeEventListener('message', handleServiceWorkerMessage);
        };
    }, [isAuthenticated, callState]);

    // URL 파라미터로 수신 전화 처리 (새 창으로 열릴 때)
    useEffect(() => {
        if (!isAuthenticated) return;

        const incomingSessionId = searchParams.get('incomingCall');
        if (incomingSessionId && callState === 'idle') {
            // setTimeout으로 비동기 처리하여 린트 규칙 준수
            const timer = setTimeout(() => {
                console.log('📞 [URL] 수신 전화 파라미터 감지:', incomingSessionId);
                setIncomingCall({
                    sessionId: incomingSessionId,
                    callerName: '보호자',
                });
                setCallState('ringing');
            }, 0);
            // URL 파라미터 제거
            searchParams.delete('incomingCall');
            setSearchParams(searchParams, { replace: true });

            return () => clearTimeout(timer);
        }
    }, [isAuthenticated, searchParams, setSearchParams, callState]);

    // 컴포넌트 언마운트 시 세션 정리
    useEffect(() => {
        return () => {
            if (sessionRef.current) {
                sessionRef.current.disconnect();
            }
        };
    }, []);

    const value = {
        callState,
        incomingCall,
        localStream,
        remoteStream,
        isMicOn,
        isCameraOn,
        startCall,
        acceptCall,
        rejectCall,
        endCall,
        toggleMic,
        toggleCamera,
    };

    return (
        <VideoCallContext.Provider value={value}>
            {children}
        </VideoCallContext.Provider>
    );
};

export default VideoCallProvider;
