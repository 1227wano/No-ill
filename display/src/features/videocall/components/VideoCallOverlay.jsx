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
                    <div className="w-full h-full flex items-center justify-center bg-gray-900">
                        <div className="text-center">
                            <div className="text-8xl mb-6">📞</div>
                            <p className="text-white text-3xl font-bold">
                                {statusText[callState] || '연결 중...'}
                            </p>
                            {callState === 'calling' && (
                                <div className="mt-6 flex justify-center gap-2">
                                    <span className="w-3 h-3 bg-white rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                                    <span className="w-3 h-3 bg-white rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                                    <span className="w-3 h-3 bg-white rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
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
                        />
                    </div>
                )}
            </div>

            {/* 컨트롤 바 */}
            <div className="bg-gray-900/90 px-8 py-6">
                <div className="flex items-center justify-center gap-8">
                    {/* 마이크 토글 */}
                    <button
                        onClick={toggleMic}
                        className={`w-20 h-20 rounded-full flex items-center justify-center text-4xl transition-all ${
                            isMicOn
                                ? 'bg-gray-700 text-white hover:bg-gray-600'
                                : 'bg-red-500 text-white hover:bg-red-400'
                        }`}
                    >
                        {isMicOn ? '🎤' : '🔇'}
                    </button>

                    {/* 통화 종료 */}
                    <button
                        onClick={endCall}
                        className="w-24 h-24 rounded-full bg-danger text-white flex items-center justify-center text-5xl hover:bg-danger/80 active:scale-95 transition-all shadow-lg"
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
                    >
                        {isCameraOn ? '📹' : '🚫'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default VideoCallOverlay;
