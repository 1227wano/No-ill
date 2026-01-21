import React from 'react';

const Footer = () => {
  return (
    <footer className="flex justify-between items-center py-5 px-10 bg-white shadow-[0_-2px_4px_rgba(0,0,0,0.05)] border-t border-gray-200 max-[768px]:py-4 max-[768px]:px-5">
      <div className="flex gap-8 items-center">
        <div className="flex items-center gap-2">
          <span className="text-xl">🌡️</span>
          <span className="text-sm text-gray-800 font-medium">현재 기온 18°C</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xl">💧</span>
          <span className="text-sm text-gray-800 font-medium">습도 45%</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xl">💨</span>
          <span className="text-sm text-gray-800 font-medium">미세먼지 좋음</span>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
        <span className="text-sm text-gray-800 font-medium">노일이 대기 중</span>
      </div>
    </footer>
  );
};

export default Footer;
