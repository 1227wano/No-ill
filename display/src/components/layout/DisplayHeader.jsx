// src/components/layout/DisplayHeader.jsx
import React, { useEffect, useState } from 'react';
import logo from '@/assets/no-ill-logo.png';

const DisplayHeader = () => {
    const [time, setTime] = useState(new Date());

    useEffect(() => {
        const timer = setInterval(() => setTime(new Date()), 1000);
        return () => clearInterval(timer);
    }, []);

    const timeOptions = { hour: '2-digit', minute: '2-digit', hour12: true };
    const dateOptions = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' };

    const timeString = time.toLocaleTimeString('ko-KR', timeOptions);
    const dateString = time.toLocaleDateString('ko-KR', dateOptions);

    return (
        <header style={{
            width: '100%',
            height: '100%',
            display: 'flex',
            // ✅ 오타 수정 및 자식들을 양 끝으로 배분
            justifyContent: 'space-between', 
            alignItems: 'center',
            padding: '0 80px', // 좌우 안전 여백
            background: 'transparent',
        }}>
            {/* 1. 왼쪽 영역 (flex: 1) */}
            <div style={{ 
                flex: 1, 
                display: 'flex', 
                alignItems: 'center', 
                gap: 15 
            }}>
                <img src={logo} style={{ width: 80 }} alt="logo" />
                <h1 className="font-keris-b" style={{ 
                    fontSize: 48, 
                    color: 'var(--color-primary)', 
                    letterSpacing: '-1.5px' 
                }}>
                    No-ill
                </h1>
            </div>

            {/* 2. 중앙 영역 (flex: 1 + 중앙 정렬) */}
            <div className="font-keris-b" style={{ 
                flex: 1,
                textAlign: 'center', // 텍스트를 박스 정중앙으로
                fontSize: '64px', 
                color: '#1A3A5F',
                letterSpacing: '-1px',
                whiteSpace: 'nowrap' // 줄바꿈 방지
            }}>
                {timeString}
            </div>

            {/* 3. 오른쪽 영역 (flex: 1 + 우측 정렬) */}
            <div style={{ 
                flex: 1,
                textAlign: 'right', // 텍스트를 오른쪽 끝으로
                fontSize: '32px', 
                color: 'var(--color-text-body)',
                opacity: 0.8,
            }}>
                {dateString}
            </div>
        </header>
    );
};

export default DisplayHeader;