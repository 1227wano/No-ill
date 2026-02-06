import React, { useState, useCallback } from 'react';

const EMOJI_POOL = ['🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🐨', '🦁', '🐸', '🌸', '🌻', '⭐', '🍎', '🍊', '🎵', '❤️'];

const shuffle = (array) => {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
};

const generateCards = (pairCount) => {
    const selected = shuffle(EMOJI_POOL).slice(0, pairCount);
    const pairs = [...selected, ...selected];
    return shuffle(pairs).map((emoji, index) => ({
        id: index,
        emoji,
        flipped: false,
        matched: false,
    }));
};

const MemoryGameOverlay = ({ onClose }) => {
    const [cards, setCards] = useState(() => generateCards(6));
    const [selected, setSelected] = useState([]);
    const [moves, setMoves] = useState(0);
    const [matchedCount, setMatchedCount] = useState(0);
    const [isChecking, setIsChecking] = useState(false);
    const totalPairs = 6;

    const gameComplete = matchedCount === totalPairs;

    const handleCardClick = useCallback((id) => {
        if (isChecking) return;

        const card = cards.find((c) => c.id === id);
        if (!card || card.flipped || card.matched) return;

        const newCards = cards.map((c) =>
            c.id === id ? { ...c, flipped: true } : c
        );
        setCards(newCards);

        const newSelected = [...selected, id];
        setSelected(newSelected);

        if (newSelected.length === 2) {
            setMoves((m) => m + 1);
            setIsChecking(true);

            const [firstId, secondId] = newSelected;
            const first = newCards.find((c) => c.id === firstId);
            const second = newCards.find((c) => c.id === secondId);

            if (first.emoji === second.emoji) {
                setTimeout(() => {
                    setCards((prev) =>
                        prev.map((c) =>
                            c.id === firstId || c.id === secondId
                                ? { ...c, matched: true }
                                : c
                        )
                    );
                    setMatchedCount((m) => m + 1);
                    setSelected([]);
                    setIsChecking(false);
                }, 400);
            } else {
                setTimeout(() => {
                    setCards((prev) =>
                        prev.map((c) =>
                            c.id === firstId || c.id === secondId
                                ? { ...c, flipped: false }
                                : c
                        )
                    );
                    setSelected([]);
                    setIsChecking(false);
                }, 800);
            }
        }
    }, [cards, selected, isChecking]);

    const resetGame = () => {
        setCards(generateCards(6));
        setSelected([]);
        setMoves(0);
        setMatchedCount(0);
        setIsChecking(false);
    };

    return (
        <div className="fixed inset-0 z-50 bg-background flex flex-col">
            {/* 헤더 */}
            <div className="flex items-center justify-between px-10 py-6 bg-surface shadow-card">
                <h1 className="text-4xl font-bold text-text-main">🧠 기억력 게임</h1>
                <div className="flex items-center gap-8">
                    <span className="text-2xl font-semibold text-text-body">
                        시도: {moves}회
                    </span>
                    <span className="text-2xl font-semibold text-primary">
                        {matchedCount} / {totalPairs} 맞춤
                    </span>
                    <button
                        onClick={onClose}
                        className="px-6 py-3 bg-gray-200 text-text-main text-xl font-bold rounded-button hover:bg-gray-300 transition-colors"
                    >
                        닫기
                    </button>
                </div>
            </div>

            {/* 게임 영역 */}
            <div className="flex-1 flex items-center justify-center px-4 py-6">
                {gameComplete ? (
                    <div className="text-center">
                        <div className="text-9xl mb-8">🎉</div>
                        <h2 className="text-5xl font-bold text-text-main mb-4">
                            축하합니다!
                        </h2>
                        <p className="text-3xl text-text-body mb-10">
                            {moves}번 만에 모두 맞추셨어요!
                        </p>
                        <div className="flex gap-6 justify-center">
                            <button
                                onClick={resetGame}
                                className="px-10 py-5 bg-primary text-white text-2xl font-bold rounded-button hover:bg-primary/90 transition-colors"
                            >
                                다시 하기
                            </button>
                            <button
                                onClick={onClose}
                                className="px-10 py-5 bg-gray-200 text-text-main text-2xl font-bold rounded-button hover:bg-gray-300 transition-colors"
                            >
                                나가기
                            </button>
                        </div>
                    </div>
                ) : (
                    <div className="grid grid-cols-4 gap-8 max-w-7xl w-full">
                        {cards.map((card) => (
                            <button
                                key={card.id}
                                onClick={() => handleCardClick(card.id)}
                                className={`aspect-square rounded-card text-9xl flex items-center justify-center transition-all duration-300 shadow-card ${
                                    card.matched
                                        ? 'bg-green-100 border-4 border-green-400 scale-95'
                                        : card.flipped
                                            ? 'bg-white border-4 border-primary'
                                            : 'bg-primary text-white hover:bg-primary/90 hover:scale-[1.03] cursor-pointer'
                                }`}
                                disabled={card.flipped || card.matched}
                            >
                                {card.flipped || card.matched ? card.emoji : '?'}
                            </button>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default MemoryGameOverlay;
