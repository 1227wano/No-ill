import React from 'react';
import './Header.css';

const Header = () => {
  const now = new Date();
  const timeOptions = { hour: '2-digit', minute: '2-digit', hour12: true };
  const dateOptions = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' };
  
  const timeString = now.toLocaleTimeString('ko-KR', timeOptions);
  const dateString = now.toLocaleDateString('ko-KR', dateOptions);

  return (
    <header className="header">
      <div className="header-left">
        <div className="logo-container">
          <div className="logo-icon"></div>
          <span className="logo-text">No-ill (노일)</span>
        </div>
      </div>
      <div className="header-right">
        <span className="time">{timeString}</span>
        <span className="date">{dateString}</span>
      </div>
    </header>
  );
};

export default Header;
