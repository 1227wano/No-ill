// src/features/fall/components/FallAlertOverlay.jsx

import React, { useEffect, useCallback } from 'react';
import useFallAlert from '../hooks/useFallAlert';
import AlertIcon from './AlertIcon';
import AlertImage from './AlertImage';
import AlertInfoCard from './AlertInfoCard';
import { formatFallTime, formatConfidence } from '../utils/fallUtils';

const FallAlertOverlay = () => {
    const { fallAlert, dismissAlert } = useFallAlert();

    // ESC 키로 닫기
    useEffect(() => {
        const handleKeyDown = (e) => {
            if (e.key === 'Escape') {
                dismissAlert();
            }
        };

        if (fallAlert) {
            window.addEventListener('keydown', handleKeyDown);
        }

        return () => {
            window.removeEventListener('keydown', handleKeyDown);
        };
    }, [fallAlert, dismissAlert]);

    const handleEmergencyCall = useCallback(() => {
        const confirmed = window.confirm(
            '119에 신고하시겠습니까?\n\n전화 앱이 실행됩니다.'
        );

        if (confirmed) {
            window.location.href = 'tel:119';
        }
    }, []);

    if (!fallAlert) {
        return null;
    }

    return (
        <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-danger"
            role="alertdialog"
            aria-modal="true"
            aria-labelledby="alert-title"
            aria-describedby="alert-description"
        >
            <div className="w-full max-w-2xl mx-4 p-10 bg-surface rounded-card shadow-card">
                {/* 헤더 */}
                <div className="text-center mb-8">
                    <AlertIcon />

                    <h1
                        id="alert-title"
                        className="text-5xl font-bold text-danger mb-4"
                    >
                        낙상 감지!
                    </h1>

                    <p
                        id="alert-description"
                        className="text-2xl text-text-main font-medium"
                    >
                        {fallAlert.message || '낙상이 감지되었습니다!'}
                    </p>
                </div>

                {/* 이미지 */}
                <AlertImage imageBase64={fallAlert.imageBase64} />

                {/* 상세 정보 */}
                <div
                    className="grid grid-cols-3 gap-4 mb-8 text-center"
                    role="region"
                    aria-label="낙상 상세 정보"
                >
                    <AlertInfoCard
                        label="감지 시간"
                        value={formatFallTime(fallAlert.detectedAt)}
                    />
                    <AlertInfoCard
                        label="위치"
                        value={fallAlert.location || '알 수 없음'}
                    />
                    <AlertInfoCard
                        label="신뢰도"
                        value={formatConfidence(fallAlert.confidence)}
                    />
                </div>

                {/* 버튼 */}
                <div className="grid grid-cols-2 gap-6">
                    <button
                        onClick={handleEmergencyCall}
                        className="py-6 px-8 bg-danger text-white text-3xl font-bold rounded-button hover:bg-danger/90 active:scale-[0.98] transition-all shadow-card"
                        aria-label="119에 긴급 신고"
                    >
                        🚨 119 신고
                    </button>
                    <button
                        onClick={dismissAlert}
                        className="py-6 px-8 bg-primary text-white text-3xl font-bold rounded-button hover:bg-primary/90 active:scale-[0.98] transition-all shadow-card"
                        aria-label="알림 닫기"
                    >
                        ✓ 괜찮아요
                    </button>
                </div>

                {/* 키보드 안내 */}
                <p className="text-center text-text-body mt-6 text-lg">
                    ESC 키를 눌러 닫을 수 있습니다
                </p>
            </div>
        </div>
    );
};

export default FallAlertOverlay;
