import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { useOverview, useRevenue } from '@/hooks/admin';

const COLORS = ['hsl(217 91% 60%)', 'hsl(142 71% 45%)', 'hsl(38 92% 50%)', 'hsl(0 84% 60%)'];

export function AnalyticsPage(): JSX.Element {
  const { data, isLoading } = useOverview();
  const { data: revenue } = useRevenue();

  if (isLoading || !data) {
    return (
      <div className="grid gap-4 lg:grid-cols-2">
        {Array.from({ length: 4 }).map((_, i) => (
          <Skeleton key={i} className="h-72" />
        ))}
      </div>
    );
  }

  const planData = [
    { name: 'Premium', value: data.users.premium },
    { name: 'Free', value: data.users.free },
  ];

  const aiData = [
    { name: 'Tokens in', value: data.ai.tokensIn },
    { name: 'Tokens out', value: data.ai.tokensOut },
  ];

  const statusData = Object.entries(revenue?.subscriptionsByStatus ?? {}).map(([name, value]) => ({
    name,
    value,
  }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Analytics</h1>
        <p className="text-sm text-muted-foreground">Platform-wide usage and revenue breakdowns.</p>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <ChartCard title="Plan distribution">
          <PieChart>
            <Pie data={planData} dataKey="value" nameKey="name" innerRadius={55} outerRadius={90}>
              {planData.map((_, i) => (
                <Cell key={i} fill={COLORS[i % COLORS.length]} />
              ))}
            </Pie>
            <Legend />
            <Tooltip contentStyle={tooltipStyle} />
          </PieChart>
        </ChartCard>

        <ChartCard title="AI token usage">
          <BarChart data={aiData}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="name" tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip contentStyle={tooltipStyle} />
            <Bar dataKey="value" radius={[4, 4, 0, 0]} fill="hsl(217 91% 60%)" />
          </BarChart>
        </ChartCard>

        <ChartCard title="Subscriptions by status">
          <BarChart data={statusData}>
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="name" tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis allowDecimals={false} tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip contentStyle={tooltipStyle} />
            <Bar dataKey="value" radius={[4, 4, 0, 0]} fill="hsl(142 71% 45%)" />
          </BarChart>
        </ChartCard>

        <ChartCard title="Engagement totals">
          <BarChart
            data={[
              { name: 'Pomodoros', value: data.engagement.pomodoroSessions },
              { name: 'Focus min', value: data.engagement.focusMinutes },
              { name: 'Tasks', value: data.engagement.tasksCompleted },
            ]}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
            <XAxis dataKey="name" tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
            <YAxis tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
            <Tooltip contentStyle={tooltipStyle} />
            <Bar dataKey="value" radius={[4, 4, 0, 0]} fill="hsl(38 92% 50%)" />
          </BarChart>
        </ChartCard>
      </div>
    </div>
  );
}

const tooltipStyle = {
  background: 'hsl(var(--popover))',
  border: '1px solid hsl(var(--border))',
  borderRadius: 8,
  fontSize: 12,
};

function ChartCard({ title, children }: { title: string; children: JSX.Element }): JSX.Element {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            {children}
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
