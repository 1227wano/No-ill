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

    if (airQuality?.text === '나쁨' || airQuality?.text === '매우나쁨') {
        return { emoji: '😷', mood: 'worried', color: '#f97316' };
    }

    if (temp !== undefined && temp !== null) {
        if (temp >= 33) return { emoji: '🥵', mood: 'hot', color: '#ef4444' };
        if (temp <= 0) return { emoji: '🥶', mood: 'cold', color: '#3b82f6' };
    }

    const moods = {
        morning: { emoji: '😊', mood: 'happy', color: '#eab308' },
        afternoon: { emoji: '😄', mood: 'energetic', color: '#22c55e' },
        evening: { emoji: '😌', mood: 'calm', color: '#fb923c' },
        night: { emoji: '😴', mood: 'sleepy', color: '#818cf8' },
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
        <div style={{
            width: '100%',
            height: '100%',
            background: 'white',
            borderRadius: 20,
            padding: 40,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
        }}>
            {/* 캐릭터 + 감정 */}
            <div style={{
                margin: '20px 0',
                position: 'relative',
            }}>
                <img
                    src={character}
                    alt="노일이 캐릭터"
                    style={{
                        width: 280,
                        height: 280,
                        objectFit: 'contain',
                    }}
                />
                <span style={{
                    position: 'absolute',
                    top: -10,
                    right: -10,
                    fontSize: 56,
                    animation: 'bounce 1s infinite',
                }}>
                    {petMood.emoji}
                </span>
            </div>

            {/* 펫 말풍선 */}
            <div style={{
                background: '#f5f5f5',
                borderRadius: 16,
                padding: '12px 24px',
                marginBottom: 20,
                position: 'relative',
            }}>
                <p style={{
                    fontSize: 18,
                    fontWeight: '600',
                    color: petMood.color,
                }}>
                    {petMessage}
                </p>
                <div style={{
                    position: 'absolute',
                    top: -8,
                    left: '50%',
                    transform: 'translateX(-50%) rotate(45deg)',
                    width: 16,
                    height: 16,
                    background: '#f5f5f5',
                }} />
            </div>

            {/* 인사말 */}
            <div style={{
                textAlign: 'center',
                marginBottom: 30,
            }}>
                <h2 style={{
                    fontSize: 32,
                    fontWeight: 'bold',
                    color: '#1a1a1a',
                    marginBottom: 12,
                }}>
                    {greeting.title}
                </h2>
                <p style={{
                    fontSize: 24,
                    color: '#5B8FCC',
                    fontWeight: '500',
                }}>
                    {greeting.sub}
                </p>
            </div>

            {/* 날씨 정보 */}
            <div style={{
                width: '100%',
                marginTop: 'auto',
            }}>
                {loading ? (
                    <p style={{
                        textAlign: 'center',
                        fontSize: 20,
                        color: '#6b7280',
                    }}>
                        날씨 정보 불러오는 중...
                    </p>
                ) : error ? (
                    <p style={{
                        textAlign: 'center',
                        fontSize: 20,
                        color: '#6b7280',
                    }}>
                        날씨 정보를 불러올 수 없습니다
                    </p>
                ) : (
                    <div style={{
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 16,
                    }}>
                        {/* 기온 */}
                        <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            background: '#f5f5f5',
                            borderRadius: 12,
                            padding: '16px 24px',
                        }}>
                            <div style={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: 16,
                            }}>
                                <span style={{ fontSize: 40 }}>🌡️</span>
                                <span style={{
                                    fontSize: 20,
                                    color: '#6b7280',
                                    fontWeight: '500',
                                }}>
                                    현재 기온
                                </span>
                            </div>
                            <span style={{
                                fontSize: 32,
                                fontWeight: 'bold',
                                color: '#1a1a1a',
                            }}>
                                {weather?.temp}°C
                            </span>
                        </div>

                        {/* 습도 */}
                        <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            background: '#f5f5f5',
                            borderRadius: 12,
                            padding: '16px 24px',
                        }}>
                            <div style={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: 16,
                            }}>
                                <span style={{ fontSize: 40 }}>💧</span>
                                <span style={{
                                    fontSize: 20,
                                    color: '#6b7280',
                                    fontWeight: '500',
                                }}>
                                    습도
                                </span>
                            </div>
                            <span style={{
                                fontSize: 32,
                                fontWeight: 'bold',
                                color: '#1a1a1a',
                            }}>
                                {weather?.humidity}%
                            </span>
                        </div>

                        {/* 미세먼지 */}
                        <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            background: '#f5f5f5',
                            borderRadius: 12,
                            padding: '16px 24px',
                        }}>
                            <div style={{
                                display: 'flex',
                                alignItems: 'center',
                                gap: 16,
                            }}>
                                <span style={{ fontSize: 40 }}>😷</span>
                                <span style={{
                                    fontSize: 20,
                                    color: '#6b7280',
                                    fontWeight: '500',
                                }}>
                                    미세먼지
                                </span>
                            </div>
                            <span style={{
                                fontSize: 32,
                                fontWeight: 'bold',
                                color: airQuality?.text === '좋음' ? '#22c55e' :
                                    airQuality?.text === '나쁨' ? '#ef4444' : '#1a1a1a',
                            }}>
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
