import React from 'react';
import './GreetingCard.css';

const GreetingCard = () => {
  return (
    <div className="greeting-card">
      <div className="sun-icon">☀️</div>
      <div className="robot-container">
        <div className="robot-avatar">
          <div className="robot-face">
            <div className="robot-eye left-eye"></div>
            <div className="robot-eye right-eye"></div>
            <div className="robot-mouth"></div>
          </div>
        </div>
      </div>
      <div className="greeting-text">
        <h2 className="greeting-title">좋은 아침이에요, 할머니!</h2>
        <p className="greeting-subtitle">오늘도 활기찬 하루 시작해볼까요?</p>
      </div>
    </div>
  );
};

export default GreetingCard;
