// src/features/schedule/components/DisplaySchedulePanel.jsx 

import React, { useMemo } from 'react';
import { Plus } from 'lucide-react';
import ScheduleModal from './ScheduleModal';
import ScheduleItem from './ScheduleItem';
import useSchedule from '../hooks/useSchedule';
import { filterTodaySchedules } from '../utils/scheduleUtils';

const DisplaySchedulePanel = () => {
    const {
        scheduleItems,
        loading,
        error,
        isModalOpen,
        handleSave,
        handleDelete,
        openModal,
        openModalForEdit,
        closeModal,
        editingItem,
    } = useSchedule();

    // 오늘 일정만 필터링
    const todaySchedules = useMemo(
        () => filterTodaySchedules(scheduleItems),
        [scheduleItems]
    );

    return (
        <div style={{
            width: '100%',
            height: '100%',
            background: 'white',
            borderRadius: 20,
            padding: 40,
            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
            display: 'flex',
            flexDirection: 'column',
            minHeight: 0,
        }}>
            {/* 헤더 */}
            <div style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 30,
            }}>
                <h2 style={{
                    fontSize: 32,
                    fontWeight: 'bold',
                    color: '#1a1a1a',
                }}>
                    오늘의 일정
                </h2>
                <button
                    onClick={openModal}
                    style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 12,
                        background: '#5B8FCC',
                        color: 'white',
                        padding: '12px 24px',
                        borderRadius: 16,
                        fontSize: 20,
                        fontWeight: '600',
                        border: 'none',
                        cursor: 'pointer',
                        transition: 'all 0.2s',
                    }}
                    onMouseEnter={(e) => {
                        e.target.style.background = '#4a7ab8';
                        e.target.style.transform = 'scale(0.95)';
                    }}
                    onMouseLeave={(e) => {
                        e.target.style.background = '#5B8FCC';
                        e.target.style.transform = 'scale(1)';
                    }}
                    aria-label="새 일정 추가"
                >
                    <Plus size={24} /> 일정 추가
                </button>
            </div>

            {/* 일정 목록 */}
            <div
                style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 20,
                    overflowY: 'auto',
                    paddingRight: 8,
                    flex: 1,
                    minHeight: 0,
                }}
                role="feed"
                aria-busy={loading}
            >
                {loading ? (
                    <div style={{
                        textAlign: 'center',
                        padding: '40px 0',
                        color: '#6b7280',
                        fontSize: 24,
                    }}>
                        불러오는 중...
                    </div>
                ) : error ? (
                    <div style={{
                        textAlign: 'center',
                        padding: '40px 0',
                        color: '#ef4444',
                        fontSize: 24,
                    }}>
                        {error}
                    </div>
                ) : todaySchedules.length > 0 ? (
                    todaySchedules.map((item) => (
                        <ScheduleItem
                            key={item.id}
                            item={item}
                            onEdit={openModalForEdit}
                            onDelete={handleDelete}
                        />
                    ))
                ) : (
                    <div style={{
                        textAlign: 'center',
                        padding: '40px 0',
                        color: '#6b7280',
                        fontSize: 24,
                    }}>
                        등록된 일정이 없습니다.
                    </div>
                )}
            </div>

            {/* 모달 */}
            <ScheduleModal
                isOpen={isModalOpen}
                onClose={closeModal}
                onSave={handleSave}
                editingItem={editingItem}
            />
        </div>
    );
};

export default DisplaySchedulePanel;
