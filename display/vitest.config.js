// Vitest 테스트 설정 파일
// 이 파일은 프로젝트의 단위 테스트 환경을 설정합니다.

import {defineConfig} from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'
import {fileURLToPath} from 'url'

// 현재 파일의 절대 경로를 구합니다.
const __filename = fileURLToPath(import.meta.url)
// 현재 파일이 위치한 디렉토리 경로를 구합니다.
const __dirname = path.dirname(__filename)

// Vitest 설정을 정의합니다.
export default defineConfig({
    // Vite 플러그인 설정
    plugins: [react()],

    // 별칭 설정 (import 경로를 단축하기 위해)
    resolve: {
        alias: {
            "@": path.resolve(__dirname, "./src"),
        },
    },

    // 테스트 관련 설정
    test: {
        // 테스트 실행 환경을 jsdom으로 설정 (브라우저 환경 흉내)
        environment: 'jsdom',

        // 글로벌 변수를 사용할 수 있도록 설정
        globals: true,

        // 테스트 시작 전에 실행할 설정 파일
        setupFiles: './src/test/setup.js',

        // CSS 스타일 테스트를 지원하도록 설정
        css: true,

        // 코드 커버리지 측정 설정
        coverage: {
            // 커버리지 측정 도구를 v8로 지정
            provider: 'v8',

            // 커버리지 보고서 형식 지정
            reporter: ['text', 'html'],

            // 커버리지 측정에서 제외할 파일/폴더
            exclude: ['node_modules/', 'src/test/']
        }
    }
})