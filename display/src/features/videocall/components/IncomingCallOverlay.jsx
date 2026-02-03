import React from 'react';
import useVideoCall from '../hooks/useVideoCall';

const IncomingCallOverlay = () => {
    const { callState, incomingCall, acceptCall, rejectCall } = useVideoCall();

    if (callState !== 'ringing' || !incomingCall) {
        return null;
    }

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80">
            <div className="w-full max-w-lg mx-4 p-10 bg-surface rounded-card shadow-card text-center">
                {/* 벨 아이콘 */}
                <div className="mb-8">
                    <span className="inline-block text-8xl animate-bounce">
                        📞
                    </span>
                </div>

                {/* 발신자 정보 */}
                <h2 className="text-4xl font-bold text-text-main mb-4">
                    영상 통화
                </h2>
                <p className="text-2xl text-text-body mb-12">
                    {incomingCall.callerName || '보호자'}님이 전화를 걸고 있습니다
                </p>

                {/* 수락/거절 버튼 */}
                <div className="grid grid-cols-2 gap-6">
                    <button
                        onClick={rejectCall}
                        className="py-8 px-6 bg-danger text-white text-3xl font-bold rounded-button hover:bg-danger/90 active:scale-[0.98] transition-all shadow-card"
                    >
                        거절
                    </button>
                    <button
                        onClick={acceptCall}
                        className="py-8 px-6 bg-green-500 text-white text-3xl font-bold rounded-button hover:bg-green-600 active:scale-[0.98] transition-all shadow-card"
                    >
                        수락
                    </button>
                </div>
            </div>
        </div>
    );
};

export default IncomingCallOverlay;
