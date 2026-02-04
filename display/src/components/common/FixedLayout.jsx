import React, { useState, useEffect, useCallback } from 'react';

const DESIGN_WIDTH = 1920;
const DESIGN_HEIGHT = 1200;

const FixedLayout = ({ children }) => {
    const [scale, setScale] = useState(1);

    const updateScale = useCallback(() => {
        const scaleX = window.innerWidth / DESIGN_WIDTH;
        const scaleY = window.innerHeight / DESIGN_HEIGHT;
        setScale(Math.min(scaleX, scaleY));
    }, []);

    useEffect(() => {
        updateScale();
        window.addEventListener('resize', updateScale);
        return () => window.removeEventListener('resize', updateScale);
    }, [updateScale]);

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
