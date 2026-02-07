import React, {useState} from 'react';
import {useVideoCall} from '../../features/videocall';
import {useAuth} from '../../features/auth';
import {MemoryGameOverlay} from '../../features/minigame';

const CommandsPanel = () => {
    const [showAIHelp, setShowAIHelp] = useState(false);
    const [showGame, setShowGame] = useState(false);
    const [showQuote, setShowQuote] = useState(false);
    const {pet} = useAuth();
    const {startPetCall} = useVideoCall();

    const DAILY_QUOTES = [
        {text: '오늘 하루도 행복하세요', author: null},
        {text: '건강이 최고의 재산입니다', author: null},
        {text: '작은 것에 감사하세요', author: null},
    ];

    const todayQuote = DAILY_QUOTES[new Date().getDate() % DAILY_QUOTES.length];

    const handleVideoCall = async () => {
        console.log('🔵 영상 통화 버튼 클릭');
        console.log('Pet 정보:', pet);

        if (pet?.petId) {
            console.log('✅ Pet으로 보호자 호출:', pet.petId);
            startPetCall();
        } else {
            console.warn('⚠️ Pet 정보 없음');
            alert('로그인 정보를 찾을 수 없습니다.');
        }
    };

    const features = [
        {
            id: 'ai-help',
            icon: '🤖',
            title: 'AI 사용법',
            color: '#5B8FCC',
            onClick: () => setShowAIHelp(true)
        },
        {
            id: 'video-call',
            icon: '📞',
            title: '영상 통화',
            color: '#22c55e',
            onClick: handleVideoCall
        },
        {
            id: 'mini-game',
            icon: '🧠',
            title: '미니 게임',
            color: '#f97316',
            onClick: () => setShowGame(true)
        },
        {
            id: 'daily-quote',
            icon: '💬',
            title: '오늘의 한마디',
            color: '#a855f7',
            onClick: () => setShowQuote(true)
        },
    ];

    const aiCommands = [
        {icon: '☁️', text: '"오늘 날씨 어때?"'},
        {icon: '💊', text: '"아침 약 먹었어"'},
        {icon: '📰', text: '"오늘 뉴스 들려줘"'},
    ];

    return (
        <div style={{
            width: '100%',
            height: '100%',
            background: 'white',
            borderRadius: 20,
            padding: 40,
            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
            display: 'flex',
            flexDirection: 'column',
        }}>
            <h2 style={{
                fontSize: 32,
                fontWeight: 'bold',
                color: '#1a1a1a',
                marginBottom: 30,
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
                    <FeatureButton key={feature.id} feature={feature}/>
                ))}
            </div>

            {/* 미니 게임 오버레이 */}
            {showGame && <MemoryGameOverlay onClose={() => setShowGame(false)}/>}

            {/* 오늘의 한마디 모달 */}
            {showQuote && (
                <div
                    style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        background: 'rgba(0,0,0,0.5)',
                        zIndex: 50,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                    }}
                    onClick={() => setShowQuote(false)}
                >
                    <div
                        style={{
                            background: 'white',
                            borderRadius: 20,
                            padding: 60,
                            width: 800,
                            boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
                            textAlign: 'center',
                        }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <span style={{
                            fontSize: 80,
                            display: 'block',
                            marginBottom: 30,
                        }}>
                            💬
                        </span>
                        <h3 style={{
                            fontSize: 28,
                            fontWeight: 'bold',
                            color: '#6b7280',
                            marginBottom: 24,
                        }}>
                            오늘의 한마디
                        </h3>
                        <p style={{
                            fontSize: 36,
                            fontWeight: 'bold',
                            color: '#1a1a1a',
                            marginBottom: 16,
                            lineHeight: 1.5,
                        }}>
                            "{todayQuote.text}"
                        </p>
                        {todayQuote.author && (
                            <p style={{
                                fontSize: 24,
                                color: '#6b7280',
                                marginBottom: 30,
                            }}>
                                - {todayQuote.author}
                            </p>
                        )}
                        <button
                            onClick={() => setShowQuote(false)}
                            style={{
                                width: '100%',
                                padding: '16px 0',
                                background: '#a855f7',
                                color: 'white',
                                fontSize: 24,
                                fontWeight: 'bold',
                                borderRadius: 16,
                                border: 'none',
                                cursor: 'pointer',
                                marginTop: 24,
                                transition: 'background 0.2s',
                            }}
                            onMouseEnter={(e) => e.currentTarget.style.background = '#9333ea'}
                            onMouseLeave={(e) => e.currentTarget.style.background = '#a855f7'}
                        >
                            닫기
                        </button>
                    </div>
                </div>
            )}

            {/* AI 사용법 모달 */}
            {showAIHelp && (
                <div
                    style={{
                        position: 'fixed',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        background: 'rgba(0,0,0,0.5)',
                        zIndex: 50,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                    }}
                    onClick={() => setShowAIHelp(false)}
                >
                    <div
                        style={{
                            background: 'white',
                            borderRadius: 20,
                            padding: 50,
                            width: 800,
                            boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
                        }}
                        onClick={(e) => e.stopPropagation()}
                    >
                        <h3 style={{
                            fontSize: 36,
                            fontWeight: 'bold',
                            color: '#1a1a1a',
                            marginBottom: 30,
                            textAlign: 'center',
                        }}>
                            🤖 이렇게 말해보세요
                        </h3>
                        <div style={{
                            display: 'flex',
                            flexDirection: 'column',
                            gap: 16,
                            marginBottom: 30,
                        }}>
                            {aiCommands.map((command, index) => (
                                <div
                                    key={index}
                                    style={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        gap: 16,
                                        padding: '20px 24px',
                                        background: '#f5f5f5',
                                        borderRadius: 16,
                                    }}
                                >
                                    <span style={{fontSize: 36}}>{command.icon}</span>
                                    <span style={{
                                        fontSize: 22,
                                        fontWeight: '600',
                                        color: '#1a1a1a',
                                    }}>
                                        {command.text}
                                    </span>
                                </div>
                            ))}
                        </div>
                        <button
                            onClick={() => setShowAIHelp(false)}
                            style={{
                                width: '100%',
                                padding: '16px 0',
                                background: '#5B8FCC',
                                color: 'white',
                                fontSize: 24,
                                fontWeight: 'bold',
                                borderRadius: 16,
                                border: 'none',
                                cursor: 'pointer',
                                transition: 'background 0.2s',
                            }}
                            onMouseEnter={(e) => e.currentTarget.style.background = '#4a7ab8'}
                            onMouseLeave={(e) => e.currentTarget.style.background = '#5B8FCC'}
                        >
                            닫기
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

// ⭐ 버튼 컴포넌트 분리 (hover 문제 해결)
const FeatureButton = ({feature}) => {
    const [isHovered, setIsHovered] = useState(false);

    return (
        <button
            onClick={feature.onClick}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            style={{
                background: feature.color,
                borderRadius: 20,
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 16,
                padding: 24,
                color: 'white',
                border: 'none',
                cursor: 'pointer',
                boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                transition: 'transform 0.2s, opacity 0.2s',
                opacity: isHovered ? 0.9 : 1,
                transform: isHovered ? 'scale(1.02)' : 'scale(1)',
            }}
        >
            <span style={{fontSize: 56, pointerEvents: 'none'}}>{feature.icon}</span>
            <span style={{
                fontSize: 22,
                fontWeight: 'bold',
                pointerEvents: 'none',
            }}>
                {feature.title}
            </span>
        </button>
    );
};

export default CommandsPanel;
