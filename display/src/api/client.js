// src/api/client.js

import axios from 'axios';

// 환경별 설정
const isDevelopment = import.meta.env.MODE === 'development';

// 개발 환경에서는 프록시 사용 (빈 문자열)
// 프로덕션 환경에서는 실제 API URL 사용
const getBaseURL = () => {
    if (isDevelopment) {
        return ''; // 프록시 사용
    }
    return import.meta.env.VITE_API_BASE_URL || 'http://i14a301.p.ssafy.io';
};

// 토큰 관리 유틸
const tokenManager = {
    get: () => localStorage.getItem("token"),
    set: (token) => localStorage.setItem("token", token),
    remove: () => localStorage.removeItem("token"),
};

// Axios 인스턴스 생성
const client = axios.create({
    baseURL: getBaseURL(),
    timeout: import.meta.env.VITE_API_TIMEOUT || 10000,
    headers: {
        'Content-Type': 'application/json',
    },
});

// 요청 인터셉터
client.interceptors.request.use((config) => {
    const token = tokenManager.get();
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }

    if (isDevelopment) {
        console.log('🔵 API Request:', config.method?.toUpperCase(), config.url);
        console.log('   Base URL:', config.baseURL);
    }

    return config;
}, (error) => {
    if (isDevelopment) {
        console.error('❌ Request Error:', error);
    }
    return Promise.reject(error);
});

// 응답 인터셉터
client.interceptors.response.use(
    (response) => {
        if (isDevelopment) {
            console.log('✅ API Response:', response.status, response.config.url);
        }
        return response;
    }, (error) => {
        if (isDevelopment) {
            console.error('❌ API Error:', error.response?.status, error.config?.url);
        }

        if (error.response) {
            const {status} = error.response;

            switch (status) {
                case 401:
                    tokenManager.remove();
                    window.dispatchEvent(new CustomEvent('auth:logout'));
                    break;

                case 403:
                    if (isDevelopment) {
                        console.warn('⚠️ 권한이 없습니다.');
                    }
                    break;

                case 404:
                    if (isDevelopment) {
                        console.warn('⚠️ 요청한 리소스를 찾을 수 없습니다.');
                    }
                    break;

                case 500:
                case 502:
                case 503:
                    console.error('🔴 서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
                    break;

                default:
                    break;
            }
        } else if (error.request) {
            console.error('🔴 네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
        }

        return Promise.reject(error);
    }
);

export default client;
export {tokenManager};
