// src/features/weather/services/weatherApi.js

import client from '../../../api/client';

// PM10 등급 기준
const PM10_GRADES = {
    1: {text: '좋음', max: 30, color: 'text-green-500'},
    2: {text: '보통', max: 80, color: 'text-yellow-500'},
    3: {text: '나쁨', max: 150, color: 'text-orange-500'},
    4: {text: '매우나쁨', max: Infinity, color: 'text-red-500'},
};

// ==================== 유틸 함수 ====================

/**
 * PM10 수치를 등급 번호로 변환
 * @param {number} pm10Value - PM10 수치
 * @returns {string} 등급 번호 ('1' | '2' | '3' | '4')
 */
export const getGradeByPm10 = (pm10Value) => {
    const value = parseInt(pm10Value);

    if (isNaN(value) || value < 0) return null;
    if (value <= 30) return '1';
    if (value <= 80) return '2';
    if (value <= 150) return '3';
    return '4';
};

/**
 * PM10 수치를 등급 정보로 변환
 * @param {number|string|null} pm10Value - PM10 수치
 * @returns {{pm10: number|null, text: string, colorClass: string}}
 */
export const parseAirQuality = (pm10Value) => {
    // null/undefined 처리
    if (pm10Value === null || pm10Value === undefined) {
        return {
            pm10: null,
            text: '알수없음',
            colorClass: 'text-gray-500',
        };
    }

    const value = parseInt(pm10Value);

    // 잘못된 값 처리
    if (isNaN(value) || value < 0) {
        console.warn('잘못된 PM10 값:', pm10Value);
        return {
            pm10: null,
            text: '알수없음',
            colorClass: 'text-gray-500',
        };
    }

    const gradeKey = getGradeByPm10(value);
    const grade = PM10_GRADES[gradeKey];

    return {
        pm10: value,
        text: grade.text,
        colorClass: grade.color,
    };
};

/**
 * 기상 데이터 파싱 및 검증
 * @param {Object} data - 백엔드 응답 데이터
 * @returns {{temp: number, humidity: number}}
 */
export const parseWeatherData = (data) => {
    const temp = parseFloat(data.temperature);
    const humidity = parseInt(data.humidity);

    // 유효성 검증
    if (isNaN(temp)) {
        throw new Error(`잘못된 온도 값: ${data.temperature}`);
    }

    if (isNaN(humidity)) {
        throw new Error(`잘못된 습도 값: ${data.humidity}`);
    }

    return {
        temp: Math.round(temp),
        humidity: humidity,
    };
};

// ==================== API 함수 ====================

/**
 * 오늘의 날씨 정보 조회
 * @returns {Promise<{weather: Object, airQuality: Object}>}
 */
export const fetchTodayWeather = async () => {
    const response = await client.get('/api/weather/today');
    const data = response.data;

    return {
        weather: parseWeatherData(data),
        airQuality: parseAirQuality(data.pm10),
    };
};

// ==================== Export ====================

export const weatherApi = {
    fetchTodayWeather,
};

export const weatherUtils = {
    getGradeByPm10,
    parseAirQuality,
    parseWeatherData,
};