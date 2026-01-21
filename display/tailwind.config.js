/** @type {import('tailwindcss').Config} */
export default { // module.exports = { 대신 사용
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
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
      fontFamily: {
        sans: ['Noto Sans KR', 'sans-serif'],
      },
      screens: {
        'xl': '1400px',
        '2xl': '1600px',
        '3xl': '1920px',
      },
      animation: {
        'pop': 'pop 0.3s ease-out',
      },
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