import React from 'react';

const GreetingCard = () => {
  return (
    <div className="bg-gradient-to-br from-[#E8F4F8] to-[#D4E8F0] rounded-[20px] p-10 flex flex-col items-center shadow-lg relative overflow-hidden">
      <div className="text-5xl absolute top-5 right-[30px] animate-spin-slow">☀️</div>
      <div className="my-5 relative z-10">
        <div className="w-[120px] h-[120px] bg-gradient-to-br from-[#5BA3D0] to-[#4A90C2] rounded-full flex items-center justify-center shadow-[0_4px_12px_rgba(91,163,208,0.3)]">
          <div className="w-20 h-20 bg-white rounded-full relative flex items-center justify-center">
            <div className="w-3 h-3 bg-[#5BA3D0] rounded-full absolute top-[30px] left-[25px]"></div>
            <div className="w-3 h-3 bg-[#5BA3D0] rounded-full absolute top-[30px] right-[25px]"></div>
            <div className="w-6 h-3 border-2 border-[#5BA3D0] border-t-0 rounded-b-[24px] absolute bottom-5 left-1/2 -translate-x-1/2"></div>
          </div>
        </div>
      </div>
      <div className="text-center mt-5">
        <h2 className="text-2xl font-semibold text-gray-800 mb-2">좋은 아침이에요, 할머니!</h2>
        <p className="text-base text-[#5BA3D0] m-0">오늘도 활기찬 하루 시작해볼까요?</p>
      </div>
    </div>
  );
};

export default GreetingCard;
