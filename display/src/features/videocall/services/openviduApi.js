// src/features/videocall/services/openviduApi.js

import client from '../../../api/client';

// ==================== 상수 ====================

const OPENVIDU_TIMEOUT = 10000; // 10초
const MAX_RETRIES = 2; // 최대 재시도 횟수

// ==================== 유틸 함수 ====================

/**
 * OpenVidu API 응답 변환 함수
 * 서버가 문자열 또는 JSON 객체를 반환할 수 있으므로 정규화
 * @param {string|Object} data - 응답 데이터
 * @returns {string|Object} 정제된 데이터
 */
const transformOpenViduResponse = (data) => {
    // 이미 객체면 그대로 반환
    if (typeof data === 'object' && data !== null) {
        return data.sessionId || data.token || data;
    }

    // 문자열 처리
    if (typeof data === 'string') {
        // 따옴표 제거
        const cleaned = data.trim().replace(/^"|"$/g, '');

        // JSON 파싱 시도
        try {
            const parsed = JSON.parse(cleaned);
            return parsed.sessionId || parsed.token || parsed;
        } catch {
            return cleaned;
        }
    }

    return data;
};

/**
 * OpenVidu sessionId 유효성 검증
 * @param {string} sessionId
 * @throws {Error} 유효하지 않으면 에러
 */
const validateSessionId = (sessionId) => {
    if (!sessionId || typeof sessionId !== 'string') {
        throw new Error('유효하지 않은 세션 ID입니다.');
    }

    if (sessionId.length < 5) {
        throw new Error('세션 ID가 너무 짧습니다.');
    }
};

/**
 * OpenVidu API 공통 요청 헬퍼 (재시도 포함)
 * @param {string} method - HTTP 메서드
 * @param {string} url - API URL
 * @param {Object} data - 요청 데이터
 * @param {boolean} transformResponse - 응답 변환 여부
 * @param {number} retryCount - 현재 재시도 횟수
 * @returns {Promise<any>}
 */
const openviduRequest = async (
    method,
    url,
    data = {},
    transformResponse = false,
    retryCount = 0
) => {
    const config = {
        method,
        url,
        data,
        timeout: OPENVIDU_TIMEOUT,
    };

    if (transformResponse) {
        config.transformResponse = [transformOpenViduResponse];
    }

    try {
        console.log(`📤 ${method.toUpperCase()} ${url}`, data);

        const response = await client.request(config);

        console.log(`📥 ${method.toUpperCase()} ${url} response:`, response.data);
        return response.data;
    } catch (error) {
        const errorMsg = error.response?.data?.message || error.message;
        console.error(`❌ ${method.toUpperCase()} ${url} error:`, errorMsg);

        // 재시도 가능한 에러 (네트워크, 타임아웃)
        const isRetryable =
            error.code === 'ECONNABORTED' ||
            error.code === 'ETIMEDOUT' ||
            error.response?.status >= 500;

        if (isRetryable && retryCount < MAX_RETRIES) {
            console.log(`🔄 재시도 ${retryCount + 1}/${MAX_RETRIES}...`);
            await new Promise((resolve) => setTimeout(resolve, 1000)); // 1초 대기
            return openviduRequest(method, url, data, transformResponse, retryCount + 1);
        }

        // 사용자 친화적 에러 메시지
        const userMessage = getUserFriendlyError(error);
        const enhancedError = new Error(userMessage);
        enhancedError.originalError = error;
        throw enhancedError;
    }
};

/**
 * 사용자 친화적 에러 메시지 생성
 * @param {Error} error
 * @returns {string}
 */
const getUserFriendlyError = (error) => {
    if (error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT') {
        return '서버 응답 시간이 초과되었습니다. 다시 시도해주세요.';
    }

    if (!error.response) {
        return '네트워크 연결을 확인해주세요.';
    }

    const status = error.response.status;

    switch (status) {
        case 400:
            return '잘못된 요청입니다.';
        case 401:
            return '인증이 필요합니다. 다시 로그인해주세요.';
        case 403:
            return '접근 권한이 없습니다.';
        case 404:
            return '요청한 리소스를 찾을 수 없습니다.';
        case 409:
            return '이미 존재하는 세션입니다.';
        case 500:
        case 502:
        case 503:
            return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
        default:
            return error.response.data?.message || '요청 처리 중 오류가 발생했습니다.';
    }
};

// ==================== API 함수 ====================

/**
 * OpenVidu 세션 생성
 * @returns {Promise<string>} 세션 ID
 */
export const createSession = async () => {
    try {
        const sessionId = await openviduRequest('post', '/api/openvidu/sessions', {}, true);
        validateSessionId(sessionId);
        return sessionId;
    } catch (error) {
        console.error('❌ 세션 생성 실패:', error.message);
        throw error;
    }
};

/**
 * OpenVidu 연결(토큰) 생성
 * @param {string} sessionId - 세션 ID
 * @returns {Promise<string>} 연결 토큰
 */
export const createConnection = async (sessionId) => {
    if (!sessionId) {
        throw new Error('세션 ID가 필요합니다.');
    }

    validateSessionId(sessionId);

    try {
        const token = await openviduRequest(
            'post',
            `/api/openvidu/sessions/${sessionId}/connections`,
            {},
            true
        );

        if (!token || typeof token !== 'string') {
            throw new Error('유효하지 않은 토큰입니다.');
        }

        return token;
    } catch (error) {
        console.error('❌ 연결 생성 실패:', error.message);
        throw error;
    }
};

/**
 * 사용자에게 전화 걸기
 * @param {string|number} userId - 사용자 ID
 * @param {string} sessionId - 세션 ID
 * @returns {Promise<Object>}
 */
export const callUser = async (userId, sessionId) => {
    if (!userId) {
        throw new Error('사용자 ID가 필요합니다.');
    }

    if (!sessionId) {
        throw new Error('세션 ID가 필요합니다.');
    }

    validateSessionId(sessionId);

    try {
        return await openviduRequest('post', '/api/openvidu/call/user', {
            userId: String(userId),
            sessionId,
        });
    } catch (error) {
        console.error('❌ 사용자 호출 실패:', error.message);
        throw error;
    }
};

/**
 * 펫(디스플레이)에게 전화 걸기
 * @param {string} petId - 펫 ID
 * @param {string} sessionId - 세션 ID
 * @returns {Promise<Object>}
 */
export const callPet = async (petId, sessionId) => {
    if (!petId) {
        throw new Error('펫 ID가 필요합니다.');
    }

    if (!sessionId) {
        throw new Error('세션 ID가 필요합니다.');
    }

    validateSessionId(sessionId);

    try {
        return await openviduRequest('post', '/api/openvidu/call/pet', {
            petId: String(petId),
            sessionId,
        });
    } catch (error) {
        console.error('❌ 펫 호출 실패:', error.message);
        throw error;
    }
};

/**
 * 펫의 모든 사용자에게 전화 걸기
 * @param {string} sessionId - 세션 ID
 * @returns {Promise<Object>}
 */
export const callUsersByPet = async (sessionId) => {
    if (!sessionId) {
        throw new Error('세션 ID가 필요합니다.');
    }

    validateSessionId(sessionId);

    try {
        return await openviduRequest('post', '/api/openvidu/call/users-by-pet', {
            sessionId,
        });
    } catch (error) {
        console.error('❌ 보호자 호출 실패:', error.message);
        throw error;
    }
};

// ==================== Export ====================

export const openviduApi = {
    createSession,
    createConnection,
    callUser,
    callPet,
    callUsersByPet,
};

export default openviduApi;
