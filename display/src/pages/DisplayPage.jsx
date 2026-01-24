import React from 'react';

import DisplayHeader from '@/components/layout/DisplayHeader'; 
import DisplayFooter from '@/components/layout/DisplayFooter';
import CommandsPanel from '@/components/common/CommandsPanel';
import GreetingCard from '@/components/common/GreetingCard'; 
import SchedulePanel from '@/features/schedule/DisplaySchedulePanel';

const DisplayPage = () => {
    return (
        <div className="min-h-screen bg-gradient-to-br from-[#F0F8FF] to-[#E6F3FF] flex flex-col">
            <DisplayHeader />
            <main className="flex-1 grid grid-cols-[1fr_1.5fr_1fr] gap-6 py-6 px-10 max-w-[1600px] mx-auto w-full box-border max-[1400px]:grid-cols-[1fr_1.2fr_1fr] max-[1200px]:grid-cols-1 max-[1200px]:gap-5">
                <div className="flex flex-col gap-6">
                    <GreetingCard />
                </div>
                <div className="flex flex-col gap-6">
                    <SchedulePanel />
                </div>
                <div className="flex flex-col gap-6">
                    <CommandsPanel />
                </div>
            </main>
            <DisplayFooter />
        </div>
    );
};

export default DisplayPage;