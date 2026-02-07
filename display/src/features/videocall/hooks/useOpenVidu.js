// src/features/videocall/hooks/useOpenVidu.js

import { useRef, useCallback } from 'react';
import { OpenVidu } from 'openvidu-browser';
import { OPENVIDU_CONFIG } from '../constants/callConstants';

/**
 * OpenVidu 세션 관리 Hook
 */
const useOpenVidu = () => {
    const ovRef = useRef(null);
    const sessionRef = useRef(null);
    const publisherRef = useRef(null);
    const eventHandlersRef = useRef({}); // 이벤트 핸들러 추적

    /**
     * OpenVidu 세션 정리
     */
    const cleanup = useCallback(() => {
        console.log('🧹 OpenVidu cleanup');

        // Publisher 정리
        if (publisherRef.current && sessionRef.current) {
            try {
                sessionRef.current.unpublish(publisherRef.current);
            } catch (error) {
                console.warn('⚠️ Publisher unpublish 실패:', error);
            }
        }

        // 세션 연결 해제
        if (sessionRef.current) {
            try {
                sessionRef.current.disconnect();
            } catch (error) {
                console.warn('⚠️ Session disconnect 실패:', error);
            }
        }

        // 레퍼런스 초기화
        sessionRef.current = null;
        publisherRef.current = null;
        ovRef.current = null;
        eventHandlersRef.current = {};
    }, []);

    /**
     * OpenVidu 세션 연결
     * @param {string} token - OpenVidu 토큰
     * @param {Object} callbacks - 콜백 함수들
     * @returns {Promise<Object>} publisher 객체
     */
    const connect = useCallback(
        async (token, callbacks = {}) => {
            const { onStreamCreated, onStreamDestroyed, onSessionDisconnected } = callbacks;

            // 중복 연결 방지
            if (sessionRef.current) {
                console.warn('⚠️ 이미 연결된 세션이 있습니다. 기존 세션을 정리합니다.');
                cleanup();
            }

            try {
                console.log('🔌 OpenVidu 연결 시작');

                // OpenVidu 인스턴스 생성
                const OV = new OpenVidu();
                OV.enableProdMode();
                ovRef.current = OV;

                // 세션 초기화
                const session = OV.initSession();
                sessionRef.current = session;

                // 이벤트 핸들러 정의
                const handleStreamCreated = (event) => {
                    console.log('📹 Remote stream created');
                    try {
                        const subscriber = session.subscribe(event.stream, undefined);
                        onStreamCreated?.(subscriber);
                    } catch (error) {
                        console.error('❌ Subscribe 실패:', error);
                    }
                };

                const handleStreamDestroyed = (event) => {
                    console.log('📹 Remote stream destroyed:', event.stream.streamId);
                    onStreamDestroyed?.();
                };

                const handleSessionDisconnected = (event) => {
                    console.log('🔌 Session disconnected:', event.reason);
                    onSessionDisconnected?.();
                };

                // 이벤트 리스너 등록
                session.on('streamCreated', handleStreamCreated);
                session.on('streamDestroyed', handleStreamDestroyed);
                session.on('sessionDisconnected', handleSessionDisconnected);

                // 핸들러 저장 (cleanup용)
                eventHandlersRef.current = {
                    streamCreated: handleStreamCreated,
                    streamDestroyed: handleStreamDestroyed,
                    sessionDisconnected: handleSessionDisconnected,
                };

                // 세션 연결
                await session.connect(token);
                console.log('✅ Session connected:', session.sessionId);

                // Publisher 생성
                const publisher = await OV.initPublisherAsync(undefined, {
                    audioSource: undefined,
                    videoSource: undefined,
                    publishAudio: OPENVIDU_CONFIG.AUDIO,
                    publishVideo: OPENVIDU_CONFIG.VIDEO,
                    resolution: OPENVIDU_CONFIG.RESOLUTION,
                    frameRate: OPENVIDU_CONFIG.FRAME_RATE,
                    mirror: OPENVIDU_CONFIG.MIRROR,
                });

                // Publisher 발행
                await session.publish(publisher);
                publisherRef.current = publisher;

                console.log('✅ Publisher created and published');
                return publisher;
            } catch (error) {
                console.error('❌ OpenVidu 연결 실패:', error);
                cleanup();
                throw error;
            }
        },
        [cleanup]
    );

    /**
     * 마이크 토글
     * @param {boolean} enabled
     */
    const toggleAudio = useCallback((enabled) => {
        if (publisherRef.current) {
            publisherRef.current.publishAudio(enabled);
            console.log(`🎤 Mic ${enabled ? 'ON' : 'OFF'}`);
        } else {
            console.warn('⚠️ Publisher가 없습니다.');
        }
    }, []);

    /**
     * 카메라 토글
     * @param {boolean} enabled
     */
    const toggleVideo = useCallback((enabled) => {
        if (publisherRef.current) {
            publisherRef.current.publishVideo(enabled);
            console.log(`📹 Camera ${enabled ? 'ON' : 'OFF'}`);
        } else {
            console.warn('⚠️ Publisher가 없습니다.');
        }
    }, []);

    /**
     * 현재 연결 상태 확인
     */
    const isConnected = useCallback(() => {
        return !!sessionRef.current && !!publisherRef.current;
    }, []);

    return {
        connect,
        cleanup,
        toggleAudio,
        toggleVideo,
        isConnected,
    };
};

export default useOpenVidu;
