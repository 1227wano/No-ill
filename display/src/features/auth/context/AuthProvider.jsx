import React, { useState, useCallback } from 'react';
import { AuthContext } from './AuthContext';
import { login as loginApi } from '../services/authApi';
import { requestFcmToken, registerFcmToken } from '../../videocall/services/fcmService';

const getInitialUser = () => {
    const token = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    if (token && savedUser) {
        try {
            return JSON.parse(savedUser);
        } catch {
            localStorage.removeItem('token');
            localStorage.removeItem('user');
        }
    }
    return null;
};

const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(getInitialUser);
    const [isLoading] = useState(false);

    const isAuthenticated = !!user;

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
