import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import LoginForm from '../features/auth/components/LoginForm';
import useAuth from '../features/auth/hooks/useAuth';

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
        <div className="min-h-screen bg-background flex flex-col items-center justify-center p-6">
            <div className="bg-surface rounded-card shadow-card p-10 w-full max-w-md">
                {/* 로고 영역 */}
                <div className="flex flex-col items-center mb-8">
                    <div className="w-24 h-24 bg-[#5BA3D0] rounded-full flex items-center justify-center shadow-card mb-4">
                        <div className="w-16 h-16 bg-surface rounded-full relative flex items-center justify-center">
                            <div className="w-2.5 h-2.5 bg-[#5BA3D0] rounded-full absolute top-[22px] left-[18px]"></div>
                            <div className="w-2.5 h-2.5 bg-[#5BA3D0] rounded-full absolute top-[22px] right-[18px]"></div>
                            <div className="w-5 h-2.5 border-2 border-[#5BA3D0] border-t-0 rounded-b-[20px] absolute bottom-[18px] left-1/2 -translate-x-1/2"></div>
                        </div>
                    </div>
                    <h1 className="text-h1 text-text-main">노일</h1>
                    <p className="text-[#5BA3D0] text-body mt-1">No-ill</p>
                </div>

                {/* 로그인 폼 */}
                <LoginForm
                    onSubmit={handleLogin}
                    isLoading={isLoading}
                    error={error}
                />

                {/* 안내 문구 */}
                <p className="text-center text-caption text-text-body mt-6">
                    로봇펫에 표시된 번호를 입력해주세요
                </p>
            </div>
        </div>
    );
};

export default LoginPage;
