import React from 'react';
import {Plus, Edit, Trash2} from 'lucide-react';
import ScheduleModal from './components/ScheduleModal';
import useSchedule from './hooks/useSchedule';

const SchedulePanel = () => {
    const {
        scheduleItems,
        isModalOpen,
        handleSave,
        handleDelete,
        openModal,
        openModalForEdit,
        closeModal,
        editingItem
    } = useSchedule();

    // 현재 시간과 비교하여 지난 일정인지 확인하는 함수
    const isPastTime = (schTime) => {
        if (!schTime) return false;
        const now = new Date();
        const scheduleDate = new Date(schTime);
        return scheduleDate < now;
    };

    const sortedItems = [...scheduleItems]
        .filter((item) => {
            if (!item.schTime) return false;

            const today = new Date();
            const itemDate = new Date(item.schTime);

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
        openModalForEdit(item);
    };

    return (
        <div className="bg-surface rounded-card p-8 shadow-card h-full flex flex-col min-h-0">
            <div className="flex justify-between items-center mb-8">
                <h2 className="text-5xl font-bold text-text-main">오늘의 일정</h2>
                <button onClick={openModal}
                        className="flex items-center gap-3 bg-primary text-white px-6 py-3 rounded-button text-3xl font-semibold hover:bg-primary/90 transition-all">
                    <Plus size={28}/> 일정 추가
                </button>
            </div>

            <div className="flex flex-col gap-5 overflow-y-auto pr-1 flex-1 min-h-0" style={{ WebkitOverflowScrolling: 'touch', touchAction: 'pan-y' }}>
                {sortedItems.length > 0 ? (
                    sortedItems.map((item) => {
                        const past = isPastTime(item.schTime);
                        return (
                            <div key={item.id}
                                 className={`flex gap-5 p-6 rounded-card border-l-4 transition-all ${
                                     past
                                         ? 'bg-border/30 border-text-body opacity-60'
                                         : 'bg-background border-primary hover:shadow-card'
                                 }`}>
                                <div className="text-6xl min-w-[88px] flex items-center justify-center">
                                    {past ? '✔️' : '🗓️'}
                                </div>
                                <div className="flex-1 flex flex-col gap-3">
                                    <div className="flex justify-between items-center">
                                        <h3 className={`text-4xl font-bold ${past ? 'text-text-body line-through' : 'text-text-main'}`}>
                                            {item.schName}
                                        </h3>
                                        <div className="flex items-center gap-4">
                                            <button onClick={() => handleEdit(item)}
                                                    className="text-text-body hover:text-primary p-2">
                                                <Edit size={36}/>
                                            </button>
                                            <button onClick={() => {
                                                if (window.confirm('정말로 이 일정을 삭제하시겠습니까?')) handleDelete(item.id)
                                            }}
                                                    className="text-text-body hover:text-danger p-2">
                                                <Trash2 size={36}/>
                                            </button>
                                        </div>
                                    </div>
                                    <p className="text-3xl text-text-body">{item.schMemo}</p>
                                    <span
                                        className={`text-3xl font-bold mt-1 ${past ? 'text-text-body' : 'text-primary'}`}>
                                        {item.schTime ? item.schTime.split('T')[1].substring(0, 5) : ''}
                                    </span>
                                </div>
                            </div>
                        );
                    })
                ) : (
                    <div className="text-center py-10 text-text-body text-3xl">등록된 일정이 없습니다.</div>
                )}
            </div>

            <ScheduleModal isOpen={isModalOpen} onClose={closeModal} onSave={handleSave} editingItem={editingItem}/>
        </div>
    );
};

export default SchedulePanel;