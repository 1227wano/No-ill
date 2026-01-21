import React from 'react';
import { Plus, Info, Edit, Trash2 } from 'lucide-react';
import ScheduleModal from './components/ScheduleModal';
import useSchedule from './hooks/useSchedule';

const SchedulePanel = () => {
  const { scheduleItems, isModalOpen, handleSave, handleDelete, openModal, openModalForEdit, closeModal, editingItem } = useSchedule();

  // 현재 시간과 비교하여 지난 일정인지 확인하는 함수
  const isPastTime = (schTime) => {
    if (!schTime) return false;
    const now = new Date();
    // const [hours, minutes] = schTime.split('T')[1].split(':');
    const scheduleDate = new Date(schTime);
    // scheduleDate.setHours(parseInt(hours), parseInt(minutes), 0);
    return scheduleDate < now;
  };
  
  // [추가] 시간 오름차순 정렬 로직
  // 원본 배열을 복사([...])하여 시간(schTime) 문자열 순서대로 정렬합니다.
  const sortedItems = [...scheduleItems]
    // 이벤트 훅이 아니라 dp 화면에서만 관리
    .filter((item) => {
      if (!item.schTime) return false;

      const today = new Date();
      const itemDate = new Date(item.schTime);

      // 연, 월, 일이 모두 일치하는지 확인
      return (
        itemDate.getFullYear() === today.getFullYear() &&
        itemDate.getMonth() === today.getMonth() &&
        itemDate.getDate() === today.getDate()
      );
    })
    .sort((a, b) => {
      return (a.schTime || "").localeCompare(b.schTime || "");
    });

  // 수정 버튼 클릭 시 로직
  const handleEdit = (item) => {
    openModalForEdit(item); // 수정 모달 열기
  };

  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm h-full flex flex-col">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-bold text-gray-800">오늘의 일정</h2>
        <button onClick={openModal} 
          className="flex items-center gap-1 bg-[#5BA3D0] text-white px-3 py-1.5 rounded-lg text-sm font-medium hover:bg-[#4A8EB8] transition-all">
          <Plus size={16} /> 일정 추가
        </button>
      </div>

      <div className="flex flex-col gap-4 overflow-y-auto pr-1">
        {/* [수정] scheduleItems 대신 정렬된 sortedItems를 사용합니다. */}
        {sortedItems.length > 0 ? (
          sortedItems.map((item) => {
            const past = isPastTime(item.schTime);
            return (
              <div key={item.id} 
                className={`flex gap-4 p-5 rounded-2xl border-l-4 transition-all ${
                  past 
                  ? 'bg-gray-100 border-gray-400 opacity-60' // [회색 처리] 지난 일정
                  : 'bg-[#F8FBFC] border-[#5BA3D0] hover:shadow-md' // [색상 처리] 예정 일정
                }`}>
                <div className="text-[32px] min-w-[48px] flex items-center justify-center">
                  {past ? '✔️' : '🗓️'}
                </div>
                <div className="flex-1 flex flex-col gap-1">
                  <div className="flex justify-between items-center">
                    {/* 텍스트 취소선 및 색상 변경 */}
                    <h3 className={`text-lg font-bold ${past ? 'text-gray-500 line-through' : 'text-gray-800'}`}>
                      {item.schName}
                    </h3>
                    <div className="flex items-center gap-2">
                      <button onClick={() => handleEdit(item)} className="text-gray-400 hover:text-[#5BA3D0]">
                        <Edit size={16} />
                      </button>
                      <button onClick={() => {
                        if (window.confirm('정말로 이 일정을 삭제하시겠습니까?')) handleDelete(item.id)}} 
                        className="text-gray-400 hover:text-red-500">
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </div>
                  <p className="text-sm text-gray-500">{item.schMemo}</p>
                  <span className={`text-sm font-bold mt-1 ${past ? 'text-gray-400' : 'text-[#5BA3D0]'}`}>
                    {item.schTime ? item.schTime.split('T')[1].substring(0, 5) : ''}
                  </span>
                </div>
              </div>
            );
          })
        ) : (
          <div className="text-center py-10 text-gray-400">등록된 일정이 없습니다.</div>
        )}
      </div>

      <ScheduleModal isOpen={isModalOpen} onClose={closeModal} onSave={handleSave} editingItem={editingItem} />
    </div>
  );
};

export default SchedulePanel;