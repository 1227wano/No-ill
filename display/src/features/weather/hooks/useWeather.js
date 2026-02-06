import { useState, useEffect } from 'react';
import axios from 'axios';
import client from '../../../api/client';

const useWeather = (refreshInterval = 30 * 60 * 1000) => {
    const [weather, setWeather] = useState(null);
    const [airQuality, setAirQuality] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchData = async () => {
        try {
            setError(null);

            // 백엔드 API 호출
            const response = await client.get('/api/weather/today');
            const data = response.data;

            // 데이터 유효성 검사 및 변환
            const temp = parseFloat(data.temperature);
            const humidity = parseInt(data.humidity);

            // NaN 체크
            if (isNaN(temp) || isNaN(humidity)) {
                console.error('기상 데이터가 잘못되었습니다:', { temperature: data.temperature, humidity: data.humidity });
                throw new Error('기상 데이터 형식 오류');
            }

            setWeather({
                temp: Math.round(temp),
                humidity: humidity,
            });

            // PM10 값을 등급으로 변환
            const pm10Value = data.pm10 !== null && data.pm10 !== undefined ? parseInt(data.pm10) : null;
            if (isNaN(pm10Value)) {
                console.error('PM10 데이터가 잘못되었습니다:', data.pm10);
                // PM10 데이터가 없거나 잘못된 경우, 기본값으로 설정
                setAirQuality({
                    pm10: null,
                    text: '알수없음',
                    colorClass: 'text-gray-500',
                });
            } else {
                const gradeText = {
                    '1': '좋음',
                    '2': '보통',
                    '3': '나쁨',
                    '4': '매우나쁨'
                };
                const grade = gradeText[getGradeByPm10(pm10Value)] || '알수없음';

                setAirQuality({
                    pm10: data.pm10,
                    text: grade,
                    colorClass: getAirQualityColorByGrade(grade),
                });
            }
        } catch (err) {
            console.error('날씨 정보 조회 실패:', err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    // PM10 수치를 등급으로 변환하는 함수 추가
    const getGradeByPm10 = (pm10Value) => {
        if (pm10Value <= 30) return '1';
        if (pm10Value <= 80) return '2';
        if (pm10Value <= 150) return '3';
        return '4';
    };

    // 기존의 등급 텍스트에 따른 색상 클래스 함수는 그대로 유지
    const getAirQualityColorByGrade = (grade) => {
        if (grade === '좋음') return 'text-green-500';
        if (grade === '보통') return 'text-yellow-500';
        if (grade === '나쁨') return 'text-orange-500';
        if (grade === '매우나쁨') return 'text-red-500';
        return 'text-gray-500';
    };

    useEffect(() => {
        fetchData();

        const interval = setInterval(fetchData, refreshInterval);
        return () => clearInterval(interval);
    }, [refreshInterval]);

    return { weather, airQuality, loading, error, refetch: fetchData };
};

export default useWeather;