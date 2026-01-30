import React from 'react';

import DisplayHeader from '@/components/layout/DisplayHeader'; 
import DisplayFooter from '@/components/layout/DisplayFooter';
import CommandsPanel from '@/components/common/CommandsPanel';
import GreetingCard from '@/components/common/GreetingCard'; 
import SchedulePanel from '@/features/schedule/DisplaySchedulePanel';

const DisplayPage = () => {
    return (
        <div className="min-h-screen bg-background flex flex-col">
            <DisplayHeader />
            <main className="flex-1 grid grid-cols-3 gap-6 py-6 px-10 w-full box-border">
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