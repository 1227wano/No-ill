import React from 'react';
// 1. 레이아웃 관련 (앞서 분리하기로 한 구조 적용 시)
import DisplayHeader from '@/components/layout/DisplayHeader'; 
import DisplayFooter from '@/components/layout/DisplayFooter';

// 2. 공통 UI 관련 (도메인 지식이 없는 순수 UI)
import CommandsPanel from '@/components/common/CommandsPanel';

// 3. 기능(Feature) 관련
import GreetingCard from '@/components/common/GreetingCard'; 
import SchedulePanel from '@/features/schedule/DisplaySchedulePanel';

// import './DisplayPage.css';

const DisplayPage = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#F0F8FF] to-[#E6F3FF] flex flex-col">
      <DisplayHeader />
      <main className="flex-1 grid grid-cols-[1fr_1.5fr_1fr] gap-6 py-6 px-10 max-w-[1600px] mx-auto w-full box-border max-[1400px]:grid-cols-[1fr_1.2fr_1fr] max-[1200px]:grid-cols-1 max-[1200px]:gap-5">
        <div className="flex flex-col">
          <GreetingCard />
        </div>
        <div className="flex flex-col">
          <SchedulePanel />
        </div>
        <div className="flex flex-col">
          <CommandsPanel />
        </div>
      </main>
      <DisplayFooter />
    </div>
  );
};

export default DisplayPage;