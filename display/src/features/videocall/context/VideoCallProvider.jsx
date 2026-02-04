import React, { useState, useCallback, useEffect, useRef } from 'react';
import { OpenVidu } from 'openvidu-browser';
import { VideoCallContext } from './VideoCallContext';
import { createSession, createConnection, callUser } from '../services/openviduApi';
import { onForegroundMessage } from '../services/fcmService';
import { useAuth } from '../../auth';

const VideoCallProvider = ({ children }) => {
    const { isAuthenticated } = useAuth();
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
            setCallState('calling');

            const sessionData = await createSession();
            const sessionId = sessionData.sessionId || sessionData;

            const connectionData = await createConnection(sessionId);
            const token = connectionData.token || connectionData;

            await callUser(userId, sessionId);
            await connectToSession(token);

            setCallState('ringing');
        } catch (error) {
            console.error('영상 통화 발신 실패:', error);
            cleanup();
            setCallState('idle');
        }
    }, [connectToSession, cleanup]);

    // 수신 수락
    const acceptCall = useCallback(async () => {
        if (!incomingCall) return;

        try {
            setCallState('calling');

            const connectionData = await createConnection(incomingCall.sessionId);
            const token = connectionData.token || connectionData;

            await connectToSession(token);
            setIncomingCall(null);
        } catch (error) {
            console.error('영상 통화 수락 실패:', error);
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
        try {
            unsubscribe = onForegroundMessage((payload) => {
                const data = payload.data || {};
                if (data.type === 'VIDEO_CALL' && data.sessionId) {
                    if (callState === 'idle') {
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

        return () => {
            if (typeof unsubscribe === 'function') {
                unsubscribe();
            }
        };
    }, [isAuthenticated, callState]);

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
