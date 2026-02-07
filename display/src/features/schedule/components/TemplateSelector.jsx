// src/features/schedule/components/TemplateSelector.jsx

import React from 'react';
import { FileText } from 'lucide-react';
import { SCHEDULE_TEMPLATES } from '../constants/scheduleConstants';

const TemplateSelector = ({ selectedContent, onSelectTemplate }) => {
    return (
        <section>
            <label style={{
                fontSize: 16,  // ⭐ 20 → 16
                fontWeight: 'bold',
                color: '#6b7280',
                marginBottom: 12,  // ⭐ 20 → 12
                display: 'flex',
                alignItems: 'center',
                gap: 8,  // ⭐ 12 → 8
            }}>
                <FileText size={20} /> {/* ⭐ 24 → 20 */}
                추천 템플릿
            </label>
            <div style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: 12,  // ⭐ 16 → 12
            }}>
                {SCHEDULE_TEMPLATES.map((template) => {
                    const isSelected = selectedContent === template.title;

                    return (
                        <button
                            key={template.id}
                            type="button"
                            onClick={() => onSelectTemplate(template)}
                            style={{
                                textAlign: 'left',
                                padding: 12,  // ⭐ 20 → 12
                                borderRadius: 12,
                                border: isSelected ? '2px solid #5B8FCC' : '2px solid transparent',
                                background: getTemplateColor(template.colorClass),
                                cursor: 'pointer',
                                transition: 'all 0.2s',
                                boxShadow: isSelected ? '0 0 0 2px rgba(91, 143, 204, 0.2)' : 'none',
                            }}
                            onMouseEnter={(e) => {
                                e.currentTarget.style.transform = 'scale(1.02)';
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.transform = 'scale(1)';
                            }}
                            aria-pressed={isSelected}
                        >
                            <div style={{
                                fontWeight: 'bold',
                                fontSize: 16,  // ⭐ 20 → 16
                                marginBottom: 2,  // ⭐ 4 → 2
                            }}>
                                {template.title}
                            </div>
                            <div style={{
                                fontSize: 13,  // ⭐ 16 → 13
                                opacity: 0.7,
                            }}>
                                {template.description}
                            </div>
                        </button>
                    );
                })}
            </div>
        </section>
    );
};

// 템플릿 색상 헬퍼 함수
const getTemplateColor = (colorClass) => {
    const colorMap = {
        'bg-blue-100': '#dbeafe',
        'bg-green-100': '#dcfce7',
        'bg-red-100': '#fee2e2',
        'bg-purple-100': '#f3e8ff',
        'bg-yellow-100': '#fef3c7',
        'bg-pink-100': '#fce7f3',
        'bg-orange-100': '#ffedd5',
        'bg-cyan-100': '#cffafe',
    };
    return colorMap[colorClass] || '#f5f5f5';
};

export default TemplateSelector;
