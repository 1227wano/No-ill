import React from 'react';

const Sidebar = () => {
  const menuItems = [
    { id: 'dashboard', icon: '⊞', label: '대시보드', active: true },
    { id: 'activity', icon: '📝', label: '활동 로그', active: false },
    { id: 'schedule', icon: '📅', label: '원격 일정 관리', active: false },
    { id: 'settings', icon: '⚙️', label: '기기 설정', active: false }
  ];

  return (
    <aside className="w-[260px] shrink-0 h-screen bg-white border-r border-gray-200 flex flex-col sticky top-0 self-start z-[100] overflow-y-auto">
      <div className="py-[30px] px-5 border-b border-gray-100 flex flex-col items-center gap-4">
        <div className="w-20 h-20 rounded-full bg-gradient-to-br from-[#D4A574] to-[#C49660] border-[3px] border-white shadow-md relative overflow-hidden">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[30px] h-[30px] bg-white/80 rounded-full"></div>
        </div>
        <div className="text-center">
          <h3 className="text-xl font-semibold text-gray-800 mb-1">No-ill (노일)</h3>
          <p className="text-sm text-gray-500 m-0">관리자 성함</p>
        </div>
      </div>
      
      <nav className="flex-1 py-5 overflow-y-auto">
        <ul className="list-none p-0 m-0">
          {menuItems.map((item) => (
            <li key={item.id} className="mx-3 my-1">
              <a 
                href="#" 
                className={`flex items-center gap-3 px-4 py-3 rounded-lg no-underline transition-all relative ${
                  item.active 
                    ? 'bg-[#E8F4F8] text-[#5BA3D0] font-semibold' 
                    : 'text-gray-800 hover:bg-gray-50'
                }`}
              >
                {item.active && (
                  <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-[#5BA3D0] rounded-r-sm"></div>
                )}
                <span className="text-xl w-6 text-center">{item.icon}</span>
                <span className="text-[15px]">{item.label}</span>
              </a>
            </li>
          ))}
        </ul>
      </nav>

      <div className="p-5 border-t border-gray-100">
        <a href="#" className="flex items-center justify-between px-4 py-3 text-gray-500 no-underline rounded-lg transition-all hover:bg-gray-50 hover:text-gray-800">
          <span>로그아웃</span>
          <span className="text-lg">→</span>
        </a>
      </div>
    </aside>
  );
};

export default Sidebar;
