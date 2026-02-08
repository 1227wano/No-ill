// src/features/weather/hooks/useWeather.js

import {useState, useEffect, useCallback, useRef} from 'react';
import {weatherApi} from '../services/weatherApi';

const DEFAULT_REFRESH_INTERVAL = 30 * 60 * 1000; // 30분

const useWeather = (refreshInterval = DEFAULT_REFRESH_INTERVAL) => {
    const [weather, setWeather] = useState(null);
    const [airQuality, setAirQuality] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);


    // interval 참조 저장
    const intervalRef = useRef(null);

    const fetchData = useCallback(async () => {
        try {
            setError(null);

            const {weather: weatherData, airQuality: airQualityData} =
                await weatherApi.fetchTodayWeather();

            setWeather(weatherData);
            setAirQuality(airQualityData);
        } catch (err) {
            console.error('날씨 정보 조회 실패:', err);
            setError(err.message || '날씨 정보를 가져올 수 없습니다.');
        } finally {
            setLoading(false);
        }
    }, []);


    useEffect(() => {
        // 초기 데이터 로드
        fetchData();

        // 주기적 갱신 설정
        if (refreshInterval > 0) {
            intervalRef.current = setInterval(fetchData, refreshInterval);
        }

        // 정리
        return () => {
            if (intervalRef.current) {
                clearInterval(intervalRef.current);
            }
        };
    }, [fetchData, refreshInterval]);

    return {
        weather,
        airQuality,
        loading,
        error,
        refetch: fetchData,
    };
};

export default useWeather;