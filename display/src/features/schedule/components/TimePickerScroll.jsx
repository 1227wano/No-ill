// src/features/schedule/components/TimePickerScroll.jsx

import React from 'react';
import { Clock } from 'lucide-react';
import { TIME_CONFIG } from '../constants/scheduleConstants';
import { isPastTime } from '../utils/timeUtils';

const TimePickerScroll = ({ hour, minute, onChange, isEditMode }) => {
    return (
        <section>
            <label style={{
                fontSize: 16,  // ⭐ 20 → 16
                fontWeight: 'bold',
                color: '#6b7280',
                marginBottom: 12,  // ⭐ 20 → 12
                display: 'flex',
                alignItems: 'center',
                gap: 8,
            }}>
                <Clock size={20} /> {/* ⭐ 24 → 20 */}
                시간 설정 (30분 단위)
            </label>
            <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 24,  // ⭐ 32 → 24
                background: '#f5f5f5',
                borderRadius: 12,
                padding: 16,  // ⭐ 24 → 16
                border: '1px solid #e5e7eb',
            }}>
                {/* 시(Hour) 스크롤 */}
                <TimeColumn
                    label="시"
                    options={TIME_CONFIG.HOURS}
                    selected={hour}
                    onSelect={(h) => onChange({ hour: h, minute })}
                    isDisabled={(h) => !isEditMode && isPastTime(h, '59')}
                />

                <div style={{
                    fontSize: 32,  // ⭐ 40 → 32
                    fontWeight: '300',
                    color: '#d1d5db',
                    alignSelf: 'center',
                    marginTop: 24,  // ⭐ 32 → 24
                }}>
                    :
                </div>

                {/* 분(Minute) 스크롤 */}
                <TimeColumn
                    label="분"
                    options={TIME_CONFIG.MINUTES}
                    selected={minute}
                    onSelect={(m) => onChange({ hour, minute: m })}
                    isDisabled={(m) => !isEditMode && isPastTime(hour, m)}
                />
            </div>
        </section>
    );
};

// 시간 컬럼
const TimeColumn = ({ label, options, selected, onSelect, isDisabled }) => {
    return (
        <div style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
        }}>
            <span style={{
                fontSize: 15,  // ⭐ 18 → 15
                color: '#6b7280',
                fontWeight: 'bold',
                marginBottom: 8,  // ⭐ 12 → 8
            }}>
                {label}
            </span>
            <div style={{
                height: 140,  // ⭐ 192 → 140
                overflowY: 'auto',
                scrollSnapType: 'y mandatory',
                padding: '0 12px',  // ⭐ 16 → 12
                scrollbarWidth: 'none',
                msOverflowStyle: 'none',
            }}>
                <style>{`
                    div::-webkit-scrollbar {
                        display: none;
                    }
                `}</style>

                <div style={{ height: 48 }} aria-hidden="true" />  {/* ⭐ 64 → 48 */}
                {options.map((value) => {
                    const disabled = isDisabled(value);
                    const isSelected = selected === value;

                    return (
                        <button
                            key={value}
                            type="button"
                            disabled={disabled}
                            onClick={() => onSelect(value)}
                            style={{
                                height: 48,  // ⭐ 64 → 48
                                width: 70,   // ⭐ 80 → 70
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                scrollSnapAlign: 'center',
                                fontSize: 22,  // ⭐ 26 → 22
                                fontWeight: 'bold',
                                transition: 'all 0.2s',
                                background: 'transparent',
                                border: 'none',
                                cursor: disabled ? 'not-allowed' : 'pointer',
                                color: isSelected
                                    ? '#5B8FCC'
                                    : disabled
                                        ? '#d1d5db'
                                        : '#6b7280',
                                transform: isSelected ? 'scale(1.2)' : 'scale(1)',  // ⭐ 1.25 → 1.2
                            }}
                            onMouseEnter={(e) => {
                                if (!disabled && !isSelected) {
                                    e.currentTarget.style.color = '#5B8FCC';
                                }
                            }}
                            onMouseLeave={(e) => {
                                if (!disabled && !isSelected) {
                                    e.currentTarget.style.color = '#6b7280';
                                }
                            }}
                            aria-selected={isSelected}
                            aria-disabled={disabled}
                        >
                            {value}
                        </button>
                    );
                })}
                <div style={{ height: 48 }} aria-hidden="true" />  {/* ⭐ 64 → 48 */}
            </div>
        </div>
    );
};

export default TimePickerScroll;
