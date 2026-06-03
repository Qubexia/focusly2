import { Activity, Bot, CreditCard, Crown, Timer, UserCheck, Users } from 'lucide-react';
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { StatCard } from '@/components/StatCard';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { useOverview, useSignups } from '@/hooks/admin';
import { formatNumber } from '@/lib/utils';

export function OverviewPage(): JSX.Element {
  const { data, isLoading } = useOverview();
  const { data: signups } = useSignups();

  if (isLoading || !data) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} className="h-28" />
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Overview</h1>
        <p className="text-sm text-muted-foreground">Key metrics across the Focaly platform.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard title="Total Users" value={formatNumber(data.users.total)} icon={Users} />
        <StatCard
          title="Premium Users"
          value={formatNumber(data.users.premium)}
          icon={Crown}
          hint={`${formatNumber(data.users.free)} free`}
        />
        <StatCard title="Active (24h)" value={formatNumber(data.users.dau)} icon={UserCheck} />
        <StatCard title="Active (30d)" value={formatNumber(data.users.mau)} icon={Activity} />
        <StatCard
          title="Active Subscriptions"
          value={formatNumber(data.subscriptions.active)}
          icon={CreditCard}
        />
        <StatCard
          title="Focus Minutes"
          value={formatNumber(data.engagement.focusMinutes)}
          icon={Timer}
          hint={`${formatNumber(data.engagement.pomodoroSessions)} sessions`}
        />
        <StatCard
          title="Tasks Completed"
          value={formatNumber(data.engagement.tasksCompleted)}
          icon={Activity}
        />
        <StatCard
          title="AI Tokens Used"
          value={formatNumber(data.ai.totalTokens)}
          icon={Bot}
          hint={`${formatNumber(data.ai.jobs)} jobs`}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>New signups (last 30 days)</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={signups?.series ?? []}>
                <defs>
                  <linearGradient id="signupFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="hsl(217 91% 60%)" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="hsl(217 91% 60%)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
                <Tooltip
                  contentStyle={{
                    background: 'hsl(var(--popover))',
                    border: '1px solid hsl(var(--border))',
                    borderRadius: 8,
                    fontSize: 12,
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="count"
                  stroke="hsl(217 91% 60%)"
                  fill="url(#signupFill)"
                  strokeWidth={2}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
