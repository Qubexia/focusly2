import { useState } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';

import { Pagination } from '@/components/Pagination';
import { StatCard } from '@/components/StatCard';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
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
import { usePayments, useRevenueReport, type PaymentsFilter } from '@/hooks/admin';
import { formatDateTime, formatMoney, formatNumber } from '@/lib/utils';

const OUTCOME_VARIANT: Record<string, 'success' | 'warning' | 'destructive' | 'secondary'> = {
  applied: 'success',
  noop: 'secondary',
  error: 'destructive',
};

const RANGES = [
  { value: '7', label: 'Last 7 days' },
  { value: '30', label: 'Last 30 days' },
  { value: '90', label: 'Last 90 days' },
  { value: '365', label: 'Last 12 months' },
];

function isoDaysAgo(days: number): string {
  return new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
}

export function PaymentsPage(): JSX.Element {
  const [rangeDays, setRangeDays] = useState('30');
  const [filter, setFilter] = useState<PaymentsFilter>({ page: 1 });
  const [search, setSearch] = useState('');

  const interval = Number(rangeDays) > 120 ? 'month' : 'day';
  const { data: revenue } = useRevenueReport({ from: isoDaysAgo(Number(rangeDays)), interval });
  const { data, isLoading } = usePayments(filter);

  const update = (patch: Partial<PaymentsFilter>): void =>
    setFilter((f) => ({ ...f, ...patch, page: patch.page ?? 1 }));

  const currency = revenue?.currency ?? 'EGP';

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Payments &amp; Revenue</h1>
          <p className="text-sm text-muted-foreground">
            Every settled transaction, and the money it actually brought in.
          </p>
        </div>
        <Select value={rangeDays} onValueChange={setRangeDays}>
          <SelectTrigger className="w-[170px]">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {RANGES.map((r) => (
              <SelectItem key={r.value} value={r.value}>
                {r.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Gross revenue"
          value={formatMoney(revenue?.grossCents, currency)}
          hint={`${formatNumber(revenue?.payments ?? 0)} payments in range`}
        />
        <StatCard
          title="Average payment"
          value={formatMoney(revenue?.averagePaymentCents, currency)}
        />
        <StatCard
          title="All-time revenue"
          value={formatMoney(revenue?.allTimeGrossCents, currency)}
          hint={`${formatNumber(revenue?.allTimePayments ?? 0)} payments total`}
        />
        <StatCard
          title="Paid subscriptions"
          value={formatNumber(
            (revenue?.byPlan ?? []).reduce((sum, row) => sum + row.payments, 0),
          )}
          hint={(revenue?.byPlan ?? [])
            .map((row) => `${row.key}: ${formatNumber(row.payments)}`)
            .join(' · ')}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">Revenue over time</CardTitle>
          </CardHeader>
          <CardContent>
            {revenue && revenue.series.length > 0 ? (
              <div className="h-52">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={revenue.series.map((p) => ({ ...p, gross: p.grossCents / 100 }))}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                    <XAxis
                      dataKey="period"
                      tick={{ fontSize: 11 }}
                      stroke="hsl(var(--muted-foreground))"
                    />
                    <YAxis tick={{ fontSize: 11 }} stroke="hsl(var(--muted-foreground))" />
                    <Tooltip
                      contentStyle={{
                        background: 'hsl(var(--popover))',
                        border: '1px solid hsl(var(--border))',
                        borderRadius: 8,
                        fontSize: 12,
                      }}
                      formatter={(value: number) => formatMoney(value * 100, currency)}
                    />
                    <Bar dataKey="gross" radius={[4, 4, 0, 0]} fill="hsl(142 71% 45%)" />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <p className="py-12 text-center text-sm text-muted-foreground">
                No revenue recorded in this range.
              </p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">By provider</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {revenue && revenue.byProvider.length > 0 ? (
              revenue.byProvider.map((row) => (
                <div key={row.key} className="flex items-center justify-between text-sm">
                  <span className="capitalize text-muted-foreground">
                    {row.key.replace('_', ' ')}
                  </span>
                  <span className="font-medium">{formatMoney(row.grossCents, currency)}</span>
                </div>
              ))
            ) : (
              <p className="text-sm text-muted-foreground">No payments yet.</p>
            )}
            {revenue && revenue.byCurrency.length > 1 ? (
              <p className="pt-2 text-xs text-muted-foreground">
                Other currencies present:{' '}
                {revenue.byCurrency
                  .filter((c) => c.key !== currency)
                  .map((c) => `${c.key} (${c.payments})`)
                  .join(', ')}
              </p>
            ) : null}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardContent className="space-y-4 pt-6">
          <div className="flex flex-wrap gap-3">
            <form
              className="flex-1 min-w-[220px]"
              onSubmit={(e) => {
                e.preventDefault();
                update({ q: search.trim() || undefined });
              }}
            >
              <Input
                placeholder="Search by payer email, name or transaction id…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </form>

            <Select
              value={filter.provider ?? 'all'}
              onValueChange={(v) => update({ provider: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[160px]">
                <SelectValue placeholder="Provider" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All providers</SelectItem>
                <SelectItem value="paymob">Paymob</SelectItem>
                <SelectItem value="google_play">Google Play</SelectItem>
                <SelectItem value="app_store">App Store</SelectItem>
              </SelectContent>
            </Select>

            <Select
              value={filter.outcome ?? 'all'}
              onValueChange={(v) => update({ outcome: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Outcome" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All outcomes</SelectItem>
                <SelectItem value="applied">Applied</SelectItem>
                <SelectItem value="noop">No-op</SelectItem>
                <SelectItem value="error">Error</SelectItem>
              </SelectContent>
            </Select>

            <Select
              value={filter.plan ?? 'all'}
              onValueChange={(v) => update({ plan: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue placeholder="Plan" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All plans</SelectItem>
                <SelectItem value="monthly">Monthly</SelectItem>
                <SelectItem value="yearly">Yearly</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Payer</TableHead>
                <TableHead>Provider</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>Outcome</TableHead>
                <TableHead>Transaction</TableHead>
                <TableHead>Date</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={7}>
                      <Skeleton className="h-6 w-full" />
                    </TableCell>
                  </TableRow>
                ))
              ) : data && data.items.length > 0 ? (
                data.items.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell>
                      <div className="font-medium">{p.user?.name ?? '—'}</div>
                      <div className="text-xs text-muted-foreground">
                        {p.user?.email ?? p.userId ?? 'unknown'}
                      </div>
                    </TableCell>
                    <TableCell className="capitalize">{p.provider.replace('_', ' ')}</TableCell>
                    <TableCell className="capitalize">{p.plan ?? '—'}</TableCell>
                    <TableCell className="text-right font-medium">
                      {p.amountCents ? formatMoney(p.amountCents, p.currency ?? currency) : '—'}
                    </TableCell>
                    <TableCell>
                      <Badge variant={OUTCOME_VARIANT[p.outcome ?? ''] ?? 'secondary'}>
                        {p.outcome ?? 'pending'}
                      </Badge>
                    </TableCell>
                    <TableCell className="max-w-[180px] truncate font-mono text-xs">
                      {p.providerTxId ?? p.eventId}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-sm text-muted-foreground">
                      {formatDateTime(p.createdAt)}
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={7} className="py-8 text-center text-muted-foreground">
                    No payments found.
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

      <p className="text-xs text-muted-foreground">
        Store purchases (Google Play / App Store) are billed by the store, so their amounts are not
        visible here — only Paymob amounts are recorded server-side.
      </p>
    </div>
  );
}
