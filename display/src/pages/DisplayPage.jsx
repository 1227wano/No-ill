// src/pages/DisplayPage.jsx

import React from 'react';
import DisplayHeader from '@/components/layout/DisplayHeader';
import CommandsPanel from '@/components/common/CommandsPanel';
import GreetingCard from '@/components/common/GreetingCard';
import IdleScreen from '@/components/common/IdleScreen';
import SchedulePanel from '@/features/schedule/components/DisplaySchedulePanel.jsx';
import useIdle from '@/hooks/useIdle';

// src/pages/DisplayPage.jsx

const DisplayPage = () => {
    const isIdle = useIdle(10000);

    // ✅ 2. 유휴 상태일 때 IdleScreen(보호 화면)을 우선적으로 보여줌
  if (isIdle) {
    return <IdleScreen />;
  }
  
  return (
    <div style={{
      width: 1920, height: 1080,
      background: 'var(--color-background)', // #FDFBF7
      position: 'relative', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* ✅ 글래스 효과를 살려줄 배경 '컬러 블러' 추가 */}
      <div style={{
        position: 'absolute', top: '-10%', right: '-5%',
        width: '600px', height: '600px',
        background: 'radial-gradient(circle, rgba(91,163,208,0.15) 0%, rgba(255,255,255,0) 70%)',
        filter: 'blur(80px)', zIndex: 0,
      }} />

      <div style={{ position: 'relative', zIndex: 1, display: 'flex', flexDirection: 'column', height: '100%' }}>
        <div style={{ height: 120 }}><DisplayHeader /></div>
        
        <main style={{
          flex: 1, display: 'grid', gridTemplateColumns: '600px 600px 600px',
          gap: 30, padding: '30px 45px', justifyContent: 'center',
        }}>
          {/* 패널들이 이제 이 배경 색상을 은은하게 머금게 됩니다. */}
          <GreetingCard />
          <SchedulePanel />
          <CommandsPanel />
        </main>
      </div>
    </div>
  );
};

export default DisplayPage;
