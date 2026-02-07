// src/features/schedule/services/scheduleApi.js

import client from '../../../api/client';

// ==================== API 함수 ====================

/**
 * 일정 목록 조회
 * @returns {Promise<Array>} 일정 목록
 */
const fetchSchedules = async () => {
    try {
        const response = await client.get('/api/schedules/pets');
        return response.data;
    } catch (error) {
        console.error('일정 목록 조회 실패:', error);
        throw new Error('일정을 불러올 수 없습니다.');
    }
};


/**
 * 일정 저장 (등록)
 * @param {Object} scheduleData - 일정 데이터
 * @param {string} scheduleData.title - 일정 제목
 * @param {string} scheduleData.date - 일정 날짜 (YYYY-MM-DD)
 * @param {string} scheduleData.time - 일정 시간 (HH:mm)
 * @param {string} [scheduleData.description] - 일정 설명
 * @returns {Promise<Object>} 생성된 일정
 */
const saveSchedule = async (scheduleData) => {
    try {
        const response = await client.post('/api/schedules/pets', scheduleData);
        return response.data;
    } catch (error) {
        console.error('일정 저장 실패:', error);
        throw new Error('일정을 저장할 수 없습니다.');
    }
};

/**
 * 일정 수정
 * @param {number|string} id - 일정 ID
 * @param {Object} scheduleData - 수정할 일정 데이터
 * @returns {Promise<Object>} 수정된 일정
 */
const updateSchedule = async (id, scheduleData) => {
    try {
        const response = await client.put(`/api/schedules/pets/${id}`, scheduleData);
        return response.data;
    } catch (error) {
        console.error('일정 수정 실패:', error);
        throw new Error('일정을 수정할 수 없습니다.');
    }
};

/**
 * 일정 삭제
 * @param {number|string} id - 일정 ID
 * @returns {Promise<Object>} 삭제 결과
 */
const deleteSchedule = async (id) => {
    try {
        const response = await client.delete(`/api/schedules/pets/${id}`);
        return response.data;
    } catch (error) {
        console.error('일정 삭제 실패:', error);
        throw new Error('일정을 삭제할 수 없습니다.');
    }
};

// ==================== Export ====================

export const scheduleApi = {
    fetchSchedules,
    saveSchedule,
    updateSchedule,
    deleteSchedule,
};

// Named export
export { fetchSchedules, saveSchedule, updateSchedule, deleteSchedule };