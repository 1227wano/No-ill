import React, { useState, useEffect } from 'react';

const FAMILY_PHOTOS = [
    { id: 1, emoji: '👨‍👩‍👧‍👦', caption: '우리 가족 나들이', bg: '#bae6fd' },
    { id: 2, emoji: '🌳🧓🧒', caption: '손주와 공원 산책', bg: '#bbf7d0' },
    { id: 3, emoji: '🎂🎉', caption: '생일 축하 파티', bg: '#fbcfe8' },
    { id: 4, emoji: '🏖️👨‍👩‍👧', caption: '여름 바다 여행', bg: '#a5f3fc' },
    { id: 5, emoji: '🍽️👨‍👩‍👧‍👦', caption: '추석 가족 모임', bg: '#fed7aa' },
    { id: 6, emoji: '🌸🧓👴', caption: '봄 꽃구경', bg: '#f5d0fe' },
];

const IdleScreen = ({ onWakeUp }) => {
    const [currentDate, setCurrentDate] = useState(new Date());
    const [mode, setMode] = useState('calendar');
    const [photoIndex, setPhotoIndex] = useState(0);
    const [fade, setFade] = useState(true);

    useEffect(() => {
        const timer = setInterval(() => {
            setCurrentDate(new Date());
        }, 1000);
        return () => clearInterval(timer);
    }, []);

    useEffect(() => {
        if (mode !== 'slideshow') return;
        const interval = setInterval(() => {
            setFade(false);
            setTimeout(() => {
                setPhotoIndex((prev) => (prev + 1) % FAMILY_PHOTOS.length);
                setFade(true);
            }, 500);
        }, 5000);
        return () => clearInterval(interval);
    }, [mode]);

    const generateCalendar = () => {
        const year = currentDate.getFullYear();
        const month = currentDate.getMonth();
        const firstDay = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const days = [];
        for (let i = 0; i < firstDay; i++) days.push(null);
        for (let i = 1; i <= daysInMonth; i++) days.push(i);
        return days;
    };

    const days = generateCalendar();
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    const timeOptions = { hour: '2-digit', minute: '2-digit', hour12: true };
    const timeString = currentDate.toLocaleTimeString('ko-KR', timeOptions);
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth() + 1;
    const day = currentDate.getDate();

    const photo = FAMILY_PHOTOS[photoIndex];

    const handleModeToggle = (e) => {
        e.stopPropagation();
        setMode((prev) => (prev === 'calendar' ? 'slideshow' : 'calendar'));
    };

    return (
        <div
            style={{
                width: 1920,
                height: 1080,
                position: 'relative',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                padding: 40,  // ⭐ 60 → 40
                cursor: 'pointer',
                background: '#f5f5f5',
            }}
            onClick={onWakeUp}
            onTouchStart={onWakeUp}
        >
            {/* 시간 표시 */}
            <div style={{
                fontSize: 80,  // ⭐ 120 → 80
                fontWeight: 'bold',
                color: '#1a1a1a',
                marginBottom: 20,  // ⭐ 40 → 20
            }}>
                {timeString}
            </div>

            {/* 년월일 표시 */}
            <div style={{
                fontSize: 40,  // ⭐ 64 → 40
                fontWeight: '600',
                color: '#4a4a4a',
                marginBottom: 20,  // ⭐ 40 → 20
            }}>
                {year}년 {month}월 {day}일
            </div>

            {/* 모드 전환 버튼 */}
            <div style={{ marginBottom: 20 }}>  {/* ⭐ 30 → 20 */}
                <button
                    onClick={handleModeToggle}
                    style={{
                        padding: '12px 30px',  // ⭐ 16px 40px → 12px 30px
                        background: '#5B8FCC',
                        color: 'white',
                        fontSize: 22,  // ⭐ 28 → 22
                        fontWeight: 'bold',
                        borderRadius: 12,
                        border: 'none',
                        cursor: 'pointer',
                        transition: 'background 0.2s',
                    }}
                    onMouseEnter={(e) => e.currentTarget.style.background = '#4a7ab8'}
                    onMouseLeave={(e) => e.currentTarget.style.background = '#5B8FCC'}
                >
                    {mode === 'calendar' ? '📷 가족 앨범' : '📅 달력'}
                </button>
            </div>

            {mode === 'calendar' ? (
                /* 캘린더 */
                <div style={{
                    background: 'white',
                    borderRadius: 16,
                    boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                    padding: 30,  // ⭐ 40 → 30
                    width: 1100,  // ⭐ 1400 → 1100
                }}>
                    {/* 요일 헤더 */}
                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(7, 1fr)',
                        gap: 8,  // ⭐ 10 → 8
                        marginBottom: 15,  // ⭐ 20 → 15
                    }}>
                        {weekDays.map((d, index) => (
                            <div
                                key={d}
                                style={{
                                    textAlign: 'center',
                                    fontSize: 28,  // ⭐ 40 → 28
                                    fontWeight: 'bold',
                                    padding: '8px 0',  // ⭐ 12px → 8px
                                    color: index === 0 ? '#ef4444' : index === 6 ? '#3b82f6' : '#4a4a4a',
                                }}
                            >
                                {d}
                            </div>
                        ))}
                    </div>

                    {/* 날짜 그리드 */}
                    <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(7, 1fr)',
                        gap: 8,  // ⭐ 10 → 8
                    }}>
                        {days.map((d, index) => (
                            <div
                                key={index}
                                style={{
                                    textAlign: 'center',
                                    fontSize: 28,  // ⭐ 40 → 28
                                    padding: '20px 0',  // ⭐ 32px → 20px
                                    borderRadius: 10,
                                    background: d === currentDate.getDate() ? '#5B8FCC' : 'transparent',
                                    color: d === null
                                        ? 'transparent'
                                        : d === currentDate.getDate()
                                            ? 'white'
                                            : index % 7 === 0
                                                ? '#ef4444'
                                                : index % 7 === 6
                                                    ? '#3b82f6'
                                                    : '#1a1a1a',
                                    fontWeight: d === currentDate.getDate() ? 'bold' : 'normal',
                                }}
                            >
                                {d}
                            </div>
                        ))}
                    </div>
                </div>
            ) : (
                /* 가족 사진 슬라이드쇼 */
                <div style={{ width: 900 }}>  {/* ⭐ 1200 → 900 */}
                    <div
                        style={{
                            background: photo.bg,
                            borderRadius: 16,
                            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                            padding: 40,  // ⭐ 60 → 40
                            display: 'flex',
                            flexDirection: 'column',
                            alignItems: 'center',
                            justifyContent: 'center',
                            minHeight: 320,  // ⭐ 450 → 320
                            transition: 'opacity 0.5s',
                            opacity: fade ? 1 : 0,
                        }}
                    >
                        <span style={{
                            fontSize: 100,  // ⭐ 150 → 100
                            marginBottom: 20  // ⭐ 30 → 20
                        }}>
                            {photo.emoji}
                        </span>
                        <p style={{
                            fontSize: 32,  // ⭐ 48 → 32
                            fontWeight: 'bold',
                            color: 'white',
                            textShadow: '2px 2px 4px rgba(0,0,0,0.3)',
                        }}>
                            {photo.caption}
                        </p>
                    </div>

                    {/* 인디케이터 */}
                    <div style={{
                        display: 'flex',
                        justifyContent: 'center',
                        gap: 10,  // ⭐ 12 → 10
                        marginTop: 20,  // ⭐ 30 → 20
                    }}>
                        {FAMILY_PHOTOS.map((_, i) => (
                            <div
                                key={i}
                                style={{
                                    width: 12,  // ⭐ 16 → 12
                                    height: 12,  // ⭐ 16 → 12
                                    borderRadius: '50%',
                                    background: i === photoIndex ? '#5B8FCC' : '#d1d5db',
                                    transform: i === photoIndex ? 'scale(1.25)' : 'scale(1)',
                                    transition: 'all 0.3s',
                                }}
                            />
                        ))}
                    </div>
                </div>
            )}

            {/* 안내 문구 */}
            <p style={{
                fontSize: 24,  // ⭐ 36 → 24
                color: '#6b7280',
                marginTop: 25,  // ⭐ 40 → 25
            }}>
                화면을 터치하면 돌아갑니다
            </p>

            {/* ⭐ CSS 애니메이션 추가 */}
            <style>{`
                @keyframes pulse {
                    0%, 100% {
                        opacity: 1;
                    }
                    50% {
                        opacity: 0.5;
                    }
                }
            `}</style>
        </div>
    );
};

export default IdleScreen;
