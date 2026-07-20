export type ItemType =
  | 'reminder'
  | 'task'
  | 'maintenance'
  | 'deadline'
  | 'preparation'
  | 'briefing'
  | 'log'
  | 'measurement';

export type Category = 'work' | 'family' | 'home' | 'finance' | 'personal';

export type ItemStatus = 'scheduled' | 'completed' | 'late' | 'skipped' | 'logged';

export interface RoutineItem {
  id: string;
  title: string;
  itemType: ItemType;
  category: Category;
  timeOfDay: 'morning' | 'afternoon' | 'evening';
  scheduledTime?: string;
  eventTimestamp?: string;
  recordedAtTimestamp?: string;
  status: ItemStatus;
  notes?: string;
  numericValue?: number;
  unit?: string;
  prepOffsetMinutes?: number;
  topicSources?: string[];
  briefStories?: {
    source: string;
    headline: string;
    summary: string;
    url: string;
  }[];
}

export const initialItems: RoutineItem[] = [
  {
    id: '1',
    title: 'Warm up car (Engine & AC prep)',
    itemType: 'preparation',
    category: 'home',
    timeOfDay: 'morning',
    scheduledTime: '06:40 AM',
    prepOffsetMinutes: 10,
    status: 'completed',
    eventTimestamp: '2026-07-20 06:42 AM',
    recordedAtTimestamp: '2026-07-20 06:42 AM',
    notes: 'Took two attempts to start smoothly'
  },
  {
    id: '2',
    title: 'Morning Briefing — Tech, Markets & Social Trends',
    itemType: 'briefing',
    category: 'personal',
    timeOfDay: 'morning',
    scheduledTime: '07:00 AM',
    status: 'completed',
    eventTimestamp: '2026-07-20 07:05 AM',
    recordedAtTimestamp: '2026-07-20 07:05 AM',
    topicSources: ['Reddit / r/technology', 'Bluesky / AI Update', 'GNews / Tech'],
    briefStories: [
      {
        source: 'Bluesky / AI Update',
        headline: 'Open-Source Multi-Modal Models Reach New Benchmarks',
        summary: 'New lightweight models achieve near state-of-the-art vision and code execution while running on consumer GPUs.',
        url: 'https://bsky.app'
      },
      {
        source: 'Reddit / r/technology',
        headline: 'Global Renewable Energy Grid Storage Surges 40%',
        summary: 'Grid battery deployments in Q2 surpassed all previous yearly milestones driven by lower LFP cell costs.',
        url: 'https://reddit.com'
      },
      {
        source: 'GNews / Markets',
        headline: 'Tech Earnings Week Kicks Off with Semiconductor Signals',
        summary: 'Key suppliers report strong server chip demand while consumer hardware orders normalize.',
        url: 'https://news.google.com'
      }
    ]
  },
  {
    id: '3',
    title: 'Clock In to Work',
    itemType: 'reminder',
    category: 'work',
    timeOfDay: 'morning',
    scheduledTime: '08:00 AM',
    status: 'completed',
    eventTimestamp: '2026-07-20 08:12 AM',
    recordedAtTimestamp: '2026-07-20 08:12 AM',
    notes: 'Arrived 12 minutes late due to road construction on 4th Ave'
  },
  {
    id: '4',
    title: 'Clock Out of Work',
    itemType: 'reminder',
    category: 'work',
    timeOfDay: 'afternoon',
    scheduledTime: '05:00 PM',
    status: 'scheduled'
  },
  {
    id: '5',
    title: 'Water Indoor & Balcony Plants',
    itemType: 'maintenance',
    category: 'home',
    timeOfDay: 'afternoon',
    scheduledTime: '06:00 PM',
    status: 'scheduled'
  },
  {
    id: '6',
    title: 'Help Son Practice Math (Multiplication Tables)',
    itemType: 'task',
    category: 'family',
    timeOfDay: 'evening',
    scheduledTime: '06:30 PM',
    status: 'scheduled'
  },
  {
    id: '7',
    title: 'Pay Monthly Electricity & Utility Bill',
    itemType: 'deadline',
    category: 'finance',
    timeOfDay: 'evening',
    scheduledTime: '08:00 PM',
    status: 'scheduled'
  },
  {
    id: '8',
    title: 'Daily Life Observation & Sleep Log',
    itemType: 'log',
    category: 'personal',
    timeOfDay: 'evening',
    scheduledTime: '09:00 PM',
    status: 'logged',
    eventTimestamp: '2026-07-20 09:15 AM',
    recordedAtTimestamp: '2026-07-20 09:15 AM',
    notes: 'Slept 5.5 hours. Plant soil looked unusually dry. Car engine hesitated slightly.',
    numericValue: 5.5,
    unit: 'hours sleep'
  }
];

export interface AnomalyReport {
  id: string;
  title: string;
  category: Category;
  severity: 'info' | 'warning' | 'danger';
  description: string;
  evidence: string[];
}

export const mockAnomalies: AnomalyReport[] = [
  {
    id: 'a1',
    title: 'Timing Shift: Work Clock-Out Delay',
    category: 'work',
    severity: 'warning',
    description: 'You clocked out >30 minutes late on 4 out of the last 6 workdays.',
    evidence: ['Tuesday: +35 mins', 'Wednesday: +40 mins', 'Thursday: +25 mins', 'Today: Pending']
  },
  {
    id: 'a2',
    title: 'Candidate Correlation: Overtime & Family Routines',
    category: 'family',
    severity: 'info',
    description: 'Observed relationship: On days when work clock-out occurred past 05:30 PM, your son’s math practice was marked skipped or delayed by over an hour.',
    evidence: ['Co-occurrence in 3 of 4 recent instances over 14 days.']
  },
  {
    id: 'a3',
    title: 'Repeated Observation: Vehicle Starting Delay',
    category: 'home',
    severity: 'warning',
    description: 'The note "car engine hesitated / multi-start" was logged 3 times in the last 7 days during morning car prep.',
    evidence: ['Jul 16: "Hesitated starting"', 'Jul 18: "Took 3 attempts"', 'Jul 20: "Took two attempts"']
  }
];
