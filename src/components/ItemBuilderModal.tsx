import React, { useState } from 'react';
import { Dialog, Input, TextArea, Select, Button, ChoiceRow } from '@andura-ui/react';
import { RoutineItem, ItemType, Category } from '../mockData';

interface ItemBuilderModalProps {
  open: boolean;
  onClose: () => void;
  onSave: (newItem: Partial<RoutineItem>) => void;
}

export const ItemBuilderModal: React.FC<ItemBuilderModalProps> = ({ open, onClose, onSave }) => {
  const [title, setTitle] = useState('');
  const [itemType, setItemType] = useState<ItemType>('reminder');
  const [category, setCategory] = useState<Category>('work');
  const [timeOfDay, setTimeOfDay] = useState<'morning' | 'afternoon' | 'evening'>('morning');
  const [scheduledTime, setScheduledTime] = useState('08:00 AM');
  const [prepOffsetMinutes, setPrepOffsetMinutes] = useState<number | undefined>(undefined);
  const [notes, setNotes] = useState('');

  const handleSave = () => {
    if (!title.trim()) return;
    onSave({
      id: Date.now().toString(),
      title,
      itemType,
      category,
      timeOfDay,
      scheduledTime,
      prepOffsetMinutes,
      status: 'scheduled',
      notes: notes.trim() ? notes : undefined,
    });
    setTitle('');
    setNotes('');
    onClose();
  };

  return (
    <Dialog open={open} title="Create New Routine Item" onClose={onClose}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', padding: '12px 0' }}>
        <div>
          <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Item Behavior / Type</label>
          <ChoiceRow
            values={['reminder', 'task', 'maintenance', 'deadline', 'preparation', 'briefing']}
            value={itemType}
            onChange={(val) => setItemType(val as ItemType)}
          />
        </div>

        <div>
          <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Title</label>
          <Input placeholder="e.g. Clock In, Water plants, Math practice" value={title} onChange={(e) => setTitle(e.target.value)} />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
          <div>
            <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Category</label>
            <Select value={category} onChange={(e) => setCategory(e.target.value as Category)}>
              <option value="work">Work</option>
              <option value="family">Family</option>
              <option value="home">Home</option>
              <option value="finance">Finance</option>
              <option value="personal">Personal</option>
            </Select>
          </div>

          <div>
            <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Time Window</label>
            <Select value={timeOfDay} onChange={(e) => setTimeOfDay(e.target.value as any)}>
              <option value="morning">Morning</option>
              <option value="afternoon">Afternoon</option>
              <option value="evening">Evening</option>
            </Select>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
          <div>
            <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Scheduled Time</label>
            <Input value={scheduledTime} onChange={(e) => setScheduledTime(e.target.value)} placeholder="08:00 AM" />
          </div>

          <div>
            <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Prep Lead Time (Mins)</label>
            <Input
              type="number"
              placeholder="e.g. 10"
              value={prepOffsetMinutes ?? ''}
              onChange={(e) => setPrepOffsetMinutes(e.target.value ? parseInt(e.target.value) : undefined)}
            />
          </div>
        </div>

        <div>
          <label style={{ fontSize: '13px', color: '#94a3b8', display: 'block', marginBottom: '6px' }}>Initial Notes / Observations</label>
          <TextArea rows={2} placeholder="Optional initial observation or instructions" value={notes} onChange={(e) => setNotes(e.target.value)} />
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
          <Button variant="secondary" onClick={onClose}>Cancel</Button>
          <Button variant="primary" onClick={handleSave}>Save Item</Button>
        </div>
      </div>
    </Dialog>
  );
};
