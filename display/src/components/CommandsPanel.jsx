import React from 'react';
import './CommandsPanel.css';

const CommandsPanel = () => {
  const commands = [
    { icon: '☁️', text: '"오늘 날씨 어때?"' },
    { icon: '✓', text: '"아침 약 먹었어"' },
    { icon: '📅', text: '"오늘 뉴스 들려줘"' }
  ];

  return (
    <div className="commands-panel">
      <h2 className="panel-title">이렇게 말해보세요</h2>
      <div className="commands-list">
        {commands.map((command, index) => (
          <button key={index} className="command-button">
            <span className="command-icon">{command.icon}</span>
            <span className="command-text">{command.text}</span>
          </button>
        ))}
      </div>
      <div className="help-section">
        <h3 className="help-title">도움말</h3>
        <p className="help-text">
          화면을 보며 궁금한 점을 목소리로 물어보세요. 노일이가 언제든 대답해 드립니다.
        </p>
      </div>
    </div>
  );
};

export default CommandsPanel;
