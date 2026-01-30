import React from 'react';

const CommandsPanel = () => {
  const commands = [
    { icon: '☁️', text: '"오늘 날씨 어때?"' },
    { icon: '💊', text: '"아침 약 먹었어"' },
    { icon: '📰', text: '"오늘 뉴스 들려줘"' }
  ];

  return (
    <div className="bg-surface rounded-card p-8 shadow-card h-full flex flex-col">
      <h2 className="text-2xl font-bold text-text-main mb-6">이렇게 말해보세요</h2>
      <div className="flex flex-col gap-4 mb-8">
        {commands.map((command, index) => (
          <button
            key={index}
            className="flex items-center gap-4 px-6 py-5 bg-background border-2 border-primary rounded-card cursor-pointer transition-all text-left hover:bg-primary hover:text-white hover:scale-[1.02]"
            aria-label={`${command.text} 명령어`}
          >
            <span className="text-3xl min-w-[40px]">{command.icon}</span>
            <span className="text-xl font-semibold text-text-main hover:text-white">{command.text}</span>
          </button>
        ))}
      </div>
      <div className="mt-auto pt-6 border-t border-border">
        <h3 className="text-xl font-bold text-text-main mb-3">도움말</h3>
        <p className="text-body text-text-body leading-relaxed">
          화면을 보며 궁금한 점을 목소리로 물어보세요. 노일이가 언제든 대답해 드립니다.
        </p>
      </div>
    </div>
  );
};

export default CommandsPanel;
