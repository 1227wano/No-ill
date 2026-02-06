export default {
    // Tailwind가 CSS를 생성할 때 검색할 파일 경로
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],

    theme: {
        extend: {
            // NoIll 디자인 시스템 색상
            colors: {
                primary: {
                    DEFAULT: '#5BA3D0',  // 브랜드 메인 컬러, 핵심 액션 버튼
                },
                danger: {
                    DEFAULT: '#E53935',  // 사고 알림, 에러 메시지, 경고
                },
                background: {
                    DEFAULT: '#FDFBF7',  // 전체 화면 배경 (밀키 아이보리)
                },
                surface: {
                    DEFAULT: '#FFFFFF',  // 카드 배경, 흰색 면적
                },
                border: {
                    DEFAULT: '#E0E0E0',  // 입력창 테두리, 구분선
                },
                'text-main': {
                    DEFAULT: '#212529',  // 제목, 주요 본문 (Deep Charcoal)
                },
                'text-body': {
                    DEFAULT: '#495057',  // 보조 설명, 캡션 텍스트
                },
            },

            // 폰트 설정 - Pretendard
            fontFamily: {
                sans: ['Pretendard', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'Roboto', 'sans-serif'],
            },

            // 타이포그래피 (font-size / line-height)
            fontSize: {
                'h1': ['20px', {lineHeight: '1.4', fontWeight: '700'}],
                'body': ['16px', {lineHeight: '1.5', fontWeight: '500'}],
                'caption': ['14px', {lineHeight: '1.5', fontWeight: '400'}],
            },

            // 간격 (8px 배수 시스템)
            spacing: {
                '18': '72px',
                '22': '88px',
            },

            // 테두리 반경
            borderRadius: {
                'card': '16px',
                'button': '24px',
                'input': '8px',
            },

            // 박스 그림자
            boxShadow: {
                'card': '0px 4px 10px rgba(0, 0, 0, 0.1)',
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
                    'from': {opacity: '0', transform: 'scale(0.9)'},
                    'to': {opacity: '1', transform: 'scale(1)'},
                },
            },
        },
    },

    plugins: [],
}