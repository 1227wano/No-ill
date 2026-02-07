// src/features/schedule/utils/timeUtils.js

/**
 * 현재 시간 기준 다음 30분 단위 시간 계산
 * @returns {{hour: string, minute: string}}
 */
export const getNextAvailableTime = () => {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    let hour = currentHour;
    let minute = currentMinute < 30 ? '30' : '00';

    if (currentMinute >= 30) {
        hour = (hour + 1) % 24;
    }

    return {
        hour: String(hour).padStart(2, '0'),
        minute,
    };
};

/**
 * schTime 포맷에서 시간 추출
 * @param {string} schTime - "2024-01-01T12:30:00" 형식
 * @returns {{hour: string, minute: string}}
 */
export const parseScheduleTime = (schTime) => {
    if (!schTime) {
        return getNextAvailableTime();
    }

    const timeString = schTime.split('T')[1] || '12:00';
    const [h, m] = timeString.split(':');

    return {
        hour: h,
        minute: m.substring(0, 2),
    };
};

/**
 * 시간이 과거인지 확인
 * @param {string} hour
 * @param {string} minute
 * @returns {boolean}
 */
export const isPastTime = (hour, minute) => {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    const selectedHour = parseInt(hour);
    const selectedMinute = parseInt(minute);

    if (selectedHour < currentHour) return true;
    if (selectedHour === currentHour && selectedMinute <= currentMinute) return true;

    return false;
};
