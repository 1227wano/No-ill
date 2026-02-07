import React, { useEffect, useState } from 'react';
import logo from '@/assets/no-ill-logo.png';

const DisplayHeader = () => {
    const [time, setTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => {
            setTime(new Date());
        }, 1000);

        return () => clearInterval(timer);
    }, []);

    const timeOptions = { hour: '2-digit', minute: '2-digit', hour12: true };
    const dateOptions = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' };

    const timeString = time.toLocaleTimeString('ko-KR', timeOptions);
    const dateString = time.toLocaleDateString('ko-KR', dateOptions);

    return (
        <header style={{
            width: '100%',
            height: 120,
            display: 'grid',
            gridTemplateColumns: '640px 640px 640px',
            alignItems: 'center',
            padding: '0 60px',
            background: 'white',
            boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        }}>
            {/* 왼쪽: 로고 */}
            <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: 20,
            }}>
                <img
                    src={logo}
                    alt="No-ill 로고"
                    style={{
                        width: 80,
                        height: 80,
                        objectFit: 'contain',
                    }}
                />
                <span style={{
                    fontSize: 36,
                    fontWeight: 'bold',
                    color: '#1a1a1a',
                }}>
                    No-ill (노일)
                </span>
            </div>

            {/* 중앙: 시간 */}
            <div style={{
                display: 'flex',
                justifyContent: 'center',
            }}>
                <span style={{
                    fontSize: 56,
                    fontWeight: 'bold',
                    color: '#1a1a1a',
                }}>
                    {timeString}
                </span>
            </div>

            {/* 오른쪽: 날짜 */}
            <div style={{
                display: 'flex',
                justifyContent: 'flex-end',
            }}>
                <span style={{
                    fontSize: 32,
                    fontWeight: '600',
                    color: '#1a1a1a',
                }}>
                    {dateString}
                </span>
            </div>
        </header>
    );
};

export default DisplayHeader;
