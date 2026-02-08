import React from 'react';
import { Navigate } from 'react-router-dom';
import useAuth from '../../features/auth/hooks/useAuth';

const LoadingSpinner = () => (
    <div className="min-h-screen bg-gradient-to-br from-[#E8F4F8] to-[#D4E8F0] flex items-center justify-center">
        <div className="flex flex-col items-center">
            <div className="w-16 h-16 border-4 border-[#5BA3D0] border-t-transparent rounded-full animate-spin"></div>
            <p className="mt-4 text-[#5BA3D0] text-lg">로딩 중...</p>
        </div>
    </div>
);

const ProtectedRoute = ({ children }) => {
    const { isAuthenticated, isLoading } = useAuth();

    if (isLoading) {
        return <LoadingSpinner />;
    }

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    return children;
};

export default ProtectedRoute;
