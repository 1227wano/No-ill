import React, { useState, useEffect } from 'react';
import { useWeather } from '@/features/weather';
import { useAuth } from '@/features/auth';
import character from '@/assets/no-ill-character.png';

// ✅ 디자인 통일감을 위한 색상 테마 정의
const theme = {
    primary: '#5B8FCC', // 메인 블루
    primarySoft: '#EBF5FF', // 말풍선 배경용 연한 블루
    textMain: '#1F2937', // 진한 회색 (가독성)
    textSub: '#6B7280', // 연한 회색
    bgCard: '#F8F9FA', // 날씨 카드 배경
    state: {
        good: '#22c55e', // 좋음/초록
        warning: '#f97316', // 나쁨/주황
        danger: '#ef4444', // 매우나쁨/더위/빨강
        cold: '#3b82f6', // 추위/파랑
        neutral: '#eab308', // 보통/노랑
    }
};

const getTimeOfDay = () => {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
};

const getPetMood = (timeOfDay, weather, airQuality) => {
    const temp = weather?.temp;

    if (airQuality?.text === '나쁨' || airQuality?.text === '매우나쁨') {
        // 테마 색상 적용
        return { emoji: '😷', mood: 'worried', color: theme.state.warning };
    }

    if (temp !== undefined && temp !== null) {
        if (temp >= 33) return { emoji: '🥵', mood: 'hot', color: theme.state.danger };
        if (temp <= 0) return { emoji: '🥶', mood: 'cold', color: theme.state.cold };
    }

    const moods = {
        // 테마 색상 적용
        morning: { emoji: '😊', mood: 'happy', color: theme.state.neutral },
        afternoon: { emoji: '😄', mood: 'energetic', color: theme.state.good },
        evening: { emoji: '😌', mood: 'calm', color: theme.state.warning },
        night: { emoji: '😴', mood: 'sleepy', color: theme.primary },
    };

    return moods[timeOfDay] || moods.morning;
};

const getGreeting = (timeOfDay, userName) => {
    // ... (기존 로직 동일)
    const name = userName || '사용자';
    const greetings = {
        morning: { title: `좋은 아침이에요, ${name}님!`, sub: '오늘도 활기찬 하루 시작해볼까요?' },
        afternoon: { title: `좋은 오후예요, ${name}님!`, sub: '점심은 맛있게 드셨나요?' },
        evening: { title: `좋은 저녁이에요, ${name}님!`, sub: '오늘 하루도 수고 많으셨어요!' },
        night: { title: `편안한 밤이에요, ${name}님!`, sub: '오늘도 푹 주무세요 💤' },
    };
    return greetings[timeOfDay] || greetings.morning;
};

const getPetMessage = (mood) => {
    // ... (기존 로직 동일)
    const messages = {
        worried: '오늘은 미세먼지가 많아요. 외출을 자제해주세요!',
        hot: '오늘 많이 덥네요! 물 자주 드세요 💧',
        cold: '오늘 많이 춥네요! 따뜻하게 입으세요 🧣',
        happy: '노일이가 기분이 좋아요!',
        energetic: '노일이가 신나 있어요!',
        calm: '노일이가 편안해하고 있어요~',
        sleepy: '노일이가 졸려하고 있어요...',
    };
    return messages[mood] || messages.happy;
};

