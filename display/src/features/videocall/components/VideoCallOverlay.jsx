import React, { useRef, useEffect } from 'react';
import useVideoCall from '../hooks/useVideoCall';

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

    useEffect(() => {
        if (remoteStream && remoteVideoRef.current) {
            remoteStream.addVideoElement(remoteVideoRef.current);
        }
    }, [remoteStream]);

    useEffect(() => {
        if (localStream && localVideoRef.current) {
            localStream.addVideoElement(localVideoRef.current);
        }
    }, [localStream]);

    if (callState === 'idle' || callState === 'ringing') {
        return null;
    }

    const statusText = {
        calling: '연결 중...',
        connected: '',
        ended: '통화가 종료되었습니다',
    };

    return (
        <div className="fixed inset-0 z-50 bg-black flex flex-col">
            {/* 상대방 비디오 (전체화면) */}
            <div className="flex-1 relative">
                {remoteStream ? (
                    <video
                        ref={remoteVideoRef}
                        autoPlay
                        playsInline
                        className="w-full h-full object-cover"
                    />
                ) : (
                    <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
                        <div className="text-center">
                            <div className="text-[200px] mb-10 animate-pulse">📞</div>
                            <p className="text-white text-6xl font-bold mb-4 tracking-wide">
                                {statusText[callState] || '연결 중...'}
                            </p>
                            {callState === 'calling' && (
                                <div className="mt-10 flex justify-center gap-4">
                                    <span className="w-5 h-5 bg-white rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                                    <span className="w-5 h-5 bg-white rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                                    <span className="w-5 h-5 bg-white rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                                </div>
                            )}
                        </div>
                    </div>
                )}

                {/* 내 비디오 (PIP) - 더 크게 */}
                {localStream && (
                    <div className="absolute top-8 right-8 w-80 h-60 rounded-3xl overflow-hidden border-4 border-white/30 shadow-2xl backdrop-blur-sm">
                        <video
                            ref={localVideoRef}
                            autoPlay
                            playsInline
                            muted
                            className="w-full h-full object-cover"
                        />
                    </div>
                )}

                {/* 통화 상태 표시 (상단 좌측) */}
                {callState === 'connected' && (
                    <div className="absolute top-8 left-8 bg-black/50 backdrop-blur-md px-6 py-3 rounded-full">
                        <div className="flex items-center gap-3">
                            <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse" />
                            <span className="text-white text-lg font-medium">통화 중</span>
                        </div>
                    </div>
                )}
            </div>

            {/* 컨트롤 바 - 하단 중앙 */}
            <div className="bg-gradient-to-t from-black/90 to-transparent px-12 py-10">
                <div className="flex items-center justify-center gap-12">
                    {/* 마이크 토글 */}
                    <button
                        onClick={toggleMic}
                        className={`w-28 h-28 rounded-full flex items-center justify-center text-5xl transition-all transform hover:scale-105 active:scale-95 ${
                            isMicOn
                                ? 'bg-gray-700/80 backdrop-blur-md text-white hover:bg-gray-600/80 shadow-xl'
                                : 'bg-red-500 text-white hover:bg-red-400 shadow-xl shadow-red-500/50'
                        }`}
                        aria-label={isMicOn ? '마이크 끄기' : '마이크 켜기'}
                    >
                        {isMicOn ? '🎤' : '🔇'}
                    </button>

                    {/* 통화 종료 - 더 크게 강조 */}
                    <button
                        onClick={endCall}
                        className="w-32 h-32 rounded-full bg-red-600 text-white flex items-center justify-center text-6xl hover:bg-red-500 active:scale-95 transition-all transform hover:scale-105 shadow-2xl shadow-red-600/50"
                        aria-label="통화 종료"
                    >
                        📵
                    </button>

                    {/* 카메라 토글 */}
                    <button
                        onClick={toggleCamera}
                        className={`w-28 h-28 rounded-full flex items-center justify-center text-5xl transition-all transform hover:scale-105 active:scale-95 ${
                            isCameraOn
                                ? 'bg-gray-700/80 backdrop-blur-md text-white hover:bg-gray-600/80 shadow-xl'
                                : 'bg-red-500 text-white hover:bg-red-400 shadow-xl shadow-red-500/50'
                        }`}
                        aria-label={isCameraOn ? '카메라 끄기' : '카메라 켜기'}
                    >
                        {isCameraOn ? '📹' : '🚫'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default VideoCallOverlay;
