import React, { useState, useEffect } from 'react';

const FAMILY_PHOTOS = [
    { id: 1, emoji: '👨‍👩‍👧‍👦', caption: '우리 가족 나들이', bg: 'from-sky-200 to-blue-300' },
    { id: 2, emoji: '🌳🧓🧒', caption: '손주와 공원 산책', bg: 'from-green-200 to-emerald-300' },
    { id: 3, emoji: '🎂🎉', caption: '생일 축하 파티', bg: 'from-pink-200 to-rose-300' },
    { id: 4, emoji: '🏖️👨‍👩‍👧', caption: '여름 바다 여행', bg: 'from-cyan-200 to-teal-300' },
    { id: 5, emoji: '🍽️👨‍👩‍👧‍👦', caption: '추석 가족 모임', bg: 'from-amber-200 to-orange-300' },
    { id: 6, emoji: '🌸🧓👴', caption: '봄 꽃구경', bg: 'from-fuchsia-200 to-pink-300' },
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

    // 슬라이드쇼 자동 전환
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
            className="fixed inset-0 bg-background z-50 flex flex-col items-center justify-center p-10 cursor-pointer"
            onClick={onWakeUp}
            onTouchStart={onWakeUp}
        >
            {/* 시간 표시 */}
            <div className="text-8xl font-bold text-text-main mb-10">
                {timeString}
            </div>

            {/* 년월일 표시 */}
            <div className="text-7xl font-semibold text-text-body mt-10 mb-10">
                {year}년 {month}월 {day}일
            </div>

            {/* 모드 전환 버튼 */}
            <div className="mb-6">
                <button
                    onClick={handleModeToggle}
                    className="px-8 py-3 bg-primary text-white text-2xl font-bold rounded-button hover:bg-primary/90 transition-colors"
                >
                    {mode === 'calendar' ? '📷 가족 앨범' : '📅 달력'}
                </button>
            </div>

            {mode === 'calendar' ? (
                /* 캘린더 */
                <div className="bg-surface rounded-card shadow-card p-8 w-full max-w-7xl">
                    <div className="grid grid-cols-7 gap-2 mb-4">
                        {weekDays.map((d, index) => (
                            <div
                                key={d}
                                className={`text-center text-5xl font-bold py-3 ${
                                    index === 0 ? 'text-red-500' : index === 6 ? 'text-blue-500' : 'text-text-body'
                                }`}
                            >
                                {d}
                            </div>
                        ))}
                    </div>
                    <div className="grid grid-cols-7 gap-2">
                        {days.map((d, index) => (
                            <div
                                key={index}
                                className={`text-center text-5xl py-8 rounded-lg ${
                                    d === null
                                        ? ''
                                        : d === currentDate.getDate()
                                        ? 'bg-primary text-white font-bold'
                                        : index % 7 === 0
                                        ? 'text-red-500'
                                        : index % 7 === 6
                                        ? 'text-blue-500'
                                        : 'text-text-main'
                                }`}
                            >
                                {d}
                            </div>
                        ))}
                    </div>
                </div>
            ) : (
                /* 가족 사진 슬라이드쇼 */
                <div className="w-full max-w-5xl">
                    <div
                        className={`bg-gradient-to-br ${photo.bg} rounded-card shadow-card p-12 flex flex-col items-center justify-center transition-opacity duration-500 ${
                            fade ? 'opacity-100' : 'opacity-0'
                        }`}
                        style={{ minHeight: '400px' }}
                    >
                        <span className="text-[120px] mb-6">{photo.emoji}</span>
                        <p className="text-4xl font-bold text-white drop-shadow-lg">
                            {photo.caption}
                        </p>
                    </div>
                    {/* 인디케이터 */}
                    <div className="flex justify-center gap-3 mt-6">
                        {FAMILY_PHOTOS.map((_, i) => (
                            <div
                                key={i}
                                className={`w-4 h-4 rounded-full transition-all ${
                                    i === photoIndex ? 'bg-primary scale-125' : 'bg-gray-300'
                                }`}
                            />
                        ))}
                    </div>
                </div>
            )}

            {/* 안내 문구 */}
            <p className="text-5xl text-text-body mt-10 animate-pulse">
                화면을 터치하면 돌아갑니다
            </p>
        </div>
    );
};

export default IdleScreen;
