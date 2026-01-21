import React from 'react';

const SnapshotPanel = () => {
  return (
    <div className="bg-white rounded-xl p-6 shadow-sm h-full">
      <div className="flex justify-between items-center mb-5">
        <div className="flex items-center gap-2">
          <span className="text-xs animate-pulse">🔴</span>
          <h3 className="text-lg font-semibold text-gray-800 m-0">실시간 스냅샷</h3>
        </div>
        <span className="text-sm text-red-500 font-semibold">• LIVE</span>
      </div>
      <div className="flex flex-col gap-3">
        <div className="w-full aspect-video bg-gray-50 rounded-lg overflow-hidden border-2 border-gray-200">
          <div className="w-full h-full bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center relative">
            <div className="w-4/5 h-4/5 relative">
              <div className="w-full h-[60%] bg-white rounded"></div>
              <div className="absolute bottom-0 left-[20%] w-[30%] h-[25%] bg-[#D4A574] rounded flex items-center justify-center">
                <div className="w-5 h-5 bg-green-500 rounded-full"></div>
              </div>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <span className="text-base">📷</span>
          <span className="font-medium text-gray-800">거실 카메라 01</span>
          <span className="ml-auto font-mono">2023-10-27 15:20:42</span>
        </div>
      </div>
    </div>
  );
};

export default SnapshotPanel;
