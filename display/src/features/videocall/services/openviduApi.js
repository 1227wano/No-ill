import client from '../../../api/client';

export const createSession = async () => {
    try {
        const response = await client.post(
            '/api/openvidu/sessions',
            {},
            {
                transformResponse: [(data) => {
                    // 서버가 순수 문자열로 반환하면 그대로 사용
                    if (typeof data === 'string') {
                        // 따옴표 제거
                        return data.trim().replace(/^"|"$/g, '');
                    }
                    // JSON 객체면 파싱
                    try {
                        const parsed = JSON.parse(data);
                        return parsed.sessionId || parsed;
                    } catch {
                        return data;
                    }
                }]
            }
        );
        console.log('📥 createSession response:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ createSession error:', error.response?.data || error.message);
        throw error;
    }
};

export const createConnection = async (sessionId) => {
    try {
        const response = await client.post(
            `/api/openvidu/sessions/${sessionId}/connections`,
            {},
            {
                transformResponse: [(data) => {
                    if (typeof data === 'string') {
                        return data.trim().replace(/^"|"$/g, '');
                    }
                    try {
                        const parsed = JSON.parse(data);
                        return parsed.token || parsed;
                    } catch {
                        return data;
                    }
                }]
            }
        );
        console.log('📥 createConnection response:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ createConnection error:', error.response?.data || error.message);
        throw error;
    }
};

export const callUser = async (userId, sessionId) => {
    try {
        const response = await client.post('/api/openvidu/call/user', {
            userId,
            sessionId
        });
        console.log('📥 callUser response:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ callUser error:', error.response?.data || error.message);
        throw error;
    }
};

export const callPet = async (petId, sessionId) => {
    try {
        const response = await client.post('/api/openvidu/call/pet', {
            petId,
            sessionId
        });
        console.log('📥 callPet response:', response.data);
        return response.data;
    } catch (error) {
        console.error('❌ callPet error:', error.response?.data || error.message);
        throw error;
    }
};