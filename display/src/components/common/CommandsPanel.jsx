import React, {useState} from 'react';
import {useVideoCall} from '../../features/videocall';
import {useAuth} from '../../features/auth';
import {MemoryGameOverlay} from '../../features/minigame';

const CommandsPanel = () => {
    const [showAIHelp, setShowAIHelp] = useState(false);
    const [showGame, setShowGame] = useState(false);
    const [showQuote, setShowQuote] = useState(false);
    const {startCall, startPetCall} = useVideoCall();
    const {user} = useAuth();

    const DAILY_QUOTES = [
        {text: '웃음은 최고의 명약이다.', author: '속담'},
        {text: '천 리 길도 한 걸음부터.', author: '노자'},
        {text: '오늘 하루도 감사한 마음으로.', author: ''},
        {text: '건강이 가장 큰 재산입니다.', author: '속담'},
        {text: '행복은 멀리 있지 않아요.', author: ''},
        {text: '늦었다고 생각할 때가 가장 빠르다.', author: '속담'},
        {text: '꽃이 피듯, 오늘도 아름다운 하루.', author: ''},
        {text: '작은 것에 감사하면 큰 행복이 온다.', author: ''},
        {text: '사랑하는 사람이 있어 행복합니다.', author: ''},
        {text: '오늘의 나는 어제보다 더 멋져요.', author: ''},
        {text: '따뜻한 차 한잔의 여유를 즐기세요.', author: ''},
        {text: '가족이 있어 든든합니다.', author: ''},
        {text: '좋은 생각이 좋은 하루를 만듭니다.', author: ''},
        {text: '느리더라도 꾸준히 걸으면 됩니다.', author: ''},
        {text: '미소는 마음의 햇살이에요.', author: ''},
        {text: '매일 조금씩 나아가면 충분해요.', author: ''},
        {text: '비 온 뒤에 땅이 굳어진다.', author: '속담'},
        {text: '오늘도 사랑받고 있다는 걸 기억하세요.', author: ''},
        {text: '고생 끝에 낙이 온다.', author: '속담'},
        {text: '하루하루가 소중한 선물이에요.', author: ''},
        {text: '될 때까지 하면 된다.', author: '이순신'},
        {text: '마음이 편안하면 몸도 건강해요.', author: ''},
        {text: '지금 이 순간이 가장 젊은 날이에요.', author: ''},
        {text: '함께라서 더 행복한 하루.', author: ''},
        {text: '맑은 공기를 마시며 산책해보세요.', author: ''},
        {text: '어제의 걱정은 내려놓으세요.', author: ''},
        {text: '소소한 일상이 가장 큰 행복이에요.', author: ''},
        {text: '당신은 충분히 잘 하고 있어요.', author: ''},
        {text: '좋아하는 노래 한 곡 들어보세요.', author: ''},
        {text: '내일은 오늘보다 더 좋은 날이 될 거예요.', author: ''},
        {text: '세상에서 가장 소중한 건 건강이에요.', author: ''},
    ];

    const todayQuote = DAILY_QUOTES[new Date().getDate() % DAILY_QUOTES.length];

    const handleVideoCall = async () => {
        // Pet 로그인 확인
        if (user?.isPet || user?.petId) {
            startPetCall();
            return;
        }

        // User 로그인: 기존 로직
        const userId = user?.userId || user?.userNo;
        if (userId) {
            startCall(userId);
        } else {
            alert('사용자 정보를 찾을 수 없습니다.');
        }
    };

    const features = [
        {
            id: 'ai-help',
            icon: '🤖',
            title: 'AI 사용법',
            color: 'bg-primary',
            onClick: () => setShowAIHelp(true)
        },
        {
            id: 'video-call',
            icon: '📞',
            title: '영상 통화',
            color: 'bg-green-500',
            onClick: handleVideoCall
        },
        {
            id: 'mini-game',
            icon: '🧠',
            title: '미니 게임',
            color: 'bg-orange-500',
            onClick: () => setShowGame(true)
        },
        {
            id: 'daily-quote',
            icon: '💬',
            title: '오늘의 한마디',
            color: 'bg-purple-500',
            onClick: () => setShowQuote(true)
        },
    ];

    const aiCommands = [
        {icon: '☁️', text: '"오늘 날씨 어때?"'},
        {icon: '💊', text: '"아침 약 먹었어"'},
        {icon: '📰', text: '"오늘 뉴스 들려줘"'},
    ];

    return (
        <div className="bg-surface rounded-card p-8 shadow-card h-full flex flex-col">
            <h2 className="text-4xl font-bold text-text-main mb-8">빠른 메뉴</h2>

            {/* 기능 버튼 그리드 */}
            <div className="grid grid-cols-2 gap-5 flex-1">
                {features.map((feature) => (
                    <button
                        key={feature.id}
                        onClick={feature.onClick}
                        className={`${feature.color} rounded-card flex flex-col items-center justify-center gap-4 p-6 text-white shadow-card hover:opacity-90 hover:scale-[1.02] transition-all`}
                    >
                        <span className="text-6xl">{feature.icon}</span>
                        <span className="text-2xl font-bold">{feature.title}</span>
                    </button>
                ))}
            </div>

            {/* 미니 게임 오버레이 */}
            {showGame && <MemoryGameOverlay onClose={() => setShowGame(false)}/>}

            {/* 오늘의 한마디 모달 */}
            {showQuote && (
                <div
                    className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-10"
                    onClick={() => setShowQuote(false)}
                >
                    <div
                        className="bg-surface rounded-card p-12 max-w-2xl w-full shadow-card text-center"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <span className="text-8xl block mb-8">💬</span>
                        <h3 className="text-3xl font-bold text-text-body mb-6">오늘의 한마디</h3>
                        <p className="text-4xl font-bold text-text-main mb-4 leading-relaxed">
                            "{todayQuote.text}"
                        </p>
                        {todayQuote.author && (
                            <p className="text-2xl text-text-body mb-8">- {todayQuote.author}</p>
                        )}
                        <button
                            onClick={() => setShowQuote(false)}
                            className="w-full py-4 bg-purple-500 text-white text-2xl font-bold rounded-card hover:bg-purple-600 transition-colors mt-6"
                        >
                            닫기
                        </button>
                    </div>
                </div>
            )}

            {/* AI 사용법 모달 */}
            {showAIHelp && (
                <div
                    className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-10"
                    onClick={() => setShowAIHelp(false)}
                >
                    <div
                        className="bg-surface rounded-card p-10 max-w-2xl w-full shadow-card"
                        onClick={(e) => e.stopPropagation()}
                    >
                        <h3 className="text-4xl font-bold text-text-main mb-8 text-center">
                            🤖 이렇게 말해보세요
                        </h3>
                        <div className="flex flex-col gap-4 mb-8">
                            {aiCommands.map((command, index) => (
                                <div
                                    key={index}
                                    className="flex items-center gap-4 px-6 py-5 bg-background rounded-card"
                                >
                                    <span className="text-4xl">{command.icon}</span>
                                    <span className="text-2xl font-semibold text-text-main">{command.text}</span>
                                </div>
                            ))}
                        </div>
                        <button
                            onClick={() => setShowAIHelp(false)}
                            className="w-full py-4 bg-primary text-white text-2xl font-bold rounded-card hover:bg-primary/90 transition-colors"
                        >
                            닫기
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
};

export default CommandsPanel;
