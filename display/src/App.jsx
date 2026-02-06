import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useEffect } from 'react';  // 추가!
import { AuthProvider, useAuth } from './features/auth';  // useAuth 추가!
import { FallAlertProvider, FallAlertOverlay } from './features/fall';
import { VideoCallProvider, VideoCallOverlay, IncomingCallOverlay } from './features/videocall';
import { requestFcmToken, registerFcmToken } from './features/videocall/services/fcmService';  // 추가!
import ProtectedRoute from './components/common/ProtectedRoute';
import FixedLayout from './components/common/FixedLayout';
import DisplayPage from './pages/DisplayPage';
import LoginPage from './pages/LoginPage';
import './App.css';

// 내부 컴포넌트로 분리 (useAuth를 사용하기 위해)
function AppContent() {
    const { isAuthenticated, user } = useAuth();

    useEffect(() => {
        if (isAuthenticated) {
            const timer = setTimeout(async () => {
                const permission = Notification.permission;

                if (permission === 'default') {
                    const userConfirm = window.confirm(
                        '화상통화 알림을 받으시겠습니까?\n(알림을 허용하면 통화 요청을 받을 수 있습니다)'
                    );

                    if (userConfirm) {
                        const token = await requestFcmToken();
                        if (token) {
                            // petId 제거 - 서버가 알아서 처리
                            await registerFcmToken(token);
                        }
                    }
                } else if (permission === 'granted') {
                    const token = await requestFcmToken();
                    if (token) {
                        // petId 제거
                        await registerFcmToken(token);
                    }
                }
            }, 1000);

            return () => clearTimeout(timer);
        }
    }, [isAuthenticated, user]);  // user 의존성은 유지


    return (
        <>
            <FixedLayout>
            <FallAlertOverlay />
            <VideoCallOverlay />
            <IncomingCallOverlay />
                <Routes>
                    <Route path="/login" element={<LoginPage />} />
                    <Route
                        path="/"
                        element={
                            <ProtectedRoute>
                                <DisplayPage />
                            </ProtectedRoute>
                        }
                    />
                    <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
            </FixedLayout>
        </>
    );
}

function App() {
    return (
        <BrowserRouter>
            <AuthProvider>
                <FallAlertProvider>
                    <VideoCallProvider>
                        <AppContent />
                    </VideoCallProvider>
                </FallAlertProvider>
            </AuthProvider>
        </BrowserRouter>
    );
}

export default App;
