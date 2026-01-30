import React, {useEffect, useState} from 'react';

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
        <header className="flex justify-between items-center py-5 px-10 bg-surface shadow-card">
            <div className="flex items-center">
                <div className="flex items-center gap-3">
                    <div className="w-12 h-12 bg-primary rounded-card flex items-center justify-center">
                        <div className="w-7 h-7 bg-white rounded-full"></div>
                    </div>
                    <span className="text-2xl font-bold text-text-main">No-ill (노일)</span>
                </div>
            </div>
            <div className="flex flex-col items-end gap-1">
                <span className="text-3xl font-bold text-text-main">{timeString}</span>
                <span className="text-body text-text-body">{dateString}</span>
            </div>
        </header>
    );
};


export default DisplayHeader;

