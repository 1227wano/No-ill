import React from 'react';

const Header = () => {
  const now = new Date();
  const timeOptions = { hour: '2-digit', minute: '2-digit', hour12: true };
  const dateOptions = { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' };
  
  const timeString = now.toLocaleTimeString('ko-KR', timeOptions);
  const dateString = now.toLocaleDateString('ko-KR', dateOptions);

  return (
    <header className="flex justify-between items-center py-5 px-10 bg-white shadow-sm max-[768px]:py-4 max-[768px]:px-5">
      <div className="flex items-center">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary-dark rounded-lg relative after:content-[''] after:absolute after:top-1/2 after:left-1/2 after:-translate-x-1/2 after:-translate-y-1/2 after:w-5 after:h-5 after:bg-white/80 after:rounded"></div>
          <span className="text-2xl font-semibold text-gray-800">No-ill (노일)</span>
        </div>
      </div>
      <div className="flex flex-col items-end gap-1">
        <span className="text-xl font-medium text-gray-800">{timeString}</span>
        <span className="text-sm text-gray-500">{dateString}</span>
      </div>
    </header>
  );
};

export default Header;
