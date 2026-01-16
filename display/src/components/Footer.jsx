import React from 'react';
import './Footer.css';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="footer-info">
        <div className="info-item">
          <span className="info-icon">🌡️</span>
          <span className="info-text">현재 기온 18°C</span>
        </div>
        <div className="info-item">
          <span className="info-icon">💧</span>
          <span className="info-text">습도 45%</span>
        </div>
        <div className="info-item">
          <span className="info-icon">💨</span>
          <span className="info-text">미세먼지 좋음</span>
        </div>
      </div>
      <div className="footer-status">
        <div className="status-indicator"></div>
        <span className="status-text">노일이 대기 중</span>
      </div>
    </footer>
  );
};

export default Footer;
