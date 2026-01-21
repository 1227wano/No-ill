import React from 'react';
import { Edit, Trash2, Calendar } from 'lucide-react';
import ScheduleModal from '@/features/schedule/components/ScheduleModal';
import useSchedule from './hooks/useSchedule'; // 작성하신 커스텀 훅 임포트

const SchedulePanel = () => {
  // useSchedule 훅에서 필요한 모든 상태와 로직을 가져옵니다.
  const {
    scheduleItems,      // 서버에서 가져와 시간순으로 정렬된 데이터
    isModalOpen,        // 모달 열림 상태
    handleSave,         // 서버 저장/수정 로직
    handleDelete,       // 서버 삭제 로직
    openModal,          // 추가 모달 열기 함수
    openModalForEdit,   // 수정 모달 열기 함수
    closeModal,         // 모달 닫기 함수
    editingItem,        // 현재 수정 중인 아이템
    // setEditingItem      // 수정 아이템 설정 함수
  } = useSchedule();

  // 시간순 정렬
  const sortedSchedules = [...scheduleItems].sort((a, b) => {
    // ISO 형식(2026-01-20T09:40:00) 문자열은 직접 비교가 가능합니다.
    const timeA = a.schTime || "";
    const timeB = b.schTime || "";
    return timeA.localeCompare(timeB);
  });

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm col-span-3 w-full overflow-x-auto">
      <div className="flex justify-between items-start mb-6">
        <div className="flex gap-3">
          <span className="text-2xl">📅</span>
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-1">원격 일정 관리</h3>
            <p className="text-sm text-gray-400 m-0">
              대상자의 스마트 기기에 실시간으로 표시되는 오늘의 일정입니다.
            </p>
          </div>
        </div>
        <div className="flex gap-3">
          <button 
            onClick={openModal} // 훅에서 제공하는 추가 모달 열기 함수
            className="px-5 py-2.5 bg-[#5BA3D0] border-none rounded-lg text-sm font-medium text-white cursor-pointer transition-all hover:bg-[#4A90C2] hover:-translate-y-0.5"
          >
            + 새 일정 추가
          </button>
        </div>
      </div>
      
      <div className="overflow-x-auto">
        <table className="w-full border-collapse">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-sm font-semibold text-gray-800 border-b-2 border-gray-200">시간</th>
              <th className="px-4 py-3 text-left text-sm font-semibold text-gray-800 border-b-2 border-gray-200">일정 내용</th>
              <th className="px-4 py-3 text-left text-sm font-semibold text-gray-800 border-b-2 border-gray-200">진행 상태</th>
              <th className="px-4 py-3 text-left text-sm font-semibold text-gray-800 border-b-2 border-gray-200">작업</th>
            </tr>
          </thead>
          <tbody>
            {sortedSchedules.length > 0 ? (
              sortedSchedules.map((item) => {
                return (
                <tr key={item.id} className="hover:bg-blue-50/50">
                  <td className="px-4 py-4 border-b border-gray-100 text-sm font-bold text-[#5BA3D0]">
                    {/* 서버 데이터 schTime에서 시간만 추출 (HH:mm) */}
                    {item.schTime ? item.schTime.split('T')[1].substring(0, 5) : '미정'}
                  </td>
                  <td className="px-4 py-4 border-b border-gray-100 text-sm text-gray-800 font-medium">
                    <div>{item.schName}</div>
                    {item.schMemo && <div className="text-xs text-gray-400 mt-0.5">{item.schMemo}</div>}
                  </td>
                  <td className="px-4 py-4 border-b border-gray-100">
                    {item.schStatus === 'N' ? (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[13px] font-medium bg-gray-50 text-gray-600">
                        ● 완료
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-[13px] font-medium bg-green-50 text-green-600">
                        ● 예정
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-4 border-b border-gray-100">
                    <div className="flex gap-2">
                      <button 
                        onClick={() => openModalForEdit(item)} 
                        className="text-gray-400 hover:text-[#5BA3D0] transition-colors"
                      >
                        <Edit size={16} />
                      </button>
                      <button 
                        onClick={() => handleDelete(item.id)} 
                        className="text-gray-400 hover:text-red-500 transition-colors"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan="4" className="text-center py-10 text-gray-400 text-sm">
                  등록된 일정이 없습니다.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <ScheduleModal 
        isOpen={isModalOpen} 
        onClose={closeModal} 
        onSave={handleSave} // 훅의 handleSave와 연결 (POST/PUT 자동 처리)
        editingItem={editingItem}
      />
    </div>
  );
};

export default SchedulePanel;