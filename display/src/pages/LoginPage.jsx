// src/pages/LoginPage.jsx

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import LoginForm from '../features/auth/components/LoginForm';
import useAuth from '../features/auth/hooks/useAuth';
import logo from '@/assets/no-ill-logo.png';

const LoginPage = () => {
    const navigate = useNavigate();
    const { login, isAuthenticated } = useAuth();
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState('');

    // 이미 로그인된 경우 메인으로 리다이렉트
    React.useEffect(() => {
        if (isAuthenticated) {
            navigate('/', { replace: true });
        }
    }, [isAuthenticated, navigate]);

    const handleLogin = async (petNo) => {
        setIsLoading(true);
        setError('');

        try {
            await login(petNo);
            navigate('/', { replace: true });
        } catch (err) {
            setError(err.message || '로그인에 실패했습니다.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div style={{
            width: 1920,
            height: 1080,
            background: '#f5f5f5',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: 60,
        }}>
            <div style={{
                background: 'white',
                borderRadius: 20,
                boxShadow: '0 8px 24px rgba(0,0,0,0.1)',
                padding: 80,
                width: 800,
            }}>
                {/* 로고 영역 */}
                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    marginBottom: 60,
                }}>
                    <img
                        src={logo}
                        alt="No-ill 로고"
                        style={{
                            width: 160,
                            height: 160,
                            objectFit: 'contain',
                            marginBottom: 30,
                        }}
                    />
                    <h1 style={{
                        fontSize: 72,
                        fontWeight: 'bold',
                        color: '#1a1a1a',
                        marginBottom: 16,
                    }}>
                        노일
                    </h1>
                    <p style={{
                        color: '#5BA3D0',
                        fontSize: 40,
                        fontWeight: '600',
                        marginTop: 8,
                    }}>
                        No-ill
                    </p>
                </div>

                {/* 로그인 폼 */}
                <LoginForm
                    onSubmit={handleLogin}
                    isLoading={isLoading}
                    error={error}
                />

                {/* 안내 문구 */}
                <p style={{
                    textAlign: 'center',
                    fontSize: 20,
                    color: '#6b7280',
                    marginTop: 40,
                }}>
                    로봇펫에 표시된 번호를 입력해주세요
                </p>
            </div>
        </div>
    );
};

export default LoginPage;
