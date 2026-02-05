import React, { useEffect, useMemo, useState } from 'react';

const DESIGN_WIDTH = 1920;
const DESIGN_HEIGHT = 1080;

const FixedLayout = ({ children, background = '#FFF' }) => {
    const [viewport, setViewport] = useState({ w: window.innerWidth, h: window.innerHeight });

    useEffect(() => {
        const onResize = () => setViewport({ w: window.innerWidth, h: window.innerHeight });
        window.addEventListener('resize', onResize);
        return () => window.removeEventListener('resize', onResize);
    }, []);

    const scale = useMemo(() => {
        return Math.min(viewport.w / DESIGN_WIDTH, viewport.h / DESIGN_HEIGHT);
    }, [viewport]);

    return (
        <div
            style={{
                width: '100vw',
                height: '100vh',
                background,
                overflow: 'hidden',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
            }}
        >
            {/* 가운데 정렬 + scale */}
            <div
                style={{
                    width: DESIGN_WIDTH,
                    height: DESIGN_HEIGHT,
                    transform: `scale(${scale})`,
                    transformOrigin: 'center center',
                    willChange: 'transform',
                }}
            >
                {children}
            </div>

            {/* (선택) 디버그용: 실제 스케일된 영역 확인하고 싶으면 아래 주석 해제 */}
            {/*
      <div style={{
        position:'fixed', left: 12, bottom: 12, color:'#fff', fontSize: 12, opacity: 0.7
      }}>
        viewport={viewport.w}x{viewport.h} scale={scale.toFixed(3)} scaled={scaledW}x{scaledH}
      </div>
      */}
        </div>
    );
};


export default FixedLayout;
