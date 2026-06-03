import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { Pagination } from '@/components/Pagination';
import { StatCard } from '@/components/StatCard';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { useRevenue, useSubscriptions } from '@/hooks/admin';
import { formatDate, formatNumber } from '@/lib/utils';

const STATUS_VARIANT: Record<string, 'success' | 'warning' | 'destructive' | 'secondary'> = {
  active: 'success',
  trialing: 'success',
  past_due: 'warning',
  canceled: 'destructive',
  expired: 'secondary',
};

export function SubscriptionsPage(): JSX.Element {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<{ status?: string; provider?: string; page?: number }>({
    page: 1,
  });
  const { data, isLoading } = useSubscriptions(filter);
  const { data: revenue } = useRevenue();

  const update = (patch: Partial<typeof filter>): void =>
    setFilter((f) => ({ ...f, ...patch, page: patch.page ?? 1 }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Subscriptions &amp; Revenue</h1>
        <p className="text-sm text-muted-foreground">
          Monitor subscriptions across all payment providers.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Active subscriptions"
          value={formatNumber(revenue?.activeSubscriptions ?? 0)}
        />
        {revenue
          ? Object.entries(revenue.subscriptionsByProvider).map(([provider, count]) => (
              <StatCard key={provider} title={`${provider} subs`} value={formatNumber(count)} />
            ))
          : null}
      </div>

      <Card>
        <CardContent className="space-y-4 pt-6">
          <div className="flex flex-wrap gap-3">
            <Select
              value={filter.status ?? 'all'}
              onValueChange={(v) => update({ status: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[160px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="trialing">Trialing</SelectItem>
                <SelectItem value="past_due">Past due</SelectItem>
                <SelectItem value="canceled">Canceled</SelectItem>
                <SelectItem value="expired">Expired</SelectItem>
              </SelectContent>
            </Select>

            <Select
              value={filter.provider ?? 'all'}
              onValueChange={(v) => update({ provider: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[160px]">
                <SelectValue placeholder="Provider" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All providers</SelectItem>
                <SelectItem value="stripe">Stripe</SelectItem>
                <SelectItem value="paymob">Paymob</SelectItem>
                <SelectItem value="google_play">Google Play</SelectItem>
                <SelectItem value="app_store">App Store</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Provider</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Period end</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={5}>
                      <Skeleton className="h-6 w-full" />
                    </TableCell>
                  </TableRow>
                ))
              ) : data && data.items.length > 0 ? (
                data.items.map((s) => (
                  <TableRow key={s.id}>
                    <TableCell>
                      <div className="font-medium">{s.user?.name ?? '—'}</div>
                      <div className="text-xs text-muted-foreground">{s.user?.email ?? s.userId}</div>
                    </TableCell>
                    <TableCell className="capitalize">{s.provider}</TableCell>
                    <TableCell>
                      <Badge variant={STATUS_VARIANT[s.status] ?? 'secondary'}>{s.status}</Badge>
                    </TableCell>
                    <TableCell>{formatDate(s.currentPeriodEnd)}</TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" onClick={() => navigate(`/users/${s.userId}`)}>
                        Manage
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={5} className="py-8 text-center text-muted-foreground">
                    No subscriptions found.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>

          {data ? (
            <Pagination
              page={data.page}
              pages={data.pages}
              total={data.total}
              onPageChange={(p) => update({ page: p })}
            />
          ) : null}
        </CardContent>
      </Card>
    </div>
  );
}
