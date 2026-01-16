import React from 'react';
import Header from './Header';
import GreetingCard from './GreetingCard';
import SchedulePanel from './SchedulePanel';
import CommandsPanel from './CommandsPanel';
import Footer from './Footer';
import './Dashboard.css';

const Dashboard = () => {
  return (
    <div className="dashboard">
      <Header />
      <main className="dashboard-main">
        <div className="dashboard-left">
          <GreetingCard />
        </div>
        <div className="dashboard-center">
          <SchedulePanel />
        </div>
        <div className="dashboard-right">
          <CommandsPanel />
        </div>
      </main>
      <Footer />
    </div>
  );
};

export default Dashboard;
