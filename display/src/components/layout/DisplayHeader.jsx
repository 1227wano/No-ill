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
        <header className="flex justify-between items-center py-5 px-10 bg-white shadow-sm max-[768px]:py-4 max-[768px]:px-5 max-[480px]:flex-col max-[480px]:items-start max-[480px]:gap-3">
            <div className="flex items-center">
                <div className="flex items-center gap-3">
                    <div
                        className="w-10 h-10 bg-gradient-to-br from-blue-500 to-blue-700 rounded-lg relative after:content-[''] after:absolute after:top-1/2 after:left-1/2 after:-translate-x-1/2 after:-translate-y-1/2 after:w-5 after:h-5 after:bg-white/80 after:rounded"></div>
                    <span className="text-2xl font-semibold text-gray-800">No-ill (노일)</span>
                </div>
            </div>
            <div className="flex flex-col items-end gap-1">
                <span className="text-xl font-medium text-gray-800">{timeString}</span>
                <span className="text-sm text-gray-500">{dateString}</span>
            </div>
        </header>
    );
};


export default DisplayHeader;

