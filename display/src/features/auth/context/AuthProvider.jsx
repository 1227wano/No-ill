import React, { useState, useEffect, useCallback } from 'react';
import { AuthContext } from './AuthContext';
import { login as loginApi, verifyToken } from '../services/authApi';
import { requestFcmToken, registerFcmToken } from '../../videocall/services/fcmService';

const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [isLoading, setIsLoading] = useState(true);

    const isAuthenticated = !!user;

    // 앱 시작 시 토큰 검증
    useEffect(() => {
        let ignore = false;

        const checkAuth = async () => {
            const token = localStorage.getItem('token');
            const savedUser = localStorage.getItem('user');

            if (!token) {
                setIsLoading(false);
                return;
            }

            try {
                const userData = await verifyToken();
                if (!ignore) {
                    setUser(userData);
                    localStorage.setItem('user', JSON.stringify(userData));
                }
            } catch (error) {
                console.error('Token verification failed:', error);
                // verify 실패해도 저장된 user 정보가 있으면 사용
                if (savedUser) {
                    try {
                        const parsedUser = JSON.parse(savedUser);
                        if (!ignore) {
                            setUser(parsedUser);
                        }
                    } catch {
                        localStorage.removeItem('token');
                        localStorage.removeItem('user');
                    }
                } else {
                    localStorage.removeItem('token');
                }
            } finally {
                if (!ignore) {
                    setIsLoading(false);
                }
            }
        };

        checkAuth();

        return () => {
            ignore = true;
        };
    }, []);

    const login = useCallback(async (petNo) => {
        const { token, user: userData } = await loginApi(petNo);
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(userData));
        setUser(userData);

        // FCM 토큰 등록
        try {
            const fcmToken = await requestFcmToken();
            if (fcmToken) {
                const petId = userData.petId || petNo;
                await registerFcmToken(fcmToken, petId);
            }
        } catch (error) {
            console.error('FCM 토큰 등록 실패:', error);
        }

        return userData;
    }, []);

    const logout = useCallback(() => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setUser(null);
    }, []);

    const value = {
        user,
        isAuthenticated,
        isLoading,
        login,
        logout,
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export default AuthProvider;
