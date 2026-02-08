// src/features/schedule/components/ScheduleItem.jsx

import React from 'react';
import { Edit, Trash2 } from 'lucide-react';
import { formatScheduleTime, isPastSchedule } from '../utils/scheduleUtils';

const ScheduleItem = ({ item, onEdit, onDelete }) => {
    const isPast = isPastSchedule(item.schTime);
    const timeString = formatScheduleTime(item.schTime);

    const handleDelete = () => {
        if (window.confirm('정말로 이 일정을 삭제하시겠습니까?')) {
            onDelete(item.id);
        }
    };

    return (
        <div
            style={{
                display: 'flex',
                gap: 20,
                padding: 24,
                borderRadius: 16,
                borderLeft: `4px solid ${isPast ? '#6b7280' : '#5B8FCC'}`,
                background: isPast ? 'rgba(229, 231, 235, 0.3)' : '#f5f5f5',
                opacity: isPast ? 0.6 : 1,
                transition: 'all 0.2s',
                boxShadow: isPast ? 'none' : '0 2px 8px rgba(0,0,0,0.05)',
            }}
            role="article"
            aria-label={`${item.schName} - ${timeString}`}
            onMouseEnter={(e) => {
                if (!isPast) {
                    e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,0,0,0.1)';
                }
            }}
            onMouseLeave={(e) => {
                if (!isPast) {
                    e.currentTarget.style.boxShadow = '0 2px 8px rgba(0,0,0,0.05)';
                }
            }}
        >
            {/* 아이콘 */}
            <div
                style={{
                    fontSize: 48,
                    minWidth: 70,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                }}
                role="img"
                aria-label={isPast ? '완료' : '예정'}
            >
                {isPast ? '✔️' : '🗓️'}
            </div>

            {/* 내용 */}
            <div style={{
                flex: 1,
                display: 'flex',
                flexDirection: 'column',
                gap: 12,
            }}>
                {/* 제목 + 버튼 */}
                <div style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                }}>
                    <h3 style={{
                        fontSize: 28,
                        fontWeight: 'bold',
                        color: isPast ? '#6b7280' : '#1a1a1a',
                        textDecoration: isPast ? 'line-through' : 'none',
                    }}>
                        {item.schName}
                    </h3>

                    {/* 액션 버튼 */}
                    <div style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 16,
                    }}>
                        <button
                            onClick={() => onEdit(item)}
                            style={{
                                color: '#6b7280',
                                background: 'transparent',
                                border: 'none',
                                padding: 8,
                                cursor: 'pointer',
                                transition: 'color 0.2s',
                                display: 'flex',
                                alignItems: 'center',
                            }}
                            onMouseEnter={(e) => e.target.style.color = '#5B8FCC'}
                            onMouseLeave={(e) => e.target.style.color = '#6b7280'}
                            aria-label={`${item.schName} 수정`}
                        >
                            <Edit size={32} />
                        </button>
                        <button
                            onClick={handleDelete}
                            style={{
                                color: '#6b7280',
                                background: 'transparent',
                                border: 'none',
                                padding: 8,
                                cursor: 'pointer',
                                transition: 'color 0.2s',
                                display: 'flex',
                                alignItems: 'center',
                            }}
                            onMouseEnter={(e) => e.target.style.color = '#ef4444'}
                            onMouseLeave={(e) => e.target.style.color = '#6b7280'}
                            aria-label={`${item.schName} 삭제`}
                        >
                            <Trash2 size={32} />
                        </button>
                    </div>
                </div>

                {/* 메모 */}
                {item.schMemo && (
                    <p style={{
                        fontSize: 20,
                        color: '#6b7280',
                        lineHeight: 1.5,
                    }}>
                        {item.schMemo}
                    </p>
                )}

                {/* 시간 */}
                <span style={{
                    fontSize: 22,
                    fontWeight: 'bold',
                    marginTop: 4,
                    color: isPast ? '#6b7280' : '#5B8FCC',
                }}>
                    {timeString}
                </span>
            </div>
        </div>
    );
};

export default ScheduleItem;