// ✅ 반복되는 날씨 정보 표시를 위한 재사용 컴포넌트
const WeatherInfoItem = ({ icon, label, value, valueColor = theme.textMain, iconBg }) => (
    <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        background: theme.bgCard,
        borderRadius: 16, // 더 둥글게
        padding: '16px 24px',
        border: '1px solid #E5E7EB', // 아주 연한 테두리 추가로 깔끔하게
    }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
             {/* 아이콘 배경 추가로 시인성 확보 */}
            <div style={{
                fontSize: 32,
                width: 52, height: 52,
                background: iconBg,
                borderRadius: 12,
                display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
                {icon}
            </div>
            <span style={{
                fontSize: 20,
                color: theme.textSub,
                fontWeight: '600',
            }}>
                {label}
            </span>
        </div>
        <span style={{
            fontSize: 32,
            fontWeight: '800', // 폰트 두께 강조
            color: valueColor,
        }}>
            {value}
        </span>
    </div>
);


const GreetingCard = () => {
    const { weather, airQuality, loading, error } = useWeather();
    const { user } = useAuth();
    const [timeOfDay, setTimeOfDay] = useState(getTimeOfDay);

    useEffect(() => {
        const interval = setInterval(() => {
            setTimeOfDay(getTimeOfDay());
        }, 60000);
        return () => clearInterval(interval);
    }, []);

    const petMood = getPetMood(timeOfDay, weather, airQuality);
    const greeting = getGreeting(timeOfDay, user?.userName);
    const petMessage = getPetMessage(petMood.mood);

    // 미세먼지 상태에 따른 색상 결정 함수
    const getAirQualityColor = (text) => {
        if (text === '좋음') return theme.state.good;
        if (text === '보통') return theme.state.neutral;
        if (text === '나쁨' || text === '매우나쁨') return theme.state.danger;
        return theme.textMain;
    };

    return (
        <div style={{
            width: '100%',
            height: '100%',
            background: 'white',
            borderRadius: 24, // 모서리 더 둥글게
            padding: '40px 32px', // 패딩 조정
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            boxShadow: '0 10px 30px rgba(0,0,0,0.08)', // 그림자 더 부드럽게
        }}>
            {/* 캐릭터 + 감정 이모지 */}
            <div style={{ margin: '10px 0 20px', position: 'relative' }}>
                <img
                    src={character}
                    alt="노일이 캐릭터"
                    style={{ width: 260, height: 260, objectFit: 'contain' }}
                />
                <span style={{
                    position: 'absolute', top: -5, right: -5, fontSize: 60,
                    animation: 'bounce 1s infinite',
                    filter: 'drop-shadow(0 4px 6px rgba(0,0,0,0.1))' // 이모지 그림자 추가
                }}>
                    {petMood.emoji}
                </span>
            </div>

            {/* 펫 말풍선 (디자인 개선) */}
            <div style={{
                background: theme.primarySoft, // 연한 블루 배경 적용
                borderRadius: 20,
                padding: '16px 28px',
                marginBottom: 30,
                position: 'relative',
                boxShadow: '0 4px 12px rgba(91, 143, 204, 0.15)', // 은은한 컬러 그림자
            }}>
                <p style={{
                    fontSize: 20,
                    fontWeight: '700',
                    color: theme.primary, // 텍스트 색상을 메인 컬러로 통일
                    textAlign: 'center',
                    margin: 0,
                }}>
                    "{petMessage}"
                </p>
                {/* 말풍선 꼬리 */}
                <div style={{
                    position: 'absolute', top: -10, left: '50%',
                    transform: 'translateX(-50%) rotate(45deg)',
                    width: 20, height: 20,
                    background: theme.primarySoft, // 배경색과 동일하게
                }} />
            </div>

            {/* 인사말 */}
            <div style={{ textAlign: 'center', marginBottom: 36 }}>
                <h2 style={{
                    fontSize: 34, fontWeight: '800',
                    color: theme.textMain, marginBottom: 12, letterSpacing: '-0.5px'
                }}>
                    {greeting.title}
                </h2>
                <p style={{
                    fontSize: 24, color: theme.primary, fontWeight: '600'
                }}>
                    {greeting.sub}
                </p>
            </div>

            {/* 날씨 정보 영역 */}
            <div style={{ width: '100%', marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: 16 }}>
                {loading ? (
                    <p style={{ textAlign: 'center', fontSize: 20, color: theme.textSub }}>
                        날씨 정보 불러오는 중...
                    </p>
                ) : error ? (
                    <p style={{ textAlign: 'center', fontSize: 20, color: theme.textSub }}>
                        날씨 정보를 불러올 수 없습니다
                    </p>
                ) : (
                    <>
                        {/* 재사용 컴포넌트 활용 */}
                        <WeatherInfoItem
                            icon="🌡️"
                            label="현재 기온"
                            value={`${weather?.temp}°C`}
                            iconBg="#FFEDD5" // 연한 주황 배경
                        />
                        <WeatherInfoItem
                            icon="💧"
                            label="습도"
                            value={`${weather?.humidity}%`}
                            iconBg="#DBEAFE" // 연한 파랑 배경
                        />
                        <WeatherInfoItem
                            icon="😷"
                            label="미세먼지"
                            value={airQuality?.text}
                            valueColor={getAirQualityColor(airQuality?.text)}
                            iconBg="#E5E7EB" // 연한 회색 배경
                        />
                    </>
                )}
            </div>
        </div>
    );
};

export default GreetingCard;