import React, { useSyncExternalStore, useCallback } from 'react';

const DESIGN_WIDTH = 1920;
const DESIGN_HEIGHT = 1200;

const getScale = () => {
    const scaleX = window.innerWidth / DESIGN_WIDTH;
    const scaleY = window.innerHeight / DESIGN_HEIGHT;
    return Math.min(scaleX, scaleY);
};

const FixedLayout = ({ children }) => {
    const subscribe = useCallback((callback) => {
        window.addEventListener('resize', callback);
        return () => window.removeEventListener('resize', callback);
    }, []);

    const scale = useSyncExternalStore(subscribe, getScale);

    return (
        <div
            style={{
                position: 'fixed',
                top: '50%',
                left: '50%',
                width: `${DESIGN_WIDTH}px`,
                height: `${DESIGN_HEIGHT}px`,
                transform: `translate(-50%, -50%) scale(${scale})`,
                transformOrigin: 'center center',
                overflow: 'hidden',
            }}
        >
            {children}
        </div>
    );
};

export default FixedLayout;
