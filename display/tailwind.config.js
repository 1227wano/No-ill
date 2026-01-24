export default {
    // Tailwind가 CSS를 생성할 때 검색할 파일 경로
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],

    theme: {
        extend: {
            // 색상 정의
            colors: {
                primary: {
                    DEFAULT: '#5BA3D0',
                    dark: '#4A90C2',
                },
                secondary: {
                    DEFAULT: '#E8F4F8',
                    dark: '#D4E8F0',
                },
            },

            // 폰트 설정
            fontFamily: {
                sans: ['Noto Sans KR', 'sans-serif'],
            },

            // 반응형 디자인 브레이크포인트
            screens: {
                'xl': '1400px',
                '2xl': '1600px',
                '3xl': '1920px',
            },

            // 애니메이션 설정
            animation: {
                'pop': 'pop 0.3s ease-out',
            },

            // keyframes 설정
            keyframes: {
                pop: {
                    'from': { opacity: '0', transform: 'scale(0.9)' },
                    'to': { opacity: '1', transform: 'scale(1)' },
                },
            },
        },
    },

    plugins: [],
}