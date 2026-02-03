import client from '../../../api/client';

export const createSession = async () => {
    const response = await client.post('/api/openvidu/sessions');
    return response.data;
};

export const createConnection = async (sessionId) => {
    const response = await client.post(`/api/openvidu/sessions/${sessionId}/connections`);
    return response.data;
};

export const callUser = async (userId, sessionId) => {
    const response = await client.post('/api/openvidu/call/user', { userId, sessionId });
    return response.data;
};

export const callPet = async (petId, sessionId) => {
    const response = await client.post('/api/openvidu/call/pet', { petId, sessionId });
    return response.data;
};
