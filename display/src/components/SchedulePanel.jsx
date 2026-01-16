import React from 'react';
import './SchedulePanel.css';

const SchedulePanel = () => {
  const scheduleItems = [
    {
      id: 1,
      icon: '🍽️',
      title: '아침 식사',
      description: '영양 가득한 식사를 챙겨드세요',
      time: '08:00',
      status: null
    },
    {
      id: 2,
      icon: '💊',
      title: '아침 약 복용',
      description: '혈압약과 비타민을 드실 시간 입니다',
      time: '09:00',
      status: '진행 중'
    },
    {
      id: 3,
      icon: '🚶',
      title: '가벼운 산책',
      description: '햇볕을 쬐며 20분만 걸어보아요',
      time: '10:30',
      status: null
    }
  ];

  return (
    <div className="schedule-panel">
      <h2 className="panel-title">오늘 아침 일정</h2>
      <div className="schedule-list">
        {scheduleItems.map((item) => (
          <div key={item.id} className="schedule-item">
            <div className="schedule-icon">{item.icon}</div>
            <div className="schedule-content">
              <div className="schedule-header">
                <h3 className="schedule-title">{item.title}</h3>
                {item.status && (
                  <span className="schedule-status">{item.status}</span>
                )}
              </div>
              <p className="schedule-description">{item.description}</p>
              <span className="schedule-time">{item.time}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SchedulePanel;
