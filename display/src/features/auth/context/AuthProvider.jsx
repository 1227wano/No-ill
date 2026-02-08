// src/features/auth/context/AuthProvider.jsx

import React, {useState, useCallback, useEffect} from 'react';
import {AuthContext} from './AuthContext';
import {authApi} from '../services/authApi';
import {tokenManager} from '@/api/client.js';
import {requestFcmToken, registerFcmToken} from '../../videocall/services/fcmService';

const getInitialPet = () => {
    const token = tokenManager.get();
    const savedPet = localStorage.getItem('pet');

    if (token && savedPet) {
        try {
            return JSON.parse(savedPet);
        } catch {
            tokenManager.remove();
            localStorage.removeItem('pet');
        }
    }
    return null;
};

const AuthProvider = ({children}) => {
    const [pet, setPet] = useState(getInitialPet);
    const [isLoading, setIsLoading] = useState(false);
    const [isInitializing, setIsInitializing] = useState(false);

    const isAuthenticated = !!pet;

    // 초기 토큰 검증
    useEffect(() => {
        const verifyInitialToken = async () => {
            const token = tokenManager.get();

            if (token && pet) {
                try {
                    const data = await authApi.verifyToken();
                    setPet(data);
                    localStorage.setItem('pet', JSON.stringify(data));
                } catch (error) {
                    console.error('토큰 검증 실패:', error);

                    // 토큰이 유효하지 않으면 로그아웃
                    tokenManager.remove();
                    localStorage.removeItem('pet');
                    setPet(null);
                }
            }

            setIsInitializing(false);
        };

        verifyInitialToken();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);




    // auth:logout 이벤트 리스너 (client.js에서 발생)
    useEffect(() => {
        const handleAuthLogout = () => {
            localStorage.removeItem('pet');
            setPet(null);
        };

        window.addEventListener('auth:logout', handleAuthLogout);

        return () => {
            window.removeEventListener('auth:logout', handleAuthLogout);
        };
    }, [])

    const login = useCallback(async (petId) => {
        setIsLoading(true);

        try {
            // 1. FCM 토큰 요청
            let fcmToken = null;
            try {
                fcmToken = await requestFcmToken();
            } catch (fcmError) {
                console.warn('FCM 토큰 요청 실패 (계속 진행):', fcmError);
            }

            // 2. 로그인
            const {token, pet: petData} = await authApi.login(petId, fcmToken);

            // 3. 토큰 저장
            tokenManager.set(token.accessToken);
            localStorage.setItem('refreshToken', token.refreshToken);
            localStorage.setItem('pet', JSON.stringify(petData));

            setPet(petData);

            // 4. FCM 토큰 등록
            if (fcmToken) {
                try {
                    await registerFcmToken(fcmToken);
                } catch (fcmError) {
                    console.error('FCM 토큰 등록 실패:', fcmError);
                }
            }

            return petData;
        } catch (error) {
            console.error('로그인 실패:', error);
            throw error;
        } finally {
            setIsLoading(false);
        }
    }, []);

    const logout = useCallback(() => {
        tokenManager.remove();
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('pet');
        setPet(null);
    }, []);

    const value = {
        pet,
        isAuthenticated,
        isLoading,
        isInitializing,
        login,
        logout,
    };

    if (isInitializing) {
        return null; // 또는 <LoadingSpinner />
    }

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export default AuthProvider;
