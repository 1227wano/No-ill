import React from 'react';

const AdminHeader = () => {
  return (
    <header className="h-[120px] shrink-0 bg-white border-b border-gray-200 py-5 px-10 flex items-center justify-between sticky top-0 z-[90] w-full">
      <div className="flex-none min-w-[300px] max-w-[400px]">
        <h1 className="text-[28px] font-semibold text-gray-800 mb-2">대시보드 개요</h1>
        <p className="text-sm text-gray-500 m-0">현재 보호 대상자의 실시간 상태를 한눈에 확인하세요.</p>
      </div>
      
      <div className="flex-1 flex justify-center min-w-0 px-5">
        <div className="flex items-center bg-gray-50 border border-gray-200 rounded-3xl py-2.5 px-5 w-full max-w-[400px] transition-all focus-within:border-[#5BA3D0] focus-within:bg-white focus-within:shadow-[0_0_0_3px_rgba(91,163,208,0.1)]">
          <span className="text-lg mr-3 text-gray-500">🔍</span>
          <input 
            type="text" 
            placeholder="검색하기..." 
            className="flex-1 border-none bg-transparent outline-none text-sm text-gray-800 placeholder:text-gray-400"
          />
        </div>
      </div>
      
      <div className="flex-none flex items-center justify-end gap-6 min-w-[200px]">
        <button className="w-11 h-11 rounded-full border-none bg-gray-50 cursor-pointer flex items-center justify-center transition-all hover:bg-[#E8F4F8]">
          <span className="text-xl">🔔</span>
        </button>
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-full bg-gradient-to-br from-pink-200 to-pink-300 border-2 border-white shadow-sm"></div>
          <div className="flex flex-col">
            <p className="text-[15px] font-semibold text-gray-800 m-0">김순지</p>
          </div>
        </div>
        <button className="w-8 h-8 rounded-full border-none bg-gray-800 text-white text-lg font-light cursor-pointer flex items-center justify-center transition-all hover:bg-gray-700 hover:scale-105 leading-none">✕</button>
      </div>
    </header>
  );
};

export default AdminHeader;
