import React, { useState } from 'react';
import { useVideoCall } from '../../features/videocall';
import { useAuth } from '../../features/auth';

const CommandsPanel = () => {
  const [showAIHelp, setShowAIHelp] = useState(false);
  const { startCall } = useVideoCall();
  const { user } = useAuth();

  const handleVideoCall = () => {
    const userId = user?.userId || user?.userNo;
    if (userId) {
      startCall(userId);
    } else {
      alert('보호자 정보를 찾을 수 없습니다.');
    }
  };

  const features = [
    {
      id: 'ai-help',
      icon: '🤖',
      title: 'AI 사용법',
      color: 'bg-primary',
      onClick: () => setShowAIHelp(true)
    },
    {
      id: 'video-call',
      icon: '📞',
      title: '영상 통화',
      color: 'bg-green-500',
      onClick: handleVideoCall
    },
    {
      id: 'hospital',
      icon: '🏥',
      title: '병원 예약',
      color: 'bg-orange-500',
      onClick: () => alert('병원 예약 기능은 준비 중입니다.')
    },
    {
      id: 'medication',
      icon: '💊',
      title: '복약 알림',
      color: 'bg-purple-500',
      onClick: () => alert('복약 알림 기능은 준비 중입니다.')
    },
  ];

  const aiCommands = [
    { icon: '☁️', text: '"오늘 날씨 어때?"' },
    { icon: '💊', text: '"아침 약 먹었어"' },
    { icon: '📰', text: '"오늘 뉴스 들려줘"' },
  ];

  return (
    <div className="bg-surface rounded-card p-8 shadow-card h-full flex flex-col">
      <h2 className="text-4xl font-bold text-text-main mb-8">빠른 메뉴</h2>

      {/* 기능 버튼 그리드 */}
      <div className="grid grid-cols-2 gap-5 flex-1">
        {features.map((feature) => (
          <button
            key={feature.id}
            onClick={feature.onClick}
            className={`${feature.color} rounded-card flex flex-col items-center justify-center gap-4 p-6 text-white shadow-card hover:opacity-90 hover:scale-[1.02] transition-all`}
          >
            <span className="text-6xl">{feature.icon}</span>
            <span className="text-2xl font-bold">{feature.title}</span>
          </button>
        ))}
      </div>

      {/* AI 사용법 모달 */}
      {showAIHelp && (
        <div
          className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-10"
          onClick={() => setShowAIHelp(false)}
        >
          <div
            className="bg-surface rounded-card p-10 max-w-2xl w-full shadow-card"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="text-4xl font-bold text-text-main mb-8 text-center">
              🤖 이렇게 말해보세요
            </h3>
            <div className="flex flex-col gap-4 mb-8">
              {aiCommands.map((command, index) => (
                <div
                  key={index}
                  className="flex items-center gap-4 px-6 py-5 bg-background rounded-card"
                >
                  <span className="text-4xl">{command.icon}</span>
                  <span className="text-2xl font-semibold text-text-main">{command.text}</span>
                </div>
              ))}
            </div>
            <button
              onClick={() => setShowAIHelp(false)}
              className="w-full py-4 bg-primary text-white text-2xl font-bold rounded-card hover:bg-primary/90 transition-colors"
            >
              닫기
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default CommandsPanel;
