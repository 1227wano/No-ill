// src/features/minigame/components/MemoryGameOverlay.jsx

import React from 'react';
import useMemoryGame from '../hooks/useMemoryGame';
import { GAME_CONFIG } from '../constants/gameConstants';

const MemoryGameOverlay = ({ onClose }) => {
    const {
        cards,
        moves,
        matchedCount,
        totalPairs,
        gameComplete,
        handleCardClick,
        resetGame,
    } = useMemoryGame();

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
                        aria-label="게임 닫기"
                    >
                        닫기
                    </button>
                </div>
            </div>

            {/* 게임 영역 */}
            <div className="flex-1 flex items-center justify-center px-4 py-6">
                {gameComplete ? (
                    <GameCompleteScreen
                        moves={moves}
                        onReset={resetGame}
                        onClose={onClose}
                    />
                ) : (
                    <GameBoard cards={cards} onCardClick={handleCardClick} />
                )}
            </div>
        </div>
    );
};

// 게임 완료 화면
const GameCompleteScreen = ({ moves, onReset, onClose }) => (
    <div className="text-center">
        <div className="text-9xl mb-8" role="img" aria-label="축하">
            🎉
        </div>
        <h2 className="text-5xl font-bold text-text-main mb-4">축하합니다!</h2>
        <p className="text-3xl text-text-body mb-10">
            {moves}번 만에 모두 맞추셨어요!
        </p>
        <div className="flex gap-6 justify-center">
            <button
                onClick={onReset}
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
);

// 게임 보드
const GameBoard = ({ cards, onCardClick }) => (
    <div
        className="grid gap-8 max-w-7xl w-full"
        style={{ gridTemplateColumns: `repeat(${GAME_CONFIG.GRID_COLS}, 1fr)` }}
        role="grid"
        aria-label="기억력 게임 카드"
    >
        {cards.map((card) => (
            <GameCard key={card.id} card={card} onClick={onCardClick} />
        ))}
    </div>
);

// 개별 카드
const GameCard = ({ card, onClick }) => {
    const getCardStyle = () => {
        if (card.matched) {
            return 'bg-green-100 border-4 border-green-400 scale-95';
        }
        if (card.flipped) {
            return 'bg-white border-4 border-primary';
        }
        return 'bg-primary text-white hover:bg-primary/90 hover:scale-[1.03] cursor-pointer';
    };

    return (
        <button
            onClick={() => onClick(card.id)}
            className={`aspect-square rounded-card text-9xl flex items-center justify-center transition-all duration-300 shadow-card ${getCardStyle()}`}
            disabled={card.flipped || card.matched}
            aria-label={
                card.flipped || card.matched
                    ? `${card.emoji} 카드`
                    : '뒤집힌 카드'
            }
            aria-pressed={card.flipped || card.matched}
        >
            <span role="img" aria-label={card.flipped || card.matched ? card.emoji : '물음표'}>
                {card.flipped || card.matched ? card.emoji : '?'}
            </span>
        </button>
    );
};

export default MemoryGameOverlay;
