// Vite 빌드 설정 파일
// 이 파일은 프로젝트의 빌드 환경과 개발 서버 설정을 정의합니다.

import {defineConfig} from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import {fileURLToPath} from 'url' // ESM 환경에서 __dirname 사용을 위해 추가

// ESM 환경에서 __dirname 직접 정의
// Node.js의 __dirname는 CommonJS에서만 사용 가능하므로 ESM에서는 별도로 정의해야 합니다.
const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

// Vite 설정을 정의하는 함수
export default defineConfig({
    // 플러그인 설정
    plugins: [react()],

    // 별칭(Alias) 설정
    resolve: {
        alias: {
            // '@' 별칭을 src 폴더로 매핑
            // 이 설정을 통해 src 폴더 내의 파일을 import할 때 @/components/Component.js와 같이 사용 가능
            "@": path.resolve(__dirname, "./src"),
        },
    },

    // 개발 서버 설정
    server: {
        proxy: {
            // 기상청 API 프록시
            '/api/weather': {
                target: 'http://apis.data.go.kr',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/api\/weather/, ''),
            },
            // 미세먼지 API 프록시
            '/api/air': {
                target: 'http://apis.data.go.kr',
                changeOrigin: true,
                rewrite: (path) => path.replace(/^\/api\/air/, ''),
            },
        },
    },
})