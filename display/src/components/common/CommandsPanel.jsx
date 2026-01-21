import React from 'react';

const CommandsPanel = () => {
  const commands = [
    { icon: '☁️', text: '"오늘 날씨 어때?"' },
    { icon: '✓', text: '"아침 약 먹었어"' },
    { icon: '📅', text: '"오늘 뉴스 들려줘"' }
  ];

  return (
    <div className="bg-white rounded-xl p-8 shadow-sm h-full flex flex-col">
      <h2 className="text-xl font-semibold text-gray-800 mb-6">이렇게 말해보세요</h2>
      <div className="flex flex-col gap-3 mb-8">
        {commands.map((command, index) => (
          <button key={index} className="flex items-center gap-3 px-5 py-4 bg-[#E8F4F8] border-2 border-[#5BA3D0] rounded-xl cursor-pointer transition-all text-left text-base text-gray-800 hover:bg-[#5BA3D0] hover:text-white hover:translate-x-1 [&:hover_.command-icon]:brightness-0 [&:hover_.command-icon]:invert">
            <span className="command-icon text-xl min-w-[24px]">{command.icon}</span>
            <span className="font-medium">{command.text}</span>
          </button>
        ))}
      </div>
      <div className="mt-auto pt-6 border-t border-gray-200">
        <h3 className="text-lg font-semibold text-gray-800 mb-3">도움말</h3>
        <p className="text-sm text-gray-500 leading-relaxed m-0">
          화면을 보며 궁금한 점을 목소리로 물어보세요. 노일이가 언제든 대답해 드립니다.
        </p>
      </div>
    </div>
  );
};

export default CommandsPanel;
