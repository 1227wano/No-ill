// src/features/auth/services/authApi.js

import client from '../../../api/client';

/**
 * 펫 로그인
 * @param {string} petId - 펫 ID
 * @param {string|null} fcmToken - FCM 토큰 (선택)
 */
const login = async (petId, fcmToken = null) => {
    const requestBody = {petId};

    if (fcmToken) {
        requestBody.fcmToken = fcmToken;
    }

    const response = await client.post('/api/auth/pets/login', requestBody);
    const data = response.data;

    return {
        token: {
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
        },
        pet: {
            petNo: data.petNo,
            petId: data.petId,
            petName: data.petName,
        },
    };
};

/**
 * 토큰 검증
 */
const verifyToken = async () => {
    const response = await client.get('/api/auth/pets/verify');
    const data = response.data.data;

    return {
        petNo: data.petNo,
        petId: data.petId,
        petName: data.petName,
    };
}

/**
 * 토큰 갱신
 */
const refreshToken = async (refreshToken) => {
    const response = await client.post('/api/auth/pets/refresh', {
        refreshToken,
    });
    const data = response.data;

    return {
        accessToken: data.accessToken,
        refreshToken: data.refreshToken,
    };
};

export const authApi = {
    login,
    verifyToken,
    refreshToken,
};

export {login, verifyToken, refreshToken};
