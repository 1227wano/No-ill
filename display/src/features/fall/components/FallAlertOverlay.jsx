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
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-red-600">
            <div className="w-full max-w-2xl mx-4 p-8 bg-white rounded-3xl shadow-2xl">
                {/* 헤더 */}
                <div className="text-center mb-6">
                    <div className="inline-flex items-center justify-center w-20 h-20 bg-red-100 rounded-full mb-4">
                        <svg
                            className="w-12 h-12 text-red-600 animate-pulse"
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
                    <h1 className="text-4xl font-bold text-red-600 mb-2">
                        낙상 감지!
                    </h1>
                    <p className="text-xl text-gray-700">
                        {fallAlert.message || '낙상이 감지되었습니다!'}
                    </p>
                </div>

                {/* 이미지 */}
                {fallAlert.imageBase64 && (
                    <div className="mb-6 rounded-2xl overflow-hidden border-4 border-red-200">
                        <img
                            src={`data:image/jpeg;base64,${fallAlert.imageBase64}`}
                            alt="낙상 감지 이미지"
                            className="w-full h-64 object-cover"
                        />
                    </div>
                )}

                {/* 상세 정보 */}
                <div className="grid grid-cols-3 gap-4 mb-8 text-center">
                    <div className="bg-gray-100 rounded-xl p-4">
                        <p className="text-sm text-gray-500">감지 시간</p>
                        <p className="text-lg font-semibold text-gray-800">
                            {formatTime(fallAlert.detectedAt)}
                        </p>
                    </div>
                    <div className="bg-gray-100 rounded-xl p-4">
                        <p className="text-sm text-gray-500">위치</p>
                        <p className="text-lg font-semibold text-gray-800">
                            {fallAlert.location || '알 수 없음'}
                        </p>
                    </div>
                    <div className="bg-gray-100 rounded-xl p-4">
                        <p className="text-sm text-gray-500">신뢰도</p>
                        <p className="text-lg font-semibold text-gray-800">
                            {fallAlert.confidence
                                ? `${Math.round(fallAlert.confidence * 100)}%`
                                : '-'}
                        </p>
                    </div>
                </div>

                {/* 버튼 */}
                <div className="grid grid-cols-2 gap-4">
                    <button
                        onClick={handleEmergencyCall}
                        className="py-6 px-8 bg-red-600 text-white text-2xl font-bold rounded-2xl hover:bg-red-700 active:bg-red-800 transition-colors shadow-lg"
                    >
                        119 신고
                    </button>
                    <button
                        onClick={dismissAlert}
                        className="py-6 px-8 bg-green-500 text-white text-2xl font-bold rounded-2xl hover:bg-green-600 active:bg-green-700 transition-colors shadow-lg"
                    >
                        괜찮아요
                    </button>
                </div>
            </div>
        </div>
    );
};

export default FallAlertOverlay;
