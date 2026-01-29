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
        <form onSubmit={handleSubmit} className="w-full max-w-sm">
            <div className="mb-6">
                <label
                    htmlFor="petNo"
                    className="block text-lg font-medium text-gray-700 mb-2"
                >
                    로봇펫 번호
                </label>
                <input
                    type="text"
                    id="petNo"
                    value={petNo}
                    onChange={(e) => setPetNo(e.target.value)}
                    placeholder="로봇펫 번호를 입력하세요"
                    className="w-full px-4 py-3 text-lg border-2 border-gray-200 rounded-xl focus:border-[#5BA3D0] focus:outline-none transition-colors"
                    disabled={isLoading}
                    autoFocus
                />
                {!isValid && petNo.length > 0 && (
                    <p className="mt-2 text-sm text-orange-500">
                        4자 이상 입력해주세요
                    </p>
                )}
                {error && (
                    <p className="mt-2 text-sm text-red-500">{error}</p>
                )}
            </div>
            <button
                type="submit"
                disabled={!isValid || isLoading}
                className="w-full py-4 text-xl font-semibold text-white bg-[#5BA3D0] rounded-xl hover:bg-[#4A90C2] disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors shadow-lg"
            >
                {isLoading ? '로그인 중...' : '로그인'}
            </button>
        </form>
    );
};

export default LoginForm;
