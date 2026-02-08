// src/features/minigame/hooks/useMemoryGame.js

import { useState, useCallback } from 'react';
import { generateCards, isCardsMatch } from '../utils/gameUtils';
import { EMOJI_POOL, GAME_CONFIG } from '../constants/gameConstants';

const useMemoryGame = (pairCount = GAME_CONFIG.DEFAULT_PAIR_COUNT) => {
    const [cards, setCards] = useState(() => generateCards(EMOJI_POOL, pairCount));
    const [selected, setSelected] = useState([]);
    const [moves, setMoves] = useState(0);
    const [matchedCount, setMatchedCount] = useState(0);
    const [isChecking, setIsChecking] = useState(false);

    const gameComplete = matchedCount === pairCount;

    const handleCardClick = useCallback(
        (id) => {
            if (isChecking) return;

            const card = cards.find((c) => c.id === id);
            if (!card || card.flipped || card.matched) return;

            // 카드 뒤집기
            const newCards = cards.map((c) =>
                c.id === id ? { ...c, flipped: true } : c
            );
            setCards(newCards);

            const newSelected = [...selected, id];
            setSelected(newSelected);

            // 두 개의 카드가 선택되었을 때
            if (newSelected.length === 2) {
                setMoves((m) => m + 1);
                setIsChecking(true);

                const [firstId, secondId] = newSelected;
                const firstCard = newCards.find((c) => c.id === firstId);
                const secondCard = newCards.find((c) => c.id === secondId);

                // 매치 확인
                if (isCardsMatch(firstCard, secondCard)) {
                    // 매치 성공
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
                    }, GAME_CONFIG.MATCH_DELAY);
                } else {
                    // 매치 실패
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
                    }, GAME_CONFIG.UNMATCH_DELAY);
                }
            }
        },
        [cards, selected, isChecking]
    );

    const resetGame = useCallback(() => {
        setCards(generateCards(EMOJI_POOL, pairCount));
        setSelected([]);
        setMoves(0);
        setMatchedCount(0);
        setIsChecking(false);
    }, [pairCount]);

    return {
        cards,
        moves,
        matchedCount,
        totalPairs: pairCount,
        gameComplete,
        handleCardClick,
        resetGame,
    };
};

export default useMemoryGame;
