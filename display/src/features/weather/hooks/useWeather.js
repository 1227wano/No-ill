import { useState, useEffect } from 'react';
import {
    fetchCurrentWeather,
    fetchAirPollution,
    getAirQualityColorByGrade
} from '../services/weatherApi';

const useWeather = (refreshInterval = 30 * 60 * 1000) => {
    const [weather, setWeather] = useState(null);
    const [airQuality, setAirQuality] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchData = async () => {
        try {
            setError(null);

            // 기상청 API 호출
            try {
                const weatherData = await fetchCurrentWeather();
                const items = weatherData?.response?.body?.items?.item || [];
                const weatherMap = {};
                items.forEach(item => {
                    weatherMap[item.category] = item.obsrValue;
                });

                setWeather({
                    temp: Math.round(parseFloat(weatherMap.T1H || 0)),
                    humidity: parseInt(weatherMap.REH || 0),
                });
            } catch (err) {
                console.error('기상청 API 조회 실패:', err);
            }

            // 에어코리아 API 호출 (실패해도 기온/습도는 표시)
            try {
                const airData = await fetchAirPollution();
                const airItems = airData?.response?.body?.items || [];
                const latestData = airItems[0];
                const pm10Grade = latestData?.pm10Grade;

                const gradeText = { '1': '좋음', '2': '보통', '3': '나쁨', '4': '매우나쁨' };
                const grade = gradeText[pm10Grade] || '알수없음';

                setAirQuality({
                    pm10: latestData?.pm10Value,
                    text: grade,
                    colorClass: getAirQualityColorByGrade(grade),
                });
            } catch (err) {
                console.error('에어코리아 API 조회 실패:', err);
                setAirQuality({
                    text: '알수없음',
                    colorClass: 'text-gray-500',
                });
            }
        } catch (err) {
            console.error('날씨 정보 조회 실패:', err);
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchData();

        const interval = setInterval(fetchData, refreshInterval);
        return () => clearInterval(interval);
    }, [refreshInterval]);

    return { weather, airQuality, loading, error, refetch: fetchData };
};

export default useWeather;
