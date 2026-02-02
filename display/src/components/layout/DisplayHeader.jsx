import React, {useEffect, useState} from 'react';
import logo from '@/assets/no-ill-logo.png';

const DisplayHeader = () => {
    const [time, setTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => {
            setTime(new Date());
        }, 1000);

        return () => clearInterval(timer);
    }, []);


    const timeOptions = {hour: '2-digit', minute: '2-digit', hour12: true};
    const dateOptions = {year: 'numeric', month: 'long', day: 'numeric', weekday: 'long'};

    const timeString = time.toLocaleTimeString('ko-KR', timeOptions);
    const dateString = time.toLocaleDateString('ko-KR', dateOptions);


    return (
        <header className="grid grid-cols-3 items-center py-6 px-10 bg-surface shadow-card">
            {/* 왼쪽: 로고 */}
            <div className="flex items-center gap-4">
                <img src={logo} alt="No-ill 로고" className="w-32 h-32 object-contain" />
                <span className="text-5xl font-bold text-text-main">No-ill (노일)</span>
            </div>
            {/* 중앙: 시간 */}
            <div className="flex justify-center">
                <span className="text-6xl font-bold text-text-main">{timeString}</span>
            </div>
            {/* 오른쪽: 날짜 */}
            <div className="flex justify-end">
                <span className="text-5xl font-semibold text-text-main">{dateString}</span>
            </div>
        </header>
    );
};


export default DisplayHeader;

