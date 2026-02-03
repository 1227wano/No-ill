import React from 'react';

import DisplayHeader from '@/components/layout/DisplayHeader';
import CommandsPanel from '@/components/common/CommandsPanel';
import GreetingCard from '@/components/common/GreetingCard';
import IdleScreen from '@/components/common/IdleScreen';
import SchedulePanel from '@/features/schedule/DisplaySchedulePanel';
import useIdle from '@/hooks/useIdle';

const DisplayPage = () => {
    const { isIdle } = useIdle(60000); // 1분

    if (isIdle) {
        return <IdleScreen onWakeUp={() => {}} />;
    }

    return (
        <div className="h-screen bg-background flex flex-col overflow-hidden">
            <DisplayHeader />
            <main className="flex-1 grid grid-cols-3 gap-6 py-6 px-10 w-full box-border min-h-0">
                <div className="flex flex-col gap-6 min-h-0">
                    <GreetingCard />
                </div>
                <div className="flex flex-col gap-6 min-h-0">
                    <SchedulePanel />
                </div>
                <div className="flex flex-col gap-6 min-h-0">
                    <CommandsPanel />
                </div>
            </main>
        </div>
    );
};

export default DisplayPage;