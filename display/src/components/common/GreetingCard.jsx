import React, { useState, useEffect } from 'react';
import { useWeather } from '@/features/weather';
import { useAuth } from '@/features/auth';
import character from '@/assets/no-ill-character.png';

const getTimeOfDay = () => {
  const hour = new Date().getHours();
  if (hour >= 5 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 21) return 'evening';
  return 'night';
};

const getPetMood = (timeOfDay, weather, airQuality) => {
  const temp = weather?.temp;

  // 미세먼지 나쁨
  if (airQuality?.text === '나쁨' || airQuality?.text === '매우나쁨') {
    return { emoji: '😷', mood: 'worried', color: 'text-orange-500' };
  }

  // 극단적 기온
  if (temp !== undefined && temp !== null) {
    if (temp >= 33) return { emoji: '🥵', mood: 'hot', color: 'text-red-500' };
    if (temp <= 0) return { emoji: '🥶', mood: 'cold', color: 'text-blue-500' };
  }

  // 시간대별 기본 감정
  const moods = {
    morning: { emoji: '😊', mood: 'happy', color: 'text-yellow-500' },
    afternoon: { emoji: '😄', mood: 'energetic', color: 'text-green-500' },
    evening: { emoji: '😌', mood: 'calm', color: 'text-orange-400' },
    night: { emoji: '😴', mood: 'sleepy', color: 'text-indigo-400' },
  };

  return moods[timeOfDay] || moods.morning;
};

const getGreeting = (timeOfDay, userName) => {
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

  return (
    <div className="bg-surface rounded-card p-8 flex flex-col items-center shadow-card h-full">
      {/* 캐릭터 + 감정 */}
      <div className="my-4 relative">
        <img src={character} alt="노일이 캐릭터" className="w-[360px] h-[360px] object-contain" />
        <span className="absolute -top-2 -right-2 text-7xl animate-bounce">
          {petMood.emoji}
        </span>
      </div>

      {/* 펫 말풍선 */}
      <div className="bg-background rounded-card px-6 py-3 mb-4 relative">
        <p className={`text-xl font-semibold ${petMood.color}`}>
          {petMessage}
        </p>
        <div className="absolute -top-2 left-1/2 -translate-x-1/2 w-4 h-4 bg-background rotate-45" />
      </div>

      {/* 인사말 */}
      <div className="text-center mb-6">
        <h2 className="text-4xl font-bold text-text-main mb-6">{greeting.title}</h2>
        <p className="text-3xl text-primary font-medium">{greeting.sub}</p>
      </div>

      {/* 날씨 정보 */}
      <div className="w-full mt-auto">
        {loading ? (
          <p className="text-center text-xl text-text-body">날씨 정보 불러오는 중...</p>
        ) : error ? (
          <p className="text-center text-xl text-text-body">날씨 정보를 불러올 수 없습니다</p>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex items-center justify-between bg-background rounded-xl px-8 py-5">
              <div className="flex items-center gap-4">
                <span className="text-5xl">🌡️</span>
                <span className="text-2xl text-text-body font-medium">현재 기온</span>
              </div>
              <span className="text-4xl font-bold text-text-main">{weather?.temp}°C</span>
            </div>
            <div className="flex items-center justify-between bg-background rounded-xl px-8 py-5">
              <div className="flex items-center gap-4">
                <span className="text-5xl">💧</span>
                <span className="text-2xl text-text-body font-medium">습도</span>
              </div>
              <span className="text-4xl font-bold text-text-main">{weather?.humidity}%</span>
            </div>
            <div className="flex items-center justify-between bg-background rounded-xl px-8 py-5">
              <div className="flex items-center gap-4">
                <span className="text-5xl">😷</span>
                <span className="text-2xl text-text-body font-medium">미세먼지</span>
              </div>
              <span className={`text-4xl font-bold ${airQuality?.colorClass}`}>
                {airQuality?.text}
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default GreetingCard;
