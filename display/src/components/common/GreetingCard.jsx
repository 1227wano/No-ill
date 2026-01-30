import React from 'react';

const GreetingCard = () => {
  return (
    <div className="bg-surface rounded-card p-8 flex flex-col items-center shadow-card relative overflow-hidden h-full">
      <div className="text-6xl absolute top-4 right-6 animate-spin-slow">☀️</div>
      <div className="my-6 relative z-10">
        <div className="w-[140px] h-[140px] bg-primary rounded-full flex items-center justify-center shadow-card">
          <div className="w-24 h-24 bg-white rounded-full relative flex items-center justify-center">
            <div className="w-4 h-4 bg-primary rounded-full absolute top-[36px] left-[28px]"></div>
            <div className="w-4 h-4 bg-primary rounded-full absolute top-[36px] right-[28px]"></div>
            <div className="w-8 h-4 border-[3px] border-primary border-t-0 rounded-b-[24px] absolute bottom-6 left-1/2 -translate-x-1/2"></div>
          </div>
        </div>
      </div>
      <div className="text-center mt-4">
        <h2 className="text-2xl font-bold text-text-main mb-3">좋은 아침이에요, 할머니!</h2>
        <p className="text-xl text-primary font-medium">오늘도 활기찬 하루 시작해볼까요?</p>
      </div>
    </div>
  );
};

export default GreetingCard;
