import { useState, useEffect, useCallback } from 'react';

const useIdle = (timeout = 60000) => {
    const [isIdle, setIsIdle] = useState(false);

    const handleActivity = useCallback(() => {
        setIsIdle(false);
    }, []);

    useEffect(() => {
        let idleTimer;

        const resetTimer = () => {
            clearTimeout(idleTimer);
            setIsIdle(false);
            idleTimer = setTimeout(() => {
                setIsIdle(true);
            }, timeout);
        };

        // 사용자 활동 이벤트
        const events = [
            'mousedown',
            'mousemove',
            'keydown',
            'touchstart',
            'touchmove',
            'scroll',
            'click',
        ];

        // 이벤트 리스너 등록
        events.forEach(event => {
            document.addEventListener(event, resetTimer, { passive: true });
        });

        // 초기 타이머 시작
        resetTimer();

        return () => {
            clearTimeout(idleTimer);
            events.forEach(event => {
                document.removeEventListener(event, resetTimer);
            });
        };
    }, [timeout]);

    return { isIdle, resetIdle: handleActivity };
};

export default useIdle;
