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
        <div className="h-full w-full bg-background flex flex-col items-center justify-center p-10">
            <div className="bg-surface rounded-card shadow-card p-16 w-full max-w-2xl">
                {/* 로고 영역 */}
                <div className="flex flex-col items-center mb-12">
                    <img src={logo} alt="No-ill 로고" className="w-48 h-48 object-contain mb-6" />
                    <h1 className="text-8xl font-bold text-text-main mb-4">노일</h1>
                    <p className="text-[#5BA3D0] text-5xl font-semibold mt-2">No-ill</p>
                </div>

                {/* 로그인 폼 */}
                <LoginForm
                    onSubmit={handleLogin}
                    isLoading={isLoading}
                    error={error}
                />

                {/* 안내 문구 */}
                <p className="text-center text-2xl text-text-body mt-10">
                    로봇펫에 표시된 번호를 입력해주세요
                </p>
            </div>
        </div>
    );
};

export default LoginPage;
