import React from 'react';
import { Dialog, Card, Badge, Button } from '@andura-ui/react';
import { RoutineItem } from '../mockData';

interface TopicBriefingModalProps {
  item: RoutineItem | null;
  onClose: () => void;
  onCompleteBrief: (id: string) => void;
}

export const TopicBriefingModal: React.FC<TopicBriefingModalProps> = ({ item, onClose, onCompleteBrief }) => {
  if (!item) return null;

  return (
    <Dialog open={!!item} title={item.title} onClose={onClose}>
      <div style={{ padding: '12px 0', display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {item.topicSources?.map((source) => (
            <Badge key={source} tone="neutral">
              {source}
            </Badge>
          ))}
        </div>

        <div style={{ fontSize: '13px', color: '#94a3b8' }}>
          Finite Scheduled Briefing • Delivered at {item.scheduledTime}
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {item.briefStories?.map((story, idx) => (
            <Card key={idx} style={{ padding: '14px', background: 'rgba(15, 23, 42, 0.6)' }}>
              <div style={{ fontSize: '11px', color: '#38bdf8', fontWeight: 600, textTransform: 'uppercase', marginBottom: '4px' }}>
                {story.source}
              </div>
              <h4 style={{ margin: '0 0 6px 0', fontSize: '15px', color: '#f8fafc' }}>{story.headline}</h4>
              <p style={{ margin: 0, fontSize: '13px', color: '#cbd5e1', lineHeight: '1.4' }}>{story.summary}</p>
              <div style={{ marginTop: '10px' }}>
                <a
                  href={story.url}
                  target="_blank"
                  rel="noreferrer"
                  style={{ color: '#818cf8', fontSize: '12px', textDecoration: 'none', fontWeight: 500 }}
                >
                  Read Source Article &rarr;
                </a>
              </div>
            </Card>
          ))}
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
          <Button variant="secondary" onClick={onClose}>Close</Button>
          <Button
            variant="primary"
            onClick={() => {
              onCompleteBrief(item.id);
              onClose();
            }}
          >
            ✓ Mark Briefing Complete
          </Button>
        </div>
      </div>
    </Dialog>
  );
};
