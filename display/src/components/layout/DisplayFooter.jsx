import React from 'react';

const Footer = () => {
    return (
        <footer style={{
            width: '100%',
            height: 80,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '0 60px',
            background: 'white',
            boxShadow: '0 -2px 8px rgba(0,0,0,0.05)',
            borderTop: '1px solid #e5e7eb',
        }}>
            {/* 왼쪽: 날씨 정보 */}
            <div style={{
                display: 'flex',
                gap: 60,
                alignItems: 'center',
            }}>
                {/* 기온 */}
                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 12,
                }}>
                    <span style={{ fontSize: 32 }}>🌡️</span>
                    <span style={{
                        fontSize: 24,
                        color: '#1a1a1a',
                        fontWeight: '500',
                    }}>
                        현재 기온 18°C
                    </span>
                </div>

                {/* 습도 */}
                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 12,
                }}>
                    <span style={{ fontSize: 32 }}>💧</span>
                    <span style={{
                        fontSize: 24,
                        color: '#1a1a1a',
                        fontWeight: '500',
                    }}>
                        습도 45%
                    </span>
                </div>

                {/* 미세먼지 */}
                <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 12,
                }}>
                    <span style={{ fontSize: 32 }}>💨</span>
                    <span style={{
                        fontSize: 24,
                        color: '#1a1a1a',
                        fontWeight: '500',
                    }}>
                        미세먼지 좋음
                    </span>
                </div>
            </div>

            {/* 오른쪽: 상태 */}
            <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
            }}>
                <div style={{
                    width: 16,
                    height: 16,
                    background: '#10b981',
                    borderRadius: '50%',
                    animation: 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
                }}></div>
                <span style={{
                    fontSize: 24,
                    color: '#1a1a1a',
                    fontWeight: '500',
                }}>
                    노일이 대기 중
                </span>
            </div>
        </footer>
    );
};

export default Footer;
