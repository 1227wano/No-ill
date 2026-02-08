// src/features/fall/context/FallAlertProvider.jsx

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { FallAlertContext } from './FallAlertContext';
import fallWebSocketService, { FALL_MESSAGE_TYPE } from '../services/fallWebSocket';
import { tokenManager } from '@/api/client.js';
import { useAuth } from '../../auth';

const FallAlertProvider = ({ children }) => {
    const { isAuthenticated, pet } = useAuth();
    const [fallAlert, setFallAlert] = useState(null);
    const [isConnected, setIsConnected] = useState(false);
    const [connectionError, setConnectionError] = useState(null);

    // 리스너 정리용 ref
    const unsubscribeRef = useRef(null);

    // WebSocket 메시지 핸들러
    const handleWebSocketMessage = useCallback((message) => {
        switch (message.type) {
            case FALL_MESSAGE_TYPE.FALL_DETECTED:
                console.log('🚨 Fall detected:', message);
                setFallAlert(message);
                setConnectionError(null);
                break;

            case FALL_MESSAGE_TYPE.FALL_RESOLVED:
                console.log('✅ Fall resolved:', message);
                setFallAlert(null);
                break;

            case FALL_MESSAGE_TYPE.CONNECTION_STATUS:
                console.log('🔌 Connection status:', message.connected);
                setIsConnected(message.connected);

                if (!message.connected) {
                    setConnectionError('낙상 감지 연결이 끊어졌습니다.');
                } else {
                    setConnectionError(null);
                }
                break;

            default:
                console.warn('Unknown message type:', message.type);
        }
    }, []);

    // WebSocket 연결 관리
    useEffect(() => {
        // 인증되지 않았으면 연결 해제
        if (!isAuthenticated || !pet?.petId) {
            console.log('🔌 User not authenticated, disconnecting WebSocket');
            fallWebSocketService.disconnect();
            // eslint-disable-next-line react-hooks/set-state-in-effect
            setConnectionError(null);
            return;
        }

        // 토큰 가져오기
        const token = tokenManager.get();
        if (!token) {
            console.warn('⚠️ No token found, cannot connect to WebSocket');
            setConnectionError('인증 토큰이 없습니다.');
            return;
        }

        // WebSocket 연결
        console.log('🔌 Connecting to Fall Alert WebSocket');
        fallWebSocketService.connect(token);

        // 리스너 등록
        unsubscribeRef.current = fallWebSocketService.addListener(handleWebSocketMessage);

        // cleanup
        return () => {
            console.log('🔌 Cleaning up Fall Alert WebSocket');
            if (unsubscribeRef.current) {
                unsubscribeRef.current();
                unsubscribeRef.current = null;
            }
            fallWebSocketService.disconnect();
            setIsConnected(false);
        };
    }, [isAuthenticated, pet, handleWebSocketMessage]);

    // 알림 해제
    const dismissAlert = useCallback(() => {
        console.log('✅ Dismissing fall alert');
        setFallAlert(null);
    }, []);

    // 수동 재연결
    const reconnect = useCallback(() => {
        const token = tokenManager.get();
        if (token) {
            console.log('🔄 Manual reconnection');
            fallWebSocketService.resetReconnection();
            fallWebSocketService.disconnect(false); // 재연결 허용
            fallWebSocketService.connect(token);
        }
    }, []);

    const value = {
        fallAlert,
        dismissAlert,
        isConnected,
        connectionError,
        reconnect,
    };

    return (
        <FallAlertContext.Provider value={value}>
            {children}
        </FallAlertContext.Provider>
    );
};

export default FallAlertProvider;
