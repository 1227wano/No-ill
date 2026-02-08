// src/features/videocall/components/VideoCallOverlay.jsx

import React, { useRef, useEffect, useState } from 'react';
import useVideoCall from '../hooks/useVideoCall';
import { CALL_STATE } from '../constants/callConstants';

const VideoCallOverlay = () => {
    const {
        callState,
        localStream,
        remoteStream,
        isMicOn,
        isCameraOn,
        endCall,
        toggleMic,
        toggleCamera,
    } = useVideoCall();

    const remoteVideoRef = useRef(null);
    const localVideoRef = useRef(null);
    const [callDuration, setCallDuration] = useState(0);
    const [isFullscreen, setIsFullscreen] = useState(false);

    // 원격 비디오 연결
    useEffect(() => {
        if (remoteStream && remoteVideoRef.current) {
            remoteStream.addVideoElement(remoteVideoRef.current);
        }
    }, [remoteStream]);

    // 로컬 비디오 연결
    useEffect(() => {
        if (localStream && localVideoRef.current) {
            localStream.addVideoElement(localVideoRef.current);
        }
    }, [localStream]);

    // 통화 시간 타이머
    useEffect(() => {
        if (callState !== CALL_STATE.CONNECTED) {
            // eslint-disable-next-line react-hooks/set-state-in-effect
            setCallDuration(0);
            return;
        }

        const timer = setInterval(() => {
            setCallDuration((prev) => prev + 1);
        }, 1000);

        return () => clearInterval(timer);
    }, [callState]);

    // 전체화면 토글
    const toggleFullscreen = () => {
        if (!document.fullscreenElement) {
            document.documentElement.requestFullscreen();
            setIsFullscreen(true);
        } else {
            document.exitFullscreen();
            setIsFullscreen(false);
        }
    };

    // 전체화면 상태 감지
    useEffect(() => {
        const handleFullscreenChange = () => {
            setIsFullscreen(!!document.fullscreenElement);
        };

        document.addEventListener('fullscreenchange', handleFullscreenChange);
        return () => document.removeEventListener('fullscreenchange', handleFullscreenChange);
    }, []);

    if (callState === CALL_STATE.IDLE || callState === CALL_STATE.RINGING) {
        return null;
    }

    // 통화 시간 포맷 (00:00:00)
    const formatDuration = (seconds) => {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        const s = seconds % 60;
        return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    };

    const statusText = {
        [CALL_STATE.CALLING]: '연결 중...',
        [CALL_STATE.CONNECTED]: '',
        [CALL_STATE.ENDED]: '통화가 종료되었습니다',
    };

    return (
        <div className="fixed inset-0 z-50 bg-black" role="dialog" aria-label="영상 통화">
            {/* 상대방 비디오 (전체화면) */}
            <div className="absolute inset-0">
                {remoteStream ? (
                    <video
                        ref={remoteVideoRef}
                        autoPlay
                        playsInline
                        className="w-full h-full object-cover"
                        aria-label="상대방 비디오"
                    />
                ) : (
                    <div className="w-full h-full flex items-center justify-center bg-gray-900">
                        <div className="text-center">
                            <div className="text-8xl mb-6" role="img" aria-label="전화 아이콘">
                                📞
                            </div>
                            <p className="text-white text-3xl font-bold">
                                {statusText[callState] || '연결 중...'}
                            </p>
                            {callState === CALL_STATE.CALLING && (
                                <div className="mt-6 flex justify-center gap-2" aria-label="로딩 중">
                                    <span
                                        className="w-3 h-3 bg-white rounded-full animate-bounce"
                                        style={{ animationDelay: '0ms' }}
                                    />
                                    <span
                                        className="w-3 h-3 bg-white rounded-full animate-bounce"
                                        style={{ animationDelay: '150ms' }}
                                    />
                                    <span
                                        className="w-3 h-3 bg-white rounded-full animate-bounce"
                                        style={{ animationDelay: '300ms' }}
                                    />
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {/* 내 비디오 (PIP) */}
                {localStream && (
                    <div className="absolute top-6 right-6 w-48 h-36 rounded-2xl overflow-hidden border-2 border-white shadow-lg">
                        <video
                            ref={localVideoRef}
                            autoPlay
                            playsInline
                            muted
                            className="w-full h-full object-cover"
                            aria-label="내 비디오"
                        />
                    </div>
                )}

                {/* 통화 시간 (상단 중앙) */}
                {callState === CALL_STATE.CONNECTED && (
                    <div className="absolute top-6 left-1/2 -translate-x-1/2 bg-black/50 backdrop-blur px-6 py-3 rounded-full">
                        <p className="text-white text-2xl font-mono font-bold">
                            {formatDuration(callDuration)}
                        </p>
                    </div>
                )}
            </div>

            {/* 컨트롤 오버레이 */}
            <div className="absolute left-0 right-0 bottom-0 pb-10 px-8">
                <div className="mx-auto max-w-3xl bg-gray-900/80 backdrop-blur rounded-3xl px-10 py-6 shadow-lg">
                    <div className="flex items-center justify-center gap-10">
                        {/* 마이크 토글 */}
                        <button
                            onClick={toggleMic}
                            className={`w-20 h-20 rounded-full flex items-center justify-center text-4xl transition-all ${
                                isMicOn
                                    ? 'bg-gray-700 text-white hover:bg-gray-600'
                                    : 'bg-red-500 text-white hover:bg-red-400'
                            }`}
                            aria-label={isMicOn ? '마이크 끄기' : '마이크 켜기'}
                        >
                            {isMicOn ? '🎤' : '🔇'}
                        </button>

                        {/* 통화 종료 */}
                        <button
                            onClick={endCall}
                            className="w-28 h-28 rounded-full bg-danger text-white flex items-center justify-center text-6xl hover:bg-danger/80 active:scale-95 transition-all shadow-lg"
                            aria-label="통화 종료"
                        >
                            📵
                        </button>

                        {/* 카메라 토글 */}
                        <button
                            onClick={toggleCamera}
                            className={`w-20 h-20 rounded-full flex items-center justify-center text-4xl transition-all ${
                                isCameraOn
                                    ? 'bg-gray-700 text-white hover:bg-gray-600'
                                    : 'bg-red-500 text-white hover:bg-red-400'
                            }`}
                            aria-label={isCameraOn ? '카메라 끄기' : '카메라 켜기'}
                        >
                            {isCameraOn ? '📹' : '🚫'}
                        </button>

                        {/* 전체화면 토글 */}
                        <button
                            onClick={toggleFullscreen}
                            className="w-20 h-20 rounded-full bg-gray-700 text-white hover:bg-gray-600 flex items-center justify-center text-4xl transition-all"
                            aria-label={isFullscreen ? '전체화면 종료' : '전체화면'}
                        >
                            {isFullscreen ? '🗗' : '⛶'}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default VideoCallOverlay;
