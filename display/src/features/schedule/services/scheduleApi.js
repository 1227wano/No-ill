import client from '../../../api/client';

// 1. 일정 목록 조회
export const fetchSchedules = async () => {
  try {
    const response = await client.get('/api/schedules/pets');
    return response.data;
  } catch (error) {
    console.error('데이터 로드 실패:', error);
    throw error;
  }
};

// 2. 일정 저장 (등록)
export const saveSchedule = async (scheduleData) => {
  try {
    const response = await client.post('/api/schedules/pets', scheduleData);
    return response.data;
  } catch (error) {
    console.error('저장 중 오류 발생:', error);
    throw error;
  }
};

// 3. 일정 수정
export const updateSchedule = async (id, scheduleData) => {
  try {
    const response = await client.put(`/api/schedules/pets/${id}`, scheduleData);
    return response.data;
  } catch (error) {
    console.error('수정 중 오류 발생:', error);
    throw error;
  }
};

// 4. 일정 삭제
export const deleteSchedule = async (id) => {
  try {
    const response = await client.delete(`/api/schedules/pets/${id}`);
    return response.data;
  } catch (error) {
    console.error('삭제 중 오류 발생:', error);
    throw error;
  }
};