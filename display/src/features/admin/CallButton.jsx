import React from 'react';

const CallButton = () => {
  return (
    <button className="w-full bg-gradient-to-br from-[#5BA3D0] to-[#4A90C2] border-none rounded-xl p-6 flex items-center justify-between cursor-pointer transition-all duration-300 shadow-[0_4px_12px_rgba(91,163,208,0.3)] hover:-translate-y-0.5 hover:shadow-[0_6px_16px_rgba(91,163,208,0.4)]">
      <div className="flex items-center gap-4">
        <span className="text-[32px] w-14 h-14 flex items-center justify-center bg-white/20 rounded-xl">📞</span>
        <div className="flex flex-col items-start gap-1">
          <span className="text-xl font-semibold text-white">지금 바로 통화하기</span>
          <span className="text-sm text-white/90">실시간 영상 및 음성 통화</span>
        </div>
      </div>
      <span className="text-2xl text-white font-light">→</span>
    </button>
  );
};

export default CallButton;
