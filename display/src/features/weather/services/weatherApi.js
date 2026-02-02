import axios from 'axios';

const API_KEY = import.meta.env.VITE_DATA_GO_KR_API_KEY;
const NX = import.meta.env.VITE_WEATHER_NX || '60';
const NY = import.meta.env.VITE_WEATHER_NY || '127';
const STATION_NAME = import.meta.env.VITE_AIR_STATION_NAME || '종로구';

// 현재 날짜/시간 포맷
const getBaseDateTime = () => {
    const now = new Date();
    // 정시 기준으로 데이터 제공 (최근 1시간 전 데이터 사용)
    now.setHours(now.getHours() - 1);

    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hour = String(now.getHours()).padStart(2, '0');

    return {
        baseDate: `${year}${month}${day}`,
        baseTime: `${hour}00`,
    };
};

// 기상청 초단기실황 조회
export const fetchCurrentWeather = async () => {
    const { baseDate, baseTime } = getBaseDateTime();

    const response = await axios.get(
        '/api/weather/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst',
        {
            params: {
                serviceKey: API_KEY,
                numOfRows: 10,
                pageNo: 1,
                dataType: 'JSON',
                base_date: baseDate,
                base_time: baseTime,
                nx: NX,
                ny: NY,
            },
        }
    );

    return response.data;
};

// 에어코리아 실시간 대기오염 정보 조회
export const fetchAirPollution = async () => {
    const response = await axios.get(
        '/api/air/B552584/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty',
        {
            params: {
                stationName: STATION_NAME,
                dataTerm: 'month',
                pageNo: 1,
                numOfRows: 1,
                returnType: 'json',
                serviceKey: API_KEY,
            },
        }
    );

    return response.data;
};

// PM10 수치를 등급 텍스트로 변환
export const getAirQualityText = (pm10Value) => {
    const value = parseInt(pm10Value);
    if (isNaN(value)) return '알수없음';
    if (value <= 30) return '좋음';
    if (value <= 80) return '보통';
    if (value <= 150) return '나쁨';
    return '매우나쁨';
};

// PM10 수치에 따른 색상 클래스
export const getAirQualityColor = (pm10Value) => {
    const value = parseInt(pm10Value);
    if (isNaN(value)) return 'text-gray-500';
    if (value <= 30) return 'text-green-500';
    if (value <= 80) return 'text-yellow-500';
    if (value <= 150) return 'text-orange-500';
    return 'text-red-500';
};

// 등급 텍스트에 따른 색상 클래스
export const getAirQualityColorByGrade = (grade) => {
    if (grade === '좋음') return 'text-green-500';
    if (grade === '보통') return 'text-yellow-500';
    if (grade === '나쁨') return 'text-orange-500';
    if (grade === '매우나쁨') return 'text-red-500';
    return 'text-gray-500';
};
