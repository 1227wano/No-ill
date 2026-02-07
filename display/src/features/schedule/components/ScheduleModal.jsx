// src/features/schedule/components/ScheduleModal.jsx

import React, { useState, useEffect } from 'react';
import { X, Calendar } from 'lucide-react';
import TemplateSelector from './TemplateSelector';
import TimePickerScroll from './TimePickerScroll';
import { getNextAvailableTime, parseScheduleTime } from '../utils/timeUtils';

const ScheduleModal = ({ isOpen, onClose, onSave, editingItem }) => {
    const [formData, setFormData] = useState({
        hour: '12',
        minute: '00',
        content: '',
        description: '',
    });

    useEffect(() => {
        if (!isOpen) return;

        if (editingItem) {
            const { hour, minute } = parseScheduleTime(editingItem.schTime);
            // eslint-disable-next-line react-hooks/set-state-in-effect
            setFormData({
                hour,
                minute,
                content: editingItem.schName || '',
                description: editingItem.schMemo || '',
            });
        } else {
            const { hour, minute } = getNextAvailableTime();
            setFormData({
                hour,
                minute,
                content: '',
                description: '',
            });
        }
    }, [isOpen, editingItem]);

    const handleTemplateSelect = (template) => {
        setFormData((prev) => ({
            ...prev,
            content: template.title,
            description: template.description,
        }));
    };

    const handleTimeChange = ({ hour, minute }) => {
        setFormData((prev) => ({
            ...prev,
            hour: hour !== undefined ? hour : prev.hour,
            minute: minute !== undefined ? minute : prev.minute,
        }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        onSave({
            ...formData,
            time: `${formData.hour}:${formData.minute}`,
        });
    };

    if (!isOpen) return null;

    return (
        <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0, 0, 0, 0.4)',
            backdropFilter: 'blur(4px)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 100,
        }}>
            <div
                style={{
                    background: 'white',
                    borderRadius: 20,
                    boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
                    width: 1100,
                    height: 900,  // ⭐ 850 → 900 (메모 필드 추가)
                    display: 'flex',
                    flexDirection: 'column',
                    overflow: 'hidden',
                }}
                role="dialog"
                aria-modal="true"
                aria-labelledby="modal-title"
            >
                {/* 헤더 */}
                <div style={{
                    background: '#5B8FCC',
                    padding: '20px 30px',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    color: 'white',
                    flexShrink: 0,
                }}>
                    <h2
                        id="modal-title"
                        style={{
                            fontWeight: 'bold',
                            fontSize: 28,
                            display: 'flex',
                            alignItems: 'center',
                            gap: 12,
                        }}
                    >
                        <Calendar size={30} />
                        {editingItem ? '일정 수정하기' : '새 일정 등록하기'}
                    </h2>
                    <button
                        onClick={onClose}
                        style={{
                            background: 'transparent',
                            border: 'none',
                            borderRadius: '50%',
                            padding: 8,
                            cursor: 'pointer',
                            color: 'white',
                            transition: 'background 0.2s',
                            display: 'flex',
                            alignItems: 'center',
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.2)'}
                        onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                        aria-label="모달 닫기"
                    >
                        <X size={28} />
                    </button>
                </div>

                {/* 폼 내용 */}
                <form
                    onSubmit={handleSubmit}
                    style={{
                        padding: '30px',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: 20,
                        flex: 1,
                        overflow: 'hidden',
                    }}
                >
                    {/* 1. 템플릿 선택 */}
                    <TemplateSelector
                        selectedContent={formData.content}
                        onSelectTemplate={handleTemplateSelect}
                    />

                    {/* 2. 일정 이름 입력 */}
                    <section>
                        <input
                            id="schedule-content"
                            type="text"
                            placeholder="일정 이름을 입력하거나 선택하세요"
                            value={formData.content}
                            onChange={(e) =>
                                setFormData({ ...formData, content: e.target.value })
                            }
                            style={{
                                width: '100%',
                                padding: '14px 16px',
                                background: '#f5f5f5',
                                border: '2px solid #e5e7eb',
                                borderRadius: 12,
                                outline: 'none',
                                fontSize: 20,
                                fontWeight: '500',
                                transition: 'border-color 0.2s',
                            }}
                            onFocus={(e) => e.target.style.borderColor = '#5B8FCC'}
                            onBlur={(e) => e.target.style.borderColor = '#e5e7eb'}
                            required
                        />
                    </section>

                    {/* 3. 시간 선택 */}
                    <TimePickerScroll
                        hour={formData.hour}
                        minute={formData.minute}
                        onChange={handleTimeChange}
                        isEditMode={!!editingItem}
                    />

                    {/* 4. 메모 입력 - ⭐ 복구 (작게) */}
                    <section>
                        <textarea
                            id="schedule-memo"
                            placeholder="메모를 입력하세요 (선택)"
                            value={formData.description}
                            onChange={(e) =>
                                setFormData({ ...formData, description: e.target.value })
                            }
                            style={{
                                width: '100%',
                                padding: '10px 12px',  // ⭐ 작게
                                background: '#f5f5f5',
                                border: '1px solid #e5e7eb',
                                borderRadius: 12,
                                outline: 'none',
                                height: 70,  // ⭐ 작게 (120 → 70)
                                resize: 'none',
                                fontSize: 16,  // ⭐ 작게
                                transition: 'border-color 0.2s',
                            }}
                            onFocus={(e) => e.target.style.borderColor = '#5B8FCC'}
                            onBlur={(e) => e.target.style.borderColor = '#e5e7eb'}
                        />
                    </section>

                    {/* 제출 버튼 */}
                    <button
                        type="submit"
                        style={{
                            width: '100%',
                            height: 56,
                            background: '#5B8FCC',
                            color: 'white',
                            borderRadius: 16,
                            fontSize: 22,
                            fontWeight: 'bold',
                            border: 'none',
                            cursor: 'pointer',
                            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                            transition: 'all 0.2s',
                            marginTop: 'auto',
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.background = '#4a7ab8';
                            e.currentTarget.style.transform = 'scale(0.98)';
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.background = '#5B8FCC';
                            e.currentTarget.style.transform = 'scale(1)';
                        }}
                    >
                        {editingItem ? '수정 완료' : '등록 완료'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default ScheduleModal;
