import axios from 'axios';
// db(서버)와 직접 통신하는 서비스 파일
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;

// 1. 일정 목록 조회
export const fetchSchedules = async () => {
  try {
    const response = await axios.get(`${API_BASE_URL}/api/schedules`);
    return response.data;
  } catch (error) {
    console.error('데이터 로드 실패:', error);
    throw error;
  }
};

// 2. 일정 저장 (등록)
export const saveSchedule = async (scheduleData) => {
  try {
    const response = await axios.post(`${API_BASE_URL}/api/schedules`, scheduleData);
    return response.data;
  } catch (error) {
    console.error('저장 중 오류 발생:', error);
    throw error;
  }
};

// 3. 일정 수정
export const updateSchedule = async (id, scheduleData) => {
  try {
    const response = await axios.put(`${API_BASE_URL}/api/schedules/${id}`, scheduleData);
    return response.data;
  } catch (error) {
    console.error('수정 중 오류 발생:', error);
    throw error;
  }
};

// 4. 일정 삭제
export const deleteSchedule = async (id) => {
  try {
    const response = await axios.delete(`${API_BASE_URL}/api/schedules/${id}`);
    return response.data;
  } catch (error) {
    console.error('삭제 중 오류 발생:', error);
    throw error;
  }
};