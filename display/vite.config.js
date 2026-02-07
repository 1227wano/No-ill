// Vite 빌드 설정 파일

import {defineConfig} from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import {fileURLToPath} from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

export default defineConfig({
    plugins: [react()],

    resolve: {
        alias: {
            "@": path.resolve(__dirname, "./src"),
        },
    },

    // 개발 서버 설정
    server: {
        proxy: {
            // API 요청을 백엔드 서버로 프록시
            '/api': {
                target: 'https://i14a301.p.ssafy.io',
                changeOrigin: true,
                secure: false,
                rewrite: (path) => {
                    console.log('🔄 Proxy Request:', path);
                    return path;
                }
            }
        },
    },
})
