import React, { useState, useEffect } from 'react';
import { X, Clock, FileText, Bell, Calendar } from 'lucide-react';

/* eslint-disable react-hooks/set-state-in-effect */

const hours = Array.from({ length: 24 }, (_, i) => String(i).padStart(2, '0'));
const minutes = ['00', '30'];

// 기존 템플릿 유지 + 디자인 톤 최적화
const templates = [
  { title: '💊 약 복용', description: '잊지 말고 챙겨드세요', colorClass: 'bg-blue-50 text-[#5BA3D0] border-blue-100' },
  { title: '🏥 병원 방문', description: '예약 시간을 확인하세요', colorClass: 'bg-indigo-50 text-indigo-500 border-indigo-100' },
  { title: '🤝 방문 일정', description: '선생님 방문 날입니다', colorClass: 'bg-slate-50 text-slate-600 border-slate-200' },
  { title: '🚶 산책', description: '가볍게 몸을 움직여요', colorClass: 'bg-cyan-50 text-cyan-600 border-cyan-100' }
];

const ScheduleModal = ({ isOpen, onClose, onSave, editingItem }) => {
  const [formData, setFormData] = useState({
    hour: '12',
    minute: '00',
    content: '',
    description: '',
    alertType: 'Voice & Screen'
  });

  const now = new Date();
  const currentHour = now.getHours();
  const currentMinute = now.getMinutes();

  useEffect(() => {
     
    // 모달이 열려 있을 때만 로직이 실행되도록 전체를 감쌉니다.
    if (!isOpen) return;
    if (editingItem) {
      // 수정 모드: 기존 데이터 파싱하여 기입력
      const [h, m] = (editingItem.schTime?.split('T')[1] || "12:00").split(':');
      setFormData({
        hour: h,
        minute: m.substring(0, 2),
        content: editingItem.schName || '',
        description: editingItem.schMemo || '',
      });
    } else if (isOpen) {
      // 신규 등록: 현재 시간 기준 가장 가까운 미래 30분 설정
      let defaultH = currentHour;
      let defaultM = currentMinute < 30 ? '30' : '00';
      if (currentMinute >= 30) defaultH = (defaultH + 1) % 24;

      setFormData({
        hour: String(defaultH).padStart(2, '0'),
        minute: defaultM,
        content: '',
        description: '',
      });
    }
  }, [editingItem, isOpen, currentHour, currentMinute]);

  const handleTemplateClick = (t) => {
    setFormData(prev => ({ ...prev, content: t.title, description: t.description }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave({
      ...formData,
      time: `${formData.hour}:${formData.minute}`
    });
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/40 backdrop-blur-sm flex items-center justify-center z-[100] p-4">
      <div className="bg-white rounded-[2.5rem] shadow-2xl w-full max-w-lg overflow-hidden animate-in fade-in zoom-in duration-200">
        {/* 헤더 */}
        <div className="bg-[#5BA3D0] p-6 flex justify-between items-center text-white">
          <span className="font-bold text-xl flex items-center gap-2">
            <Calendar size={22} /> {editingItem ? '일정 수정하기' : '새 일정 등록하기'}
          </span>
          <button onClick={onClose} className="hover:bg-white/20 rounded-full p-1.5 transition-colors"><X size={24} /></button>
        </div>

        {/* 폼 내용 (스크롤 가능 영역) */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6 max-h-[80vh] overflow-y-auto scrollbar-hide">
          
          {/* 1. 템플릿 선택 */}
          <section>
            <label className="text-sm font-bold text-gray-500 mb-3 block flex items-center gap-2">
              <FileText size={16} /> 추천 템플릿
            </label>
            <div className="grid grid-cols-2 gap-2">
              {templates.map((t) => (
                <button 
                  key={t.title} 
                  type="button" 
                  onClick={() => handleTemplateClick(t)}
                  className={`text-left p-3 rounded-2xl border-2 transition-all hover:scale-[1.02] active:scale-95 ${t.colorClass} ${formData.content === t.title ? 'ring-2 ring-[#5BA3D0] border-transparent' : 'border-transparent'}`}
                >
                  <div className="font-bold text-[15px]">{t.title}</div>
                  <div className="text-[11px] opacity-70">{t.description}</div>
                </button>
              ))}
            </div>
          </section>

          {/* 2. 직접 입력 */}
          <section>
            <input 
              type="text" 
              placeholder="일정 이름을 입력하거나 선택하세요" 
              value={formData.content} 
              onChange={(e) => setFormData({...formData, content: e.target.value})}
              className="w-full p-4 bg-gray-50 border-2 border-transparent focus:border-[#5BA3D0] rounded-2xl outline-none transition-all text-lg font-medium" 
              required 
            />
          </section>

          {/* 3. 시간 선택 (분리형 스크롤 피커) */}
          <section>
            <label className="text-sm font-bold text-gray-500 mb-3 block flex items-center gap-2">
              <Clock size={16} /> 시간 설정 (30분 단위)
            </label>
            <div className="flex items-center justify-center gap-6 bg-gray-50 rounded-[2rem] p-4 border border-gray-100">
              {/* 시(Hour) 스크롤 */}
              <div className="flex flex-col items-center">
                <span className="text-[10px] text-gray-400 font-bold mb-2">시</span>
                <div className="h-36 overflow-y-auto snap-y snap-mandatory px-4 scrollbar-hide">
                  <div className="h-12" /> {/* 여백용 */}
                  {hours.map(h => {
                    const isPast = !editingItem && parseInt(h) < currentHour;
                    return (
                      <button
                        key={h}
                        type="button"
                        disabled={isPast}
                        onClick={() => setFormData({...formData, hour: h})}
                        className={`h-12 w-16 flex items-center justify-center snap-center text-2xl font-bold transition-all ${
                          formData.hour === h ? 'text-[#5BA3D0] scale-125' : isPast ? 'text-gray-200' : 'text-gray-400'
                        }`}
                      >
                        {h}
                      </button>
                    );
                  })}
                  <div className="h-12" /> {/* 여백용 */}
                </div>
              </div>

              <div className="text-3xl font-light text-gray-300 self-center mt-6">:</div>

              {/* 분(Minute) 스크롤 */}
              <div className="flex flex-col items-center">
                <span className="text-[10px] text-gray-400 font-bold mb-2">분</span>
                <div className="h-36 overflow-y-auto snap-y snap-mandatory px-4 scrollbar-hide">
                  <div className="h-12" />
                  {minutes.map(m => {
                    const isPast = !editingItem && parseInt(formData.hour) === currentHour && parseInt(m) <= currentMinute;
                    return (
                      <button
                        key={m}
                        type="button"
                        disabled={isPast}
                        onClick={() => setFormData({...formData, minute: m})}
                        className={`h-12 w-16 flex items-center justify-center snap-center text-2xl font-bold transition-all ${
                          formData.minute === m ? 'text-[#5BA3D0] scale-125' : isPast ? 'text-gray-200' : 'text-gray-400'
                        }`}
                      >
                        {m}
                      </button>
                    );
                  })}
                  <div className="h-12" />
                </div>
              </div>
            </div>
          </section>

          {/* 4. 추가 설정 */}
          <div className="space-y-4">
            
            <textarea 
              placeholder="메모를 입력하세요 (선택)" 
              value={formData.description} 
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              className="w-full p-4 bg-gray-50 border-none rounded-2xl outline-none h-24 resize-none text-base" 
            />
          </div>

          {/* 제출 버튼 */}
          <button 
            type="submit" 
            className="w-full bg-[#5BA3D0] text-white py-5 rounded-[1.5rem] text-xl font-bold hover:bg-[#4A8EB8] shadow-lg shadow-blue-100 transition-all active:scale-[0.98]"
          >
            {editingItem ? '수정 내용 저장하기' : '일정 등록 완료'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ScheduleModal;