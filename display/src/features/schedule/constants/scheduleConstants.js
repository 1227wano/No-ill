// src/features/schedule/constants/scheduleConstants.js

export const TIME_CONFIG = {
    HOURS: Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0')),
    MINUTES: ['00', '30'],
    INTERVAL: 30, // 30분 단위
};

export const SCHEDULE_TEMPLATES = [
    {
        id: 'medicine',
        title: '💊 약 복용',
        description: '잊지 말고 챙겨드세요',
        colorClass: 'bg-primary/10 text-primary border-primary/20',
    },
    {
        id: 'hospital',
        title: '🏥 병원 방문',
        description: '예약 시간을 확인하세요',
        colorClass: 'bg-primary/10 text-primary border-primary/20',
    },
    {
        id: 'visit',
        title: '🤝 방문 일정',
        description: '선생님 방문 날입니다',
        colorClass: 'bg-primary/10 text-primary border-primary/20',
    },
    {
        id: 'walk',
        title: '🚶 산책',
        description: '가볍게 몸을 움직여요',
        colorClass: 'bg-primary/10 text-primary border-primary/20',
    },
];
