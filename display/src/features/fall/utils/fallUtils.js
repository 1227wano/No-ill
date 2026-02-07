// src/features/fall/utils/fallUtils.js

/**
 * 날짜/시간 포맷팅
 * @param {string} dateTimeStr - ISO 날짜 문자열
 * @returns {string} 포맷된 시간
 */
export const formatFallTime = (dateTimeStr) => {
    if (!dateTimeStr) return '알 수 없음';

    try {
        const date = new Date(dateTimeStr);
        return date.toLocaleTimeString('ko-KR', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
        });
    } catch (error) {
        console.error('시간 포맷 오류:', error);
        return '알 수 없음';
    }
};

/**
 * 신뢰도 포맷팅
 * @param {number} confidence - 0~1 사이의 값
 * @returns {string}
 */
export const formatConfidence = (confidence) => {
    if (confidence == null || isNaN(confidence)) return '-';
    return `${Math.round(confidence * 100)}%`;
};

/**
 * Base64 이미지 URL 생성
 * @param {string} base64Data
 * @returns {string}
 */
export const getImageDataUrl = (base64Data) => {
    if (!base64Data) return null;
    return `data:image/jpeg;base64,${base64Data}`;
};
