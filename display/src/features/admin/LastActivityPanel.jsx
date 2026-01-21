import React from 'react';

const LastActivityPanel = () => {
  return (
    <div className="bg-white rounded-xl p-6 shadow-sm h-full">
      <div className="flex items-center gap-2 mb-5">
        <span className="text-xl">🔄</span>
        <h3 className="text-lg font-semibold text-gray-800 m-0">마지막 활동</h3>
      </div>
      <div className="flex flex-col gap-3">
        <div className="flex items-center gap-2">
          <span className="text-lg">🕐</span>
          <span className="text-base font-semibold text-gray-800">20분 전</span>
        </div>
        <p className="text-[15px] text-gray-500 m-0 pl-[26px]">침실 이동 감지</p>
      </div>
    </div>
  );
};

export default LastActivityPanel;
