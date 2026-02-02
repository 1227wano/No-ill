import React from 'react';
import { useWeather } from '@/features/weather';
import { useAuth } from '@/features/auth';
import character from '@/assets/no-ill-character.png';

const GreetingCard = () => {
  const { weather, airQuality, loading, error } = useWeather();
  const { user } = useAuth();

  return (
    <div className="bg-surface rounded-card p-8 flex flex-col items-center shadow-card h-full">
      {/* 캐릭터 */}
      <div className="my-4">
        <img src={character} alt="노일이 캐릭터" className="w-[360px] h-[360px] object-contain" />
      </div>

      {/* 인사말 */}
      <div className="text-center mb-6">
        <h2 className="text-4xl font-bold text-text-main mb-6">좋은 아침이에요, {user?.userName || '사용자'}님!</h2>
        <p className="text-3xl text-primary font-medium">오늘도 활기찬 하루 시작해볼까요?</p>
      </div>

      {/* 날씨 정보 */}
      <div className="w-full mt-auto">
        {loading ? (
          <p className="text-center text-xl text-text-body">날씨 정보 불러오는 중...</p>
        ) : error ? (
          <p className="text-center text-xl text-text-body">날씨 정보를 불러올 수 없습니다</p>
        ) : (
          <div className="flex flex-col gap-4">
            {/* 기온 */}
            <div className="flex items-center justify-between bg-background rounded-xl px-8 py-5">
              <div className="flex items-center gap-4">
                <span className="text-5xl">🌡️</span>
                <span className="text-2xl text-text-body font-medium">현재 기온</span>
              </div>
              <span className="text-4xl font-bold text-text-main">{weather?.temp}°C</span>
            </div>
            {/* 습도 */}
            <div className="flex items-center justify-between bg-background rounded-xl px-8 py-5">
              <div className="flex items-center gap-4">
                <span className="text-5xl">💧</span>
                <span className="text-2xl text-text-body font-medium">습도</span>
              </div>
              <span className="text-4xl font-bold text-text-main">{weather?.humidity}%</span>
            </div>
            {/* 미세먼지 */}
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
