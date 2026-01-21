import React from 'react';

const ActivityLogPanel = () => {
  const activities = [
    {
      id: 1,
      icon: '📡',
      title: '침실 활동 감지됨',
      time: '오후 02:45',
      source: '모션 센서',
      status: '활동중',
      statusColor: 'bg-green-100 text-green-800'
    },
    {
      id: 2,
      icon: '💊',
      title: '오전 약 복용 완료',
      time: '오전 09:15',
      source: '자동 체크',
      status: '완료',
      statusColor: 'bg-blue-100 text-blue-800'
    },
    {
      id: 3,
      icon: '🌙',
      title: '기상 완료',
      time: '오전 07:30',
      source: '침대 센서',
      status: '기상',
      statusColor: 'bg-yellow-100 text-yellow-800'
    }
  ];

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm h-full">
      <div className="flex justify-between items-center mb-5">
        <div className="flex items-center gap-2">
          <span className="text-xl">📝</span>
          <h3 className="text-lg font-semibold text-gray-800 m-0">활동 로그</h3>
        </div>
        <a href="#" className="text-sm text-[#5BA3D0] font-medium no-underline transition-colors hover:text-[#4A90C2] hover:underline">전체보기</a>
      </div>
      <div className="flex flex-col gap-4">
        {activities.map((activity) => (
          <div key={activity.id} className="flex gap-4 p-4 bg-gray-50 rounded-lg transition-all hover:bg-blue-50 hover:translate-x-1">
            <div className="w-10 h-10 flex items-center justify-center bg-white rounded-lg shrink-0">
              <span className="text-xl">{activity.icon}</span>
            </div>
            <div className="flex-1 flex flex-col gap-1.5">
              <div className="flex justify-between items-center">
                <span className="text-[15px] font-medium text-gray-800">{activity.title}</span>
                <span className={`px-2.5 py-1 rounded-xl text-xs font-medium ${activity.statusColor}`}>
                  {activity.status}
                </span>
              </div>
              <div className="flex items-center gap-2 text-[13px] text-gray-500">
                <span>{activity.time}</span>
                <span className="text-gray-300">•</span>
                <span>{activity.source}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ActivityLogPanel;
