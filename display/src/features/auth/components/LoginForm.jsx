import React, { useState } from 'react';

const LoginForm = ({ onSubmit, isLoading, error }) => {
    const [petNo, setPetNo] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();
        if (petNo.trim()) {
            onSubmit(petNo.trim());
        }
    };

    const isValid = petNo.trim().length >= 4;

    return (
        <form onSubmit={handleSubmit} className="w-full">
            <div className="mb-6">
                <label
                    htmlFor="petNo"
                    className="block text-3xl font-semibold text-text-main mb-5"
                >
                    로봇펫 번호
                </label>
                <input
                    type="text"
                    id="petNo"
                    value={petNo}
                    onChange={(e) => setPetNo(e.target.value)}
                    placeholder="로봇펫 번호를 입력하세요"
                    className="w-full px-4 py-4 text-2xl bg-surface border border-border rounded-input focus:border-[#5BA3D0] focus:ring-2 focus:ring-[#5BA3D0]/20 focus:outline-none transition-colors mb-1"
                    disabled={isLoading}
                    autoFocus
                />
                {!isValid && petNo.length > 0 && (
                    <p className="mt-2 text-caption text-danger">
                        4자 이상 입력해주세요
                    </p>
                )}
                {error && (
                    <p className="mt-2 text-caption text-danger">{error}</p>
                )}
            </div>
            <button
                type="submit"
                disabled={!isValid || isLoading}
                className="w-full h-[52px] text-3xl font-semibold text-white bg-[#5BA3D0] rounded-button hover:bg-[#4A90C2] disabled:bg-border disabled:cursor-not-allowed transition-colors shadow-card"
            >
                {isLoading ? '로그인 중...' : '로그인'}
            </button>
        </form>
    );
};

export default LoginForm;
