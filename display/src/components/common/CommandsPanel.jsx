import React, { useState } from 'react';
import { useVideoCall } from '../../features/videocall';
import { useAuth } from '../../features/auth';
import { MemoryGameOverlay } from '../../features/minigame';

const CommandsPanel = () => {
    const [showAIHelp, setShowAIHelp] = useState(false);
    const [showGame, setShowGame] = useState(false);
    const [showQuote, setShowQuote] = useState(false);
    const { pet } = useAuth();
    const { startPetCall } = useVideoCall();

    const DAILY_QUOTES = [
        { text: '오늘 하루도 행복하세요', author: null },
        { text: '건강이 최고의 재산입니다', author: null },
        { text: '작은 것에 감사하세요', author: null },
    ];

    const todayQuote = DAILY_QUOTES[new Date().getDate() % DAILY_QUOTES.length];

    const handleVideoCall = async () => {
        if (pet?.petId) {
            startPetCall();
        } else {
            alert('로그인 정보를 찾을 수 없습니다.');
        }
    };

    // ✅ 노일 브랜드 컬러 팔레트로 색상 통일
    const features = [
        {
            id: 'ai-help',
            icon: '🤖',
            title: '노일이 사용법',
            color: 'var(--pastel-blue)', // Primary (메인 하늘색)
            onClick: () => setShowAIHelp(true)
        },
        {
            id: 'video-call',
            icon: '📞',
            title: '영상 통화',
            color: 'var(--pastel-green)', // Light Sky Blue
            onClick: handleVideoCall
        },
        {
            id: 'mini-game',
            icon: '🧠',
            title: '미니 게임',
            color: 'var(--pastel-orange)', // Deep Blue
            onClick: () => setShowGame(true)
        },
        {
            id: 'daily-quote',
            icon: '💬',
            title: '오늘의 한마디',
            color: 'var(--pastel-purple)', // Soft Pastel Blue
            onClick: () => setShowQuote(true)
        },
    ];

    const aiCommands = [
        { icon: '☁️', text: '"오늘 날씨 어때?"' },
        { icon: '💊', text: '"아침 약 먹었어"' },
        { icon: '📰', text: '"오늘 뉴스 들려줘"' },
    ];

    return (
        <div style={{
            width: '100%',
            height: '100%',
            background: 'var(--color-surface)', // White
            borderRadius: 'var(--radius-card)', // 16px
            padding: 40,
            boxShadow: 'var(--shadow-card)', // 부드러운 그림자
            display: 'flex',
            flexDirection: 'column',
        }}>
            <h2 style={{
                fontSize: 32,
                fontWeight: 'bold',
                color: 'var(--color-text-main)',
                marginBottom: 30,
                fontFamily: 'var(--font-family)', // Pretendard
            }}>
                빠른 메뉴
            </h2>

            {/* 기능 버튼 그리드 */}
            <div style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gridTemplateRows: '1fr 1fr',
                gap: 20,
                flex: 1,
            }}>
                {features.map((feature) => (
                    <FeatureButton key={feature.id} feature={feature} />
                ))}
            </div>

            {/* 미니 게임 오버레이 */}
            {showGame && <MemoryGameOverlay onClose={() => setShowGame(false)} />}

            {/* 오늘의 한마디 & AI 사용법 모달 (디자인 시스템 적용) */}
            {(showQuote || showAIHelp) && (
                <div style={modalOverlayStyle} onClick={() => { setShowQuote(false); setShowAIHelp(false); }}>
                    <div style={modalContentStyle} onClick={(e) => e.stopPropagation()}>
                        {showQuote ? (
                            <QuoteContent todayQuote={todayQuote} onClose={() => setShowQuote(false)} />
                        ) : (
                            <AIHelpContent aiCommands={aiCommands} onClose={() => setShowAIHelp(false)} />
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

// --- 서브 컴포넌트 및 스타일 ---

// 세련된 감각의 FeatureButton
const FeatureButton = ({ feature }) => {
    const [isHovered, setIsHovered] = useState(false);

    return (
        <button
            onClick={feature.onClick}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            style={{
                // ✅ 단색 대신 부드러운 그라데이션 적용
                background: `linear-gradient(135deg, ${feature.color} 0%, ${feature.secondaryColor || feature.color} 100%)`,
                borderRadius: '32px', // 더 둥글게 만들어 귀여운 느낌 강조
                position: 'relative',
                overflow: 'hidden',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                padding: '30px',
                border: 'none',
                cursor: 'pointer',
                // ✅ 버튼 색상을 머금은 부드러운 그림자
                boxShadow: isHovered 
                    ? `0 20px 40px ${feature.color}40` 
                    : `0 10px 20px rgba(0,0,0,0.05)`,
                transition: 'all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)', // 쫀득한 애니메이션
                transform: isHovered ? 'scale(1.05) translateY(-10px)' : 'scale(1)',
            }}
        >
            {/* 배경에 은은한 원형 패턴 추가 (디테일) */}
            <div style={{
                position: 'absolute', top: -20, right: -20, width: 100, height: 100,
                background: 'rgba(255,255,255,0.1)', borderRadius: '50%'
            }} />

            <span style={{ 
                fontSize: 80, // 아이콘을 더 과감하게 키움
                marginBottom: 20,
                filter: 'drop-shadow(0 10px 10px rgba(0,0,0,0.1))' 
            }}>{feature.icon}</span>
            
            <span style={{ 
                fontSize: 28, 
                fontWeight: '800', 
                color: 'white',
                letterSpacing: '-0.5px',
                fontFamily: 'var(--font-family)' // Pretendard
            }}>
                {feature.title}
            </span>
        </button>
    );
};

// 공통 모달 스타일
const modalOverlayStyle = {
    position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
    background: 'rgba(0,0,0,0.4)', zIndex: 100,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
};

const modalContentStyle = {
    background: 'white', borderRadius: 32, padding: 60, width: 800,
    boxShadow: '0 20px 40px rgba(0,0,0,0.2)', textAlign: 'center',
};

const QuoteContent = ({ todayQuote, onClose }) => (
    <>
        <span style={{ fontSize: 80, display: 'block', marginBottom: 20 }}>💬</span>
        <p style={{ fontSize: 42, fontWeight: 'bold', lineHeight: 1.4, marginBottom: 40 }}>
            "{todayQuote.text}"
        </p>
        <button onClick={onClose} style={closeButtonStyle}>닫기</button>
    </>
);

const AIHelpContent = ({ aiCommands, onClose }) => (
    <>
        <h3 className="font-keris" style={{ fontSize: 42, color: 'var(--color-primary)', marginBottom: 40 }}>
            노일이에게 물어보세요
        </h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20, marginBottom: 40 }}>
            {aiCommands.map((cmd, i) => (
                <div key={i} style={{ background: '#f8f9fa', padding: 24, borderRadius: 20, fontSize: 28, fontWeight: 'bold', display: 'flex', gap: 20 }}>
                    <span>{cmd.icon}</span> {cmd.text}
                </div>
            ))}
        </div>
        <button onClick={onClose} style={closeButtonStyle}>알겠어!</button>
    </>
);

const closeButtonStyle = {
    width: '100%', padding: '20px 0', background: 'var(--color-primary)',
    color: 'white', fontSize: 28, fontWeight: 'bold', borderRadius: 20,
    border: 'none', cursor: 'pointer'
};

export default CommandsPanel;