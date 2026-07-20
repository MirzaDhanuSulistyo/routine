import React from 'react';
import { Button, Card, Badge, IconButton, Alert } from '@andura-ui/react';
import { RoutineItem } from '../mockData';

interface TimelineViewProps {
  items: RoutineItem[];
  currentDate: string;
  onDateChange: (direction: 'prev' | 'next' | 'today') => void;
  onToggleStatus: (id: string) => void;
  onOpenBrief: (item: RoutineItem) => void;
  onFastLogClick: () => void;
  onAddItemClick: () => void;
}

export const TimelineView: React.FC<TimelineViewProps> = ({
  items,
  currentDate,
  onDateChange,
  onToggleStatus,
  onOpenBrief,
  onFastLogClick,
  onAddItemClick,
}) => {
  const morningItems = items.filter((i) => i.timeOfDay === 'morning');
  const afternoonItems = items.filter((i) => i.timeOfDay === 'afternoon');
  const eveningItems = items.filter((i) => i.timeOfDay === 'evening');

  const renderItemCard = (item: RoutineItem) => (
    <div key={item.id} className="item-card">
      <div className="item-header">
        <div className="item-title-row">
          <span className={`category-dot category-${item.category}`} title={`Category: ${item.category}`} />
          <div>
            <h4 style={{ margin: 0, fontSize: '15px', fontWeight: 600 }}>{item.title}</h4>
            <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '2px' }}>
              ⏰ {item.scheduledTime} &bull; <span style={{ textTransform: 'capitalize' }}>{item.itemType}</span>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {item.itemType === 'briefing' ? (
            <Button variant="secondary" onClick={() => onOpenBrief(item)}>
              Read Brief
            </Button>
          ) : (
            <Button
              variant={item.status === 'completed' ? 'secondary' : 'primary'}
              onClick={() => onToggleStatus(item.id)}
            >
              {item.status === 'completed' ? '✓ Done' : 'Complete'}
            </Button>
          )}
        </div>
      </div>

      {item.prepOffsetMinutes && (
        <div style={{ marginTop: '8px' }}>
          <Badge tone="neutral">⚡ Prep offset: {item.prepOffsetMinutes}m lead time</Badge>
        </div>
      )}

      {item.notes && <div className="item-notes">📝 <strong>Observation / Note:</strong> {item.notes}</div>}

      {item.eventTimestamp && (
        <div className="timestamps-meta">
          <span>🕒 Event Time: {item.eventTimestamp}</span>
          {item.recordedAtTimestamp && <span>💾 Recorded At: {item.recordedAtTimestamp}</span>}
        </div>
      )}
    </div>
  );

  return (
    <div>
      {/* Date Switcher */}
      <Card style={{ padding: '12px 16px', marginBottom: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: '8px' }}>
          <Button variant="secondary" onClick={() => onDateChange('prev')}>&larr; Prev</Button>
          <Button variant="secondary" onClick={() => onDateChange('today')}>Today</Button>
          <Button variant="secondary" onClick={() => onDateChange('next')}>Next &rarr;</Button>
        </div>
        <div style={{ fontWeight: 600, fontSize: '15px', color: '#38bdf8' }}>
          📅 {currentDate}
        </div>
      </Card>

      {/* Info Alert on 3-Layer Model */}
      <Alert intent="info" title="Unified Operational Timeline">
        Timeline displays planned commitments, actual logs, and topic briefs. Dual timestamps track when events occurred versus when they were recorded.
      </Alert>
      <br />

      {/* Morning Section */}
      <div className="time-section">
        <div className="time-section-title">🌅 Morning (05:00 - 12:00)</div>
        {morningItems.length > 0 ? morningItems.map(renderItemCard) : <div style={{ color: '#64748b' }}>No morning items.</div>}
      </div>

      {/* Afternoon Section */}
      <div className="time-section">
        <div className="time-section-title">☀️ Afternoon (12:00 - 18:00)</div>
        {afternoonItems.length > 0 ? afternoonItems.map(renderItemCard) : <div style={{ color: '#64748b' }}>No afternoon items.</div>}
      </div>

      {/* Evening Section */}
      <div className="time-section">
        <div className="time-section-title">🌙 Evening (18:00 - 24:00)</div>
        {eveningItems.length > 0 ? eveningItems.map(renderItemCard) : <div style={{ color: '#64748b' }}>No evening items.</div>}
      </div>
    </div>
  );
};
