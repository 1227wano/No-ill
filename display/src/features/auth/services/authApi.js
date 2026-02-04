import client from '../../../api/client';

const USE_MOCK = import.meta.env.VITE_USE_MOCK_AUTH === 'true';

// Mock 데이터
const MOCK_USERS = [
    { petNo: '1234', userNo: 1, userName: '김영희' },
    { petNo: '5678', userNo: 2, userName: '박철수' },
    { petNo: 'TEST', userNo: 99, userName: '테스트 사용자' },
];

const generateMockToken = (user) => {
    const payload = {
        userNo: user.userNo,
        userName: user.userName,
        petNo: user.petNo,
        exp: Date.now() + 24 * 60 * 60 * 1000, // 24시간 후 만료
    };
    // 한글 지원을 위해 encodeURIComponent 사용
    return btoa(encodeURIComponent(JSON.stringify(payload)));
};

const parseMockToken = (token) => {
    try {
        const payload = JSON.parse(decodeURIComponent(atob(token)));
        if (payload.exp < Date.now()) {
            return null; // 만료됨
        }
        return payload;
    } catch {
        return null;
    }
};

// Mock API 함수들
const mockLogin = async (petNo) => {
    // 네트워크 지연 시뮬레이션
    await new Promise((resolve) => setTimeout(resolve, 500));

    const user = MOCK_USERS.find((u) => u.petNo === petNo);

    if (!user) {
        // 4자 이상이면 임시 사용자로 허용
        if (petNo.length >= 4) {
            const tempUser = { petNo, userNo: 100, userName: '노일 사용자' };
            const token = generateMockToken(tempUser);
            return { token, user: tempUser };
        }
        throw new Error('유효하지 않은 로봇펜 번호입니다.');
    }

    const token = generateMockToken(user);
    return { token, user };
};

const mockVerifyToken = async () => {
    await new Promise((resolve) => setTimeout(resolve, 200));

    const token = localStorage.getItem('token');
    if (!token) {
        throw new Error('토큰이 없습니다.');
    }

    const payload = parseMockToken(token);
    if (!payload) {
        throw new Error('유효하지 않은 토큰입니다.');
    }

    return {
        userNo: payload.userNo,
        userName: payload.userName,
        petNo: payload.petNo,
    };
};

// 실제 API 함수들
const realLogin = async (petId) => {
    const response = await client.post('/api/auth/pets/login', { petId: petId });
    const data = response.data;
    // 백엔드 응답을 프론트엔드 형식으로 변환
    return {
        token: data.accessToken,
        user: {
            petId: data.petId,
            petNo: data.petNo,
            userName: data.petName,
        },
    };
};

// Tolelom: 백엔드 토큰 검증 미구현으로 인한 주석 처리
// const realVerifyToken = async () => {
//     const response = await client.get('/api/auth/pet/verify');
//     return response.data.data;
// };

// Export - 환경변수에 따라 Mock/Real 전환
export const login = USE_MOCK ? mockLogin : realLogin;
