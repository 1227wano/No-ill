import React from 'react';
import Sidebar from '@/components/layout/AdminSidebar';
import Header from '@/components/layout/AdminHeader';
import DeviceStatusPanel from '@/components/common/DeviceStatusPanel';
import LastActivityPanel from '@/features/admin/LastActivityPanel';
import CallButton from '@/features/admin/CallButton';
import ActivityLogPanel from '@/features/admin/ActivityLogPanel';
import SnapshotPanel from '@/features/admin/SnapshotPanel';
import SchedulePanel from '@/features/schedule/AdminSchedulePanel';

const AdminPage = () => {
  return (
    <div className="flex w-full min-h-screen bg-[#F5F7FA] overflow-hidden">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-y-auto overflow-x-hidden min-w-0">
        <Header />
        <main className="py-[30px] px-10 flex-1">
          <div className="grid grid-cols-3 gap-6 w-full min-h-[200px] max-w-[1800px] mx-auto 
            xl:grid-cols-2 
            xl:max-w-[1600px]
            lg:grid-cols-1">
            {/* 첫 번째 행: 3개 컬럼 */}
            <div>
              <DeviceStatusPanel />
            </div>
            <div>
              <LastActivityPanel />
            </div>
            <div className="xl:col-span-2 lg:col-span-1">
              <CallButton />
            </div>
            {/* 두 번째 행: 2개 컬럼 */}
            <div>
              <ActivityLogPanel />
            </div>
            <div>
              <SnapshotPanel />
            </div>
            {/* 세 번째 행: 전체 너비 */}
            <div className="col-span-3 xl:col-span-2 lg:col-span-1">
              <SchedulePanel />
            </div>
          </div>
        </main>
      </div>
    </div>
  );
};

export default AdminPage;
