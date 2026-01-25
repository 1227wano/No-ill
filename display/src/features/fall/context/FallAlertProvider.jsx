import React, { useState, useEffect, useCallback } from 'react';
import { FallAlertContext } from './FallAlertContext';
import fallWebSocketService from '../services/fallWebSocket';
import { useAuth } from '../../auth';

const FallAlertProvider = ({ children }) => {
    const { isAuthenticated } = useAuth();
    const [fallAlert, setFallAlert] = useState(null);
    const [isConnected, setIsConnected] = useState(false);

    // 연결 상태 동기화
    useEffect(() => {
        const connectionCheckInterval = setInterval(() => {
            setIsConnected(fallWebSocketService.isConnected());
        }, 1000);

        return () => clearInterval(connectionCheckInterval);
    }, []);

    // WebSocket 연결 관리
    useEffect(() => {
        if (!isAuthenticated) {
            fallWebSocketService.disconnect();
            return;
        }

        const token = localStorage.getItem('token');
        if (!token) return;

        fallWebSocketService.connect(token);

        const unsubscribe = fallWebSocketService.addListener((message) => {
            if (message.type === 'FALL_DETECTED') {
                console.log('Fall alert received:', message);
                setFallAlert(message);
            }
        });

        return () => {
            unsubscribe();
            fallWebSocketService.disconnect();
        };
    }, [isAuthenticated]);

    const dismissAlert = useCallback(() => {
        setFallAlert(null);
    }, []);

    const value = {
        fallAlert,
        dismissAlert,
        isConnected,
    };

    return (
        <FallAlertContext.Provider value={value}>
            {children}
        </FallAlertContext.Provider>
    );
};

export default FallAlertProvider;
