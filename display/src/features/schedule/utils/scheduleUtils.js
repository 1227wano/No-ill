// src/features/schedule/utils/scheduleUtils.js

/**
 * 오늘 날짜의 일정만 필터링
 * @param {Array} schedules - 일정 목록
 * @returns {Array}
 */
export const filterTodaySchedules = (schedules) => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return schedules.filter((item) => {
        if (!item.schTime) return false;

        const itemDate = new Date(item.schTime);
        itemDate.setHours(0, 0, 0, 0);

        return itemDate.getTime() === today.getTime();
    });
};

/**
 * 시간 포맷팅 (HH:mm)
 * @param {string} schTime - ISO 시간 문자열
 * @returns {string}
 */
export const formatScheduleTime = (schTime) => {
    if (!schTime) return '';
    return schTime.split('T')[1]?.substring(0, 5) || '';
};

/**
 * 일정이 과거인지 확인
 * @param {string} schTime - ISO 시간 문자열
 * @returns {boolean}
 */
export const isPastSchedule = (schTime) => {
    if (!schTime) return false;
    const now = new Date();
    const scheduleDate = new Date(schTime);
    return scheduleDate < now;
};
