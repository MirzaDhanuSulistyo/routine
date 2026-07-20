import React, { useState } from 'react';
import { Page, Tabs, Button, Dialog } from '@andura-ui/react';
import { initialItems, RoutineItem } from './mockData';
import { TimelineView } from './components/TimelineView';
import { PatternReportView } from './components/PatternReportView';
import { ItemBuilderModal } from './components/ItemBuilderModal';
import { FastLogSheet } from './components/FastLogSheet';
import { TopicBriefingModal } from './components/TopicBriefingModal';

export const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'timeline' | 'insights' | 'settings'>('timeline');
  const [items, setItems] = useState<RoutineItem[]>(initialItems);
  const [currentDate, setCurrentDate] = useState('Monday, Jul 20, 2026');

  // Modals
  const [isItemBuilderOpen, setIsItemBuilderOpen] = useState(false);
  const [isFastLogOpen, setIsFastLogOpen] = useState(false);
  const [selectedBriefItem, setSelectedBriefItem] = useState<RoutineItem | null>(null);

  const handleToggleStatus = (id: string) => {
    setItems((prev) =>
      prev.map((item) =>
        item.id === id
          ? {
              ...item,
              status: item.status === 'completed' ? 'scheduled' : 'completed',
              eventTimestamp: item.status === 'completed' ? undefined : new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
            }
          : item
      )
    );
  };

  const handleAddItem = (newItem: Partial<RoutineItem>) => {
    setItems((prev) => [...prev, newItem as RoutineItem]);
  };

  const handleFastLog = (newLog: Partial<RoutineItem>) => {
    setItems((prev) => [newLog as RoutineItem, ...prev]);
  };

  const handleDateChange = (direction: 'prev' | 'next' | 'today') => {
    if (direction === 'today') setCurrentDate('Monday, Jul 20, 2026');
    if (direction === 'prev') setCurrentDate('Sunday, Jul 19, 2026');
    if (direction === 'next') setCurrentDate('Tuesday, Jul 21, 2026');
  };

  return (
    <div>
      {/* Top sticky header */}
      <header className="app-header">
        <div className="brand-title">
          <span style={{ fontSize: '24px' }}>⚡</span>
          <div>
            <h1>Routine</h1>
            <div className="motto-tag">Remember it. Record it. Notice the pattern.</div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          <Button variant="secondary" onClick={() => setIsFastLogOpen(true)}>
            + Fast Log
          </Button>
          <Button variant="primary" onClick={() => setIsItemBuilderOpen(true)}>
            + New Item
          </Button>
        </div>
      </header>

      {/* Page Content */}
      <Page style={{ maxWidth: '840px', margin: '0 auto', padding: '24px 16px' }}>
        {/* Navigation Tabs */}
        <div className="nav-tabs-wrapper">
          <Tabs
            tabs={[
              { value: 'timeline', label: '📅 Timeline (Plan & Record)' },
              { value: 'insights', label: '📊 Weekly Pattern Report (Understand)' },
              { value: 'settings', label: '⚙️ Settings & Topics' },
            ]}
            value={activeTab}
            onChange={(val) => setActiveTab(val as any)}
          />
        </div>

        {/* Tab 1: Timeline */}
        {activeTab === 'timeline' && (
          <TimelineView
            items={items}
            currentDate={currentDate}
            onDateChange={handleDateChange}
            onToggleStatus={handleToggleStatus}
            onOpenBrief={(item) => setSelectedBriefItem(item)}
            onFastLogClick={() => setIsFastLogOpen(true)}
            onAddItemClick={() => setIsItemBuilderOpen(true)}
          />
        )}

        {/* Tab 2: Pattern Report */}
        {activeTab === 'insights' && <PatternReportView />}

        {/* Tab 3: Settings */}
        {activeTab === 'settings' && (
          <div style={{ background: 'rgba(30, 41, 59, 0.7)', padding: '20px', borderRadius: '12px', border: '1px solid rgba(255,255,255,0.08)' }}>
            <h3 style={{ margin: '0 0 16px 0' }}>Settings & Topic Subscriptions</h3>
            <p style={{ color: '#cbd5e1', fontSize: '14px' }}>
              Followed Topics for Morning Briefings: <strong>Tech & AI, Global Markets, Renewable Energy</strong>.
            </p>
            <p style={{ color: '#94a3b8', fontSize: '13px' }}>
              Connected Sources: <strong>Reddit (r/technology), Bluesky (AI Digest), Google News API</strong>.
            </p>
            <div style={{ marginTop: '16px' }}>
              <Button variant="secondary">Export Local Database Backup (JSON)</Button>
            </div>
          </div>
        )}
      </Page>

      {/* Floating Quick Action Buttons */}
      <div className="fab-container">
        <Button variant="secondary" onClick={() => setIsFastLogOpen(true)}>
          📝 Quick Log
        </Button>
        <Button variant="primary" onClick={() => setIsItemBuilderOpen(true)}>
          + Add Routine Item
        </Button>
      </div>

      {/* Modals & Sheets */}
      <ItemBuilderModal open={isItemBuilderOpen} onClose={() => setIsItemBuilderOpen(false)} onSave={handleAddItem} />

      <FastLogSheet open={isFastLogOpen} onClose={() => setIsFastLogOpen(false)} onSaveLog={handleFastLog} />

      <TopicBriefingModal
        item={selectedBriefItem}
        onClose={() => setSelectedBriefItem(null)}
        onCompleteBrief={handleToggleStatus}
      />
    </div>
  );
};

export default App;
