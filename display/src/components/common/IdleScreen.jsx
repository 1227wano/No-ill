import React, { useState, useEffect } from 'react';

const IdleScreen = ({ onWakeUp }) => {
    const [currentDate, setCurrentDate] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => {
            setCurrentDate(new Date());
        }, 1000);

        return () => clearInterval(timer);
    }, []);

    // 현재 월의 달력 데이터 생성
    const generateCalendar = () => {
        const year = currentDate.getFullYear();
        const month = currentDate.getMonth();

        const firstDay = new Date(year, month, 1).getDay();
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        const days = [];

        // 빈 칸 (이전 달)
        for (let i = 0; i < firstDay; i++) {
            days.push(null);
        }

        // 현재 월의 날짜
        for (let i = 1; i <= daysInMonth; i++) {
            days.push(i);
        }

        return days;
    };

    const days = generateCalendar();
    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    const timeOptions = { hour: '2-digit', minute: '2-digit', hour12: true };
    const timeString = currentDate.toLocaleTimeString('ko-KR', timeOptions);

    const year = currentDate.getFullYear();
    const month = currentDate.getMonth() + 1;

    return (
        <div
            className="fixed inset-0 bg-background z-50 flex flex-col items-center justify-center p-10 cursor-pointer"
            onClick={onWakeUp}
            onTouchStart={onWakeUp}
        >
            {/* 시간 표시 */}
            <div className="text-8xl font-bold text-text-main mb-6">
                {timeString}
            </div>

            {/* 년월 표시 */}
            <div className="text-4xl font-semibold text-text-body mb-10">
                {year}년 {month}월
            </div>

            {/* 캘린더 */}
            <div className="bg-surface rounded-card shadow-card p-8 w-full max-w-4xl">
                {/* 요일 헤더 */}
                <div className="grid grid-cols-7 gap-2 mb-4">
                    {weekDays.map((day, index) => (
                        <div
                            key={day}
                            className={`text-center text-2xl font-bold py-3 ${
                                index === 0 ? 'text-red-500' : index === 6 ? 'text-blue-500' : 'text-text-body'
                            }`}
                        >
                            {day}
                        </div>
                    ))}
                </div>

                {/* 날짜 그리드 */}
                <div className="grid grid-cols-7 gap-2">
                    {days.map((day, index) => (
                        <div
                            key={index}
                            className={`text-center text-3xl py-4 rounded-lg ${
                                day === null
                                    ? ''
                                    : day === currentDate.getDate()
                                    ? 'bg-primary text-white font-bold'
                                    : index % 7 === 0
                                    ? 'text-red-500'
                                    : index % 7 === 6
                                    ? 'text-blue-500'
                                    : 'text-text-main'
                            }`}
                        >
                            {day}
                        </div>
                    ))}
                </div>
            </div>

            {/* 안내 문구 */}
            <p className="text-2xl text-text-body mt-10 animate-pulse">
                화면을 터치하면 돌아갑니다
            </p>
        </div>
    );
};

export default IdleScreen;
