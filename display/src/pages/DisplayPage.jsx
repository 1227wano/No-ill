// src/pages/DisplayPage.jsx

import React from 'react';
import DisplayHeader from '@/components/layout/DisplayHeader';
import CommandsPanel from '@/components/common/CommandsPanel';
import GreetingCard from '@/components/common/GreetingCard';
import IdleScreen from '@/components/common/IdleScreen';
import SchedulePanel from '@/features/schedule/components/DisplaySchedulePanel.jsx';
import useIdle from '@/hooks/useIdle';

const DisplayPage = () => {
    const { isIdle } = useIdle(60000); // 1분

    if (isIdle) {
        return <IdleScreen onWakeUp={() => {}} />;
    }

    return (
        <div style={{
            width: 1920,
            height: 1080,
            background: '#f5f5f5',
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
        }}>
            {/* 헤더 */}
            <div style={{
                height: 120,
                flexShrink: 0,
            }}>
                <DisplayHeader />
            </div>

            {/* 메인 콘텐츠 */}
            <main style={{
                flex: 1,
                display: 'grid',
                gridTemplateColumns: '600px 600px 600px',  // ⭐ 640 → 600
                gap: 30,  // ⭐ 40 → 30
                padding: '30px 45px',  // ⭐ 40px 60px → 30px 45px
                minHeight: 0,
                overflow: 'hidden',
            }}>
                {/* 왼쪽: 인사말 */}
                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 20,
                    minHeight: 0,
                    overflow: 'hidden',
                }}>
                    <GreetingCard />
                </div>

                {/* 중앙: 일정 */}
                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 20,
                    minHeight: 0,
                    overflow: 'hidden',
                }}>
                    <SchedulePanel />
                </div>

                {/* 오른쪽: 명령어 */}
                <div style={{
                    display: 'flex',
                    flexDirection: 'column',
                    gap: 20,
                    minHeight: 0,
                    overflow: 'hidden',
                }}>
                    <CommandsPanel />
                </div>
            </main>
        </div>
    );
};

export default DisplayPage;
