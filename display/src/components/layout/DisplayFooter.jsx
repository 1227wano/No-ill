import React from 'react';

const Footer = () => {
  return (
    <footer className="flex justify-between items-center py-4 px-10 bg-surface shadow-card border-t border-border">
      <div className="flex gap-10 items-center">
        <div className="flex items-center gap-3">
          <span className="text-2xl">🌡️</span>
          <span className="text-body text-text-main font-medium">현재 기온 18°C</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-2xl">💧</span>
          <span className="text-body text-text-main font-medium">습도 45%</span>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-2xl">💨</span>
          <span className="text-body text-text-main font-medium">미세먼지 좋음</span>
        </div>
      </div>
      <div className="flex items-center gap-3">
        <div className="w-4 h-4 bg-green-500 rounded-full animate-pulse"></div>
        <span className="text-body text-text-main font-medium">노일이 대기 중</span>
      </div>
    </footer>
  );
};

export default Footer;
