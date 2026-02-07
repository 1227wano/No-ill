// src/components/common/FixedLayout.jsx

/* eslint-disable no-undef */

import React, { useEffect, useMemo, useState } from 'react';

const DESIGN_WIDTH = 1920;
const DESIGN_HEIGHT = 1080;
const TARGET_RATIO = DESIGN_WIDTH / DESIGN_HEIGHT; // 1.778

const FixedLayout = ({
                         children,
                         background = '#000',
                         maxScale
                     }) => {
    const [viewport, setViewport] = useState({
        w: window.innerWidth,
        h: window.innerHeight
    });

    useEffect(() => {
        const onResize = () => {
            setViewport({
                w: window.innerWidth,
                h: window.innerHeight
            });
        };

        window.addEventListener('resize', onResize);
        return () => window.removeEventListener('resize', onResize);
    }, []);

    const { scale, mode } = useMemo(() => {
        const scaleByWidth = viewport.w / DESIGN_WIDTH;
        const scaleByHeight = viewport.h / DESIGN_HEIGHT;

        // ⭐ Contain 방식: 작은 쪽 기준 (전체가 보임, 잘림 없음)
        let calculatedScale = Math.min(scaleByWidth, scaleByHeight);

        // 어느 쪽이 기준인지
        const scaleMode = scaleByWidth < scaleByHeight ? 'width' : 'height';

        // 최대 scale 제한
        const finalScale = maxScale ? Math.min(calculatedScale, maxScale) : calculatedScale;

        console.log('📏 Scale Debug:', {
            viewport: `${viewport.w} × ${viewport.h}`,
            windowRatio: (viewport.w / viewport.h).toFixed(3),
            targetRatio: TARGET_RATIO.toFixed(3),
            scaleByWidth: scaleByWidth.toFixed(4),
            scaleByHeight: scaleByHeight.toFixed(4),
            selected: `${scaleMode} (${calculatedScale.toFixed(4)})`,
            finalScale: finalScale.toFixed(4),
            limited: maxScale && calculatedScale > maxScale ? '⚠️ 제한됨' : '✅',
            result: `${Math.round(DESIGN_WIDTH * finalScale)} × ${Math.round(DESIGN_HEIGHT * finalScale)}`
        });

        return { scale: finalScale, mode: scaleMode };
    }, [viewport, maxScale]);

    return (
        <div
            style={{
                position: 'fixed',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                width: '100%',
                height: '100%',
                background,
                overflow: 'hidden',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
            }}
        >
            <div
                style={{
                    width: DESIGN_WIDTH,
                    height: DESIGN_HEIGHT,
                    transform: `scale(${scale})`,
                    transformOrigin: 'center center',
                    position: 'relative',
                }}
            >
                {children}
            </div>

            {/* 디버그 */}
            {process.env.NODE_ENV === 'development' && (
                <div style={{
                    position: 'fixed',
                    left: 12,
                    bottom: 12,
                    color: '#0f0',
                    fontSize: 14,
                    background: 'rgba(0,0,0,0.9)',
                    padding: '8px 12px',
                    borderRadius: '6px',
                    fontFamily: 'monospace',
                    zIndex: 99999,
                    lineHeight: 1.5,
                }}>
                    <div><strong>Viewport:</strong> {viewport.w} × {viewport.h}</div>
                    <div><strong>Ratio:</strong> {(viewport.w / viewport.h).toFixed(3)} (target: {TARGET_RATIO.toFixed(3)})</div>
                    <div><strong>Mode:</strong> contain ({mode})</div>
                    <div><strong>Scale:</strong> {scale.toFixed(4)} {maxScale && scale >= maxScale && '(최대)'}</div>
                    <div><strong>Scaled:</strong> {Math.round(DESIGN_WIDTH * scale)} × {Math.round(DESIGN_HEIGHT * scale)}</div>
                </div>
            )}
        </div>
    );
};

export default FixedLayout;
