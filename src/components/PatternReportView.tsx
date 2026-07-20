import React from 'react';
import { Stat, Card, Alert, Badge } from '@andura-ui/react';
import { mockAnomalies } from '../mockData';

export const PatternReportView: React.FC = () => {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      <Alert intent="info" title="Understand Layer — Rule Engine Intelligence">
        This view periodically analyzes your sliding 7-day logs for timing shifts, repeated observations, and candidate correlation trends.
      </Alert>

      {/* Summary Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '12px' }}>
        <Card style={{ padding: '16px' }}>
          <Stat label="7-Day Completion Rate" value="84%" change="+4% vs last week" intent="success" />
        </Card>
        <Card style={{ padding: '16px' }}>
          <Stat label="Total Items Tracked" value="42" change="Work, Family, Home" intent="neutral" />
        </Card>
        <Card style={{ padding: '16px' }}>
          <Stat label="Anomalies Detected" value="3" change="Requires attention" intent="warning" />
        </Card>
      </div>

      {/* Detected Anomalies */}
      <div>
        <h3 style={{ fontSize: '16px', fontWeight: 600, color: '#f8fafc', marginBottom: '12px' }}>
          Detected Patterns & Anomalies (7-Day Window)
        </h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {mockAnomalies.map((anomaly) => (
            <Card key={anomaly.id} style={{ padding: '16px', background: 'rgba(30, 41, 59, 0.7)', borderLeft: `4px solid ${anomaly.severity === 'warning' ? '#fbbf24' : '#38bdf8'}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                <span className={`category-dot category-${anomaly.category}`} />
                <h4 style={{ margin: 0, fontSize: '15px', color: '#f8fafc', flexGrow: 1, marginLeft: '8px' }}>
                  {anomaly.title}
                </h4>
                <Badge tone={anomaly.severity === 'warning' ? 'warning' : 'neutral'}>
                  {anomaly.severity.toUpperCase()}
                </Badge>
              </div>

              <p style={{ margin: '8px 0', fontSize: '13px', color: '#cbd5e1', lineHeight: '1.4' }}>
                {anomaly.description}
              </p>

              <div style={{ fontSize: '12px', color: '#94a3b8', background: 'rgba(0,0,0,0.2)', padding: '8px 12px', borderRadius: '6px', marginTop: '10px' }}>
                🔍 <strong>Evidence Log:</strong> {anomaly.evidence.join(' | ')}
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
};
