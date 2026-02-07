// src/features/videocall/context/VideoCallProvider.jsx

import React, { useState, useCallback, useEffect } from 'react';
import { VideoCallContext } from './VideoCallContext';
import { useAuth } from '../../auth';
import useOpenVidu from '../hooks/useOpenVidu';
import useCallNotification from '../hooks/useCallNotification';
import { openviduApi } from '../services/openviduApi';
import { CALL_STATE, CALL_END_DELAY } from '../constants/callConstants';

const VideoCallProvider = ({ children }) => {
    const { isAuthenticated } = useAuth();

    // 상태
    const [callState, setCallState] = useState(CALL_STATE.IDLE);
    const [incomingCall, setIncomingCall] = useState(null);
    const [localStream, setLocalStream] = useState(null);
    const [remoteStream, setRemoteStream] = useState(null);
    const [isMicOn, setIsMicOn] = useState(true);
    const [isCameraOn, setIsCameraOn] = useState(true);
    const [error, setError] = useState(null);

    // OpenVidu Hook
    const { connect, cleanup: cleanupOpenVidu, toggleAudio, toggleVideo } = useOpenVidu();

    /**
     * 전체 상태 초기화
     */
    const resetState = useCallback(() => {
        cleanupOpenVidu();
        setLocalStream(null);
        setRemoteStream(null);
        setIsMicOn(true);
        setIsCameraOn(true);
        setError(null);
        setCallState(CALL_STATE.IDLE);
    }, [cleanupOpenVidu]);

    /**
     * OpenVidu 세션 연결 (공통)
     * @param {boolean} waitForRemote - 상대방 연결을 기다릴지 여부
     */
    const connectSession = useCallback(
        async (token, waitForRemote = true) => {
            try {
                const publisher = await connect(token, {
                    onStreamCreated: (subscriber) => {
                        console.log('✅ Remote stream connected');
                        setRemoteStream(subscriber);
                        // ⭐ 상대방 연결 시 항상 CONNECTED
                        if (callState !== CALL_STATE.CONNECTED) {
                            setCallState(CALL_STATE.CONNECTED);
                        }
                    },
                    onStreamDestroyed: () => {
                        console.log('⚠️ Remote stream disconnected');
                        setRemoteStream(null);
                        setCallState(CALL_STATE.ENDED);

                        // 2초 후 초기화
                        setTimeout(resetState, CALL_END_DELAY);
                    },
                    onSessionDisconnected: () => {
                        console.log('⚠️ Session disconnected');

                        // ⭐ CALLING 상태에서는 무시 (아직 연결 중)
                        if (callState === CALL_STATE.CALLING) {
                            console.log('   → CALLING 상태이므로 무시');
                            return;
                        }

                        setCallState(CALL_STATE.ENDED);

                        // 2초 후 초기화
                        setTimeout(resetState, CALL_END_DELAY);
                    },
                });

                setLocalStream(publisher);

                // ⭐ 상대방을 기다리지 않으면 바로 CONNECTED
                if (!waitForRemote) {
                    setCallState(CALL_STATE.CONNECTED);
                }
            } catch (error) {
                console.error('❌ 세션 연결 실패:', error);
                setError('세션 연결에 실패했습니다.');
                resetState();
                throw error;
            }
        },
        [connect, resetState, callState]
    );

    /**
     * 발신: 특정 사용자에게 전화
     */
    const startCall = useCallback(
        async (userId) => {
            try {
                console.log('📞 전화 걸기 시작:', userId);
                setCallState(CALL_STATE.CALLING);
                setError(null);

                // 1. 세션 생성
                const sessionData = await openviduApi.createSession();
                const sessionId = sessionData.sessionId || sessionData;

                // 2. 토큰 발급
                const connectionData = await openviduApi.createConnection(sessionId);
                const token = connectionData.token || connectionData;

                // 3. 상대방 호출
                await openviduApi.callUser(userId, sessionId);

                // 4. OpenVidu 연결 (상대방 기다림)
                await connectSession(token, true);

                console.log('✅ 전화 걸기 완료');
            } catch (error) {
                console.error('❌ 전화 걸기 실패:', error);
                setError('전화 연결에 실패했습니다.');
                resetState();
            }
        },
        [connectSession, resetState]
    );

    /**
     * 발신: 모든 보호자에게 전화 (Pet Call)
     */
    const startPetCall = useCallback(async () => {
        try {
            console.log('📞 보호자 전체 호출 시작');
            setCallState(CALL_STATE.CALLING);
            setError(null);

            // 1. 세션 생성
            const sessionData = await openviduApi.createSession();
            const sessionId = sessionData.sessionId || sessionData;
            console.log('✅ 세션 생성:', sessionId);

            // 2. 토큰 발급
            const connectionData = await openviduApi.createConnection(sessionId);
            const token = connectionData.token || connectionData;
            console.log('✅ 토큰 발급 완료');

            // 3. OpenVidu 연결 (먼저 연결)
            await connectSession(token, false);  // ⭐ 상대방 기다리지 않음
            console.log('✅ OpenVidu 연결 완료');

            // 4. 모든 보호자 호출 (FCM 전송)
            await openviduApi.callUsersByPet(sessionId);
            console.log('✅ 보호자 호출 신호 전송 완료');

            console.log('✅ 보호자 호출 완료 - 연결 대기 중...');
        } catch (error) {
            console.error('❌ 보호자 호출 실패:', error);
            setError('보호자 호출에 실패했습니다.');
            resetState();
        }
    }, [connectSession, resetState]);

    /**
     * 수신: 전화 수락
     */
    const acceptCall = useCallback(async () => {
        if (!incomingCall) {
            console.warn('⚠️ 수신 전화가 없습니다.');
            return;
        }

        try {
            console.log('📞 전화 수락:', incomingCall.sessionId);
            setCallState(CALL_STATE.CALLING);
            setError(null);

            // 1. 토큰 발급
            const connectionData = await openviduApi.createConnection(incomingCall.sessionId);
            const token = connectionData.token || connectionData;

            // 2. OpenVidu 연결
            await connectSession(token, false);  // ⭐ 바로 CONNECTED

            setIncomingCall(null);
            console.log('✅ 전화 수락 완료');
        } catch (error) {
            console.error('❌ 전화 수락 실패:', error);
            setError('전화 수락에 실패했습니다.');
            resetState();
            setIncomingCall(null);
        }
    }, [incomingCall, connectSession, resetState]);

    /**
     * 수신: 전화 거절
     */
    const rejectCall = useCallback(() => {
        console.log('📞 전화 거절');
        setIncomingCall(null);
        setCallState(CALL_STATE.IDLE);
    }, []);

    /**
     * 통화 종료
     */
    const endCall = useCallback(() => {
        console.log('📞 통화 종료 (사용자 요청)');
        setCallState(CALL_STATE.ENDED);

        // 2초 후 초기화
        setTimeout(() => {
            resetState();
            setIncomingCall(null);
        }, CALL_END_DELAY);
    }, [resetState]);

    /**
     * 마이크 토글
     */
    const toggleMic = useCallback(() => {
        const newState = !isMicOn;
        toggleAudio(newState);
        setIsMicOn(newState);
    }, [isMicOn, toggleAudio]);

    /**
     * 카메라 토글
     */
    const toggleCamera = useCallback(() => {
        const newState = !isCameraOn;
        toggleVideo(newState);
        setIsCameraOn(newState);
    }, [isCameraOn, toggleVideo]);

    /**
     * 수신 전화 핸들러
     */
    const handleIncomingCall = useCallback(
        (callInfo) => {
            console.log('📞 수신 전화:', callInfo);
            setIncomingCall(callInfo);
            setCallState(CALL_STATE.RINGING);
        },
        []
    );

    // 알림 리스너 (FCM, Service Worker, URL)
    useCallNotification(isAuthenticated, callState, handleIncomingCall);

    // Cleanup on unmount
    useEffect(() => {
        return () => {
            cleanupOpenVidu();
        };
    }, [cleanupOpenVidu]);

    const value = {
        callState,
        incomingCall,
        localStream,
        remoteStream,
        isMicOn,
        isCameraOn,
        error,
        startCall,
        startPetCall,
        acceptCall,
        rejectCall,
        endCall,
        toggleMic,
        toggleCamera,
    };

    return <VideoCallContext.Provider value={value}>{children}</VideoCallContext.Provider>;
};

export default VideoCallProvider;
