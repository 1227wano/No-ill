// src/features/auth/components/LoginForm.jsx

import React, { useState } from 'react';

const LoginForm = ({ onSubmit, isLoading, error }) => {
    const [petId, setPetId] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();
        if (petId.trim() && isValid) {
            onSubmit(petId.trim());
        }
    };

    const isValid = petId.trim().length >= 4;

    return (
        <form onSubmit={handleSubmit} style={{ width: '100%' }} noValidate>
            <div style={{ marginBottom: 24 }}>
                <label
                    htmlFor="petId"
                    style={{
                        display: 'block',
                        fontSize: 28,
                        fontWeight: '600',
                        color: '#1a1a1a',
                        marginBottom: 20,
                    }}
                >
                    로봇펫 번호
                </label>
                <input
                    type="text"
                    id="petId"
                    value={petId}
                    onChange={(e) => setPetId(e.target.value)}
                    placeholder="로봇펫 번호를 입력하세요"
                    style={{
                        width: '100%',
                        padding: '16px',
                        fontSize: 22,
                        background: 'white',
                        border: '1px solid #e5e7eb',
                        borderRadius: 12,
                        outline: 'none',
                        transition: 'border-color 0.2s, box-shadow 0.2s',
                        marginBottom: 4,
                    }}
                    onFocus={(e) => {
                        e.target.style.borderColor = '#5BA3D0';
                        e.target.style.boxShadow = '0 0 0 3px rgba(91, 163, 208, 0.2)';
                    }}
                    onBlur={(e) => {
                        e.target.style.borderColor = '#e5e7eb';
                        e.target.style.boxShadow = 'none';
                    }}
                    disabled={isLoading}
                    autoFocus
                />
                {!isValid && petId.length > 0 && (
                    <p style={{
                        marginTop: 8,
                        fontSize: 16,
                        color: '#ef4444',
                    }}>
                        4자 이상 입력해주세요
                    </p>
                )}
                {error && (
                    <p style={{
                        marginTop: 8,
                        fontSize: 16,
                        color: '#ef4444',
                    }}>
                        {error}
                    </p>
                )}
            </div>
            <button
                type="submit"
                disabled={!isValid || isLoading}
                style={{
                    width: '100%',
                    height: 56,
                    fontSize: 24,
                    fontWeight: '600',
                    color: 'white',
                    background: !isValid || isLoading ? '#e5e7eb' : '#5BA3D0',
                    borderRadius: 16,
                    border: 'none',
                    cursor: !isValid || isLoading ? 'not-allowed' : 'pointer',
                    transition: 'background 0.2s',
                    boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                }}
                onMouseEnter={(e) => {
                    if (isValid && !isLoading) {
                        e.target.style.background = '#4A90C2';
                    }
                }}
                onMouseLeave={(e) => {
                    if (isValid && !isLoading) {
                        e.target.style.background = '#5BA3D0';
                    }
                }}
            >
                {isLoading ? '로그인 중...' : '로그인'}
            </button>
        </form>
    );
};

export default LoginForm;
