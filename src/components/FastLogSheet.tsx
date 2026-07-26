import React, { useState } from 'react';
import { BottomSheet, TextArea, Input, Select, Button, ChoiceRow } from '@andura-ui/react';
import { RoutineItem, Category } from '../mockData';

interface FastLogSheetProps {
  open: boolean;
  onClose: () => void;
  onSaveLog: (logItem: Partial<RoutineItem>) => void;
}

export const FastLogSheet: React.FC<FastLogSheetProps> = ({ open, onClose, onSaveLog }) => {
  const [dateMode, setDateMode] = useState<'today' | 'yesterday' | 'tomorrow'>('today');
  const [category, setCategory] = useState<Category>('personal');
  const [notes, setNotes] = useState('');

  const handleSave = () => {
    if (!notes.trim()) return;

    let eventTime = '2026-07-20 09:00 AM';
    if (dateMode === 'yesterday') eventTime = '2026-07-19 09:00 AM (Backdated)';
    if (dateMode === 'tomorrow') eventTime = '2026-07-21 09:00 AM (Future-dated)';

    onSaveLog({
      id: Date.now().toString(),
      title: notes.slice(0, 30) || `${category} log`,
      itemType: 'log',
      category,
      timeOfDay: 'evening',
      scheduledTime: 'Fast Logged',
      status: 'logged',
      eventTimestamp: eventTime,
      recordedAtTimestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      notes: notes.trim(),
    });

    setNotes('');
    onClose();
  };

  return (
    <BottomSheet open={open} title="Fast Event & Observation Logger" onClose={onClose}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', padding: '16px 0' }}>
        <div>
          <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Target Date (Dual Timestamping)</label>
          <ChoiceRow
            values={['today', 'yesterday', 'tomorrow']}
            value={dateMode}
            onChange={(val) => setDateMode(val as any)}
          />
        </div>

        <div>
          <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Category</label>
          <Select value={category} onChange={(e) => setCategory(e.target.value as Category)}>
            <option value="personal">Personal / Life</option>
            <option value="work">Work</option>
            <option value="family">Family</option>
            <option value="home">Home</option>
            <option value="finance">Finance</option>
          </Select>
        </div>

        <div>
          <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>What happened or what did you observe?</label>
          <TextArea
            rows={3}
            placeholder="e.g. Plant leaves look yellow, slept 5 hours, car engine made unusual noise..."
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
          />
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '8px' }}>
          <Button variant="secondary" onClick={onClose}>Cancel</Button>
          <Button variant="primary" onClick={handleSave}>Save Log Entry</Button>
        </div>
      </div>
    </BottomSheet>
  );
};
