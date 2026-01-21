// 백엔드 주소
import axios from 'axios';

const client = axios.create({
  // 환경 변수에서 주소를 가져옵니다.
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 필요한 경우 인터셉터를 추가해 토큰 등을 처리할 수 있습니다.
client.interceptors.request.use((config) => {
  // 예: const token = localStorage.getItem('token');
  // if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

export default client;