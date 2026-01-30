import React from 'react';
import useFallAlert from '../hooks/useFallAlert';

const FallAlertOverlay = () => {
    const { fallAlert, dismissAlert } = useFallAlert();

    if (!fallAlert) {
        return null;
    }

    const formatTime = (dateTimeStr) => {
        if (!dateTimeStr) return '';
        const date = new Date(dateTimeStr);
        return date.toLocaleTimeString('ko-KR', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        });
    };

    const handleEmergencyCall = () => {
        window.location.href = 'tel:119';
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-danger">
            <div className="w-full max-w-2xl mx-4 p-10 bg-surface rounded-card shadow-card">
                {/* 헤더 */}
                <div className="text-center mb-8">
                    <div className="inline-flex items-center justify-center w-24 h-24 bg-danger/10 rounded-full mb-6">
                        <svg
                            className="w-14 h-14 text-danger animate-pulse"
                            fill="none"
                            stroke="currentColor"
                            viewBox="0 0 24 24"
                        >
                            <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth={2}
                                d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                            />
                        </svg>
                    </div>
                    <h1 className="text-5xl font-bold text-danger mb-4">
                        낙상 감지!
                    </h1>
                    <p className="text-2xl text-text-main font-medium">
                        {fallAlert.message || '낙상이 감지되었습니다!'}
                    </p>
                </div>

                {/* 이미지 */}
                {fallAlert.imageBase64 && (
                    <div className="mb-8 rounded-card overflow-hidden border-4 border-danger/30">
                        <img
                            src={`data:image/jpeg;base64,${fallAlert.imageBase64}`}
                            alt="낙상 감지 이미지"
                            className="w-full h-72 object-cover"
                        />
                    </div>
                )}

                {/* 상세 정보 */}
                <div className="grid grid-cols-3 gap-4 mb-8 text-center">
                    <div className="bg-background rounded-card p-5">
                        <p className="text-body text-text-body mb-1">감지 시간</p>
                        <p className="text-xl font-bold text-text-main">
                            {formatTime(fallAlert.detectedAt)}
                        </p>
                    </div>
                    <div className="bg-background rounded-card p-5">
                        <p className="text-body text-text-body mb-1">위치</p>
                        <p className="text-xl font-bold text-text-main">
                            {fallAlert.location || '알 수 없음'}
                        </p>
                    </div>
                    <div className="bg-background rounded-card p-5">
                        <p className="text-body text-text-body mb-1">신뢰도</p>
                        <p className="text-xl font-bold text-text-main">
                            {fallAlert.confidence
                                ? `${Math.round(fallAlert.confidence * 100)}%`
                                : '-'}
                        </p>
                    </div>
                </div>

                {/* 버튼 */}
                <div className="grid grid-cols-2 gap-6">
                    <button
                        onClick={handleEmergencyCall}
                        className="py-6 px-8 bg-danger text-white text-3xl font-bold rounded-button hover:bg-danger/90 active:scale-[0.98] transition-all shadow-card"
                    >
                        🚨 119 신고
                    </button>
                    <button
                        onClick={dismissAlert}
                        className="py-6 px-8 bg-primary text-white text-3xl font-bold rounded-button hover:bg-primary/90 active:scale-[0.98] transition-all shadow-card"
                    >
                        ✓ 괜찮아요
                    </button>
                </div>
            </div>
        </div>
    );
};

export default FallAlertOverlay;
