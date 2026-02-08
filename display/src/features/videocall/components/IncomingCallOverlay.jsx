// src/features/videocall/components/IncomingCallOverlay.jsx

import React, { useEffect } from 'react';
import useVideoCall from '../hooks/useVideoCall';
import { CALL_STATE } from '../constants/callConstants';

const IncomingCallOverlay = () => {
    const { callState, incomingCall, acceptCall, rejectCall } = useVideoCall();

    // 키보드 지원
    useEffect(() => {
        if (callState !== CALL_STATE.RINGING) return;

        const handleKeyDown = (e) => {
            if (e.key === 'Enter') {
                acceptCall();
            } else if (e.key === 'Escape') {
                rejectCall();
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [callState, acceptCall, rejectCall]);

    if (callState !== CALL_STATE.RINGING || !incomingCall) {
        return null;
    }

    return (
        <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/80"
            role="alertdialog"
            aria-modal="true"
            aria-labelledby="incoming-call-title"
            aria-describedby="incoming-call-description"
        >
            <div className="w-full max-w-lg mx-4 p-10 bg-surface rounded-card shadow-card text-center">
                {/* 벨 아이콘 */}
                <div className="mb-8" role="img" aria-label="전화벨">
                    <span className="inline-block text-8xl animate-bounce">📞</span>
                </div>

                {/* 발신자 정보 */}
                <h2 id="incoming-call-title" className="text-4xl font-bold text-text-main mb-4">
                    영상 통화
                </h2>
                <p id="incoming-call-description" className="text-2xl text-text-body mb-12">
                    {incomingCall.callerName || '보호자'}님이 전화를 걸고 있습니다
                </p>

                {/* 수락/거절 버튼 */}
                <div className="grid grid-cols-2 gap-6">
                    <button
                        onClick={rejectCall}
                        className="py-8 px-6 bg-danger text-white text-3xl font-bold rounded-button hover:bg-danger/90 active:scale-[0.98] transition-all shadow-card"
                        aria-label="전화 거절 (ESC)"
                    >
                        거절
                    </button>
                    <button
                        onClick={acceptCall}
                        className="py-8 px-6 bg-green-500 text-white text-3xl font-bold rounded-button hover:bg-green-600 active:scale-[0.98] transition-all shadow-card"
                        aria-label="전화 수락 (Enter)"
                        autoFocus
                    >
                        수락
                    </button>
                </div>

                {/* 키보드 안내 */}
                <p className="text-center text-text-body mt-6 text-lg">
                    Enter: 수락 | ESC: 거절
                </p>
            </div>
        </div>
    );
};

export default IncomingCallOverlay;
