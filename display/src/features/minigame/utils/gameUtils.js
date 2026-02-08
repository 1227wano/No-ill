// src/features/minigame/utils/gameUtils.js

/**
 * 배열을 랜덤하게 섞기
 * @param {Array} array
 * @returns {Array}
 */
export const shuffle = (array) => {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
};

/**
 * 카드 생성
 * @param {Array} emojiPool - 이모지 풀
 * @param {number} pairCount - 쌍 개수
 * @returns {Array<{id: number, emoji: string, flipped: boolean, matched: boolean}>}
 */
export const generateCards = (emojiPool, pairCount) => {
    const selected = shuffle(emojiPool).slice(0, pairCount);
    const pairs = [...selected, ...selected];
    return shuffle(pairs).map((emoji, index) => ({
        id: index,
        emoji,
        flipped: false,
        matched: false,
    }));
};

/**
 * 두 카드가 매치되는지 확인
 * @param {Object} card1
 * @param {Object} card2
 * @returns {boolean}
 */
export const isCardsMatch = (card1, card2) => {
    return card1?.emoji === card2?.emoji;
};
