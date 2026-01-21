import React from 'react';

const DeviceStatusPanel = () => {
  return (
    <div className="bg-white rounded-xl p-6 shadow-sm h-full">
      <h3 className="text-lg font-semibold text-gray-800 mb-5">기기 현재 상태</h3>
      <div className="flex flex-col gap-5">
        <div className="flex items-center gap-3">
          <div className="w-4 h-4 rounded-full bg-green-500 shadow-[0_0_0_4px_rgba(46,204,113,0.2)]"></div>
          <span className="text-base font-medium text-gray-800">정상</span>
        </div>
        <div className="flex items-center gap-4 pt-4 border-t border-gray-100">
          <div className="text-[32px] w-12 h-12 flex items-center justify-center bg-[#E8F4F8] rounded-xl">🏃</div>
          <div className="flex-1">
            <p className="text-base font-semibold text-gray-800 mb-1">주행 중</p>
            <p className="text-sm text-gray-500 m-0">네비게이션 활성화됨</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DeviceStatusPanel;
