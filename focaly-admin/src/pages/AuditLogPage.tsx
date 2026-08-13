import { useState } from 'react';

import { Pagination } from '@/components/Pagination';
import { Badge } from '@/components/ui/badge';
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
import { useAuditEventTypes, useAuditLogs, type AuditFilter } from '@/hooks/admin';
import { formatDateTime } from '@/lib/utils';

const ACTOR_VARIANT: Record<string, 'success' | 'warning' | 'destructive' | 'secondary'> = {
  admin: 'warning',
  user: 'secondary',
  system: 'secondary',
  webhook: 'success',
};

/** Destructive actions deserve to stand out in a wall of rows. */
const DESTRUCTIVE = ['delete', 'ban', 'revoke', 'cancel'];

export function AuditLogPage(): JSX.Element {
  const [filter, setFilter] = useState<AuditFilter>({ page: 1, actor: 'admin' });
  const { data, isLoading } = useAuditLogs(filter);
  const { data: eventTypes } = useAuditEventTypes();

  const update = (patch: Partial<AuditFilter>): void =>
    setFilter((f) => ({ ...f, ...patch, page: patch.page ?? 1 }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Audit log</h1>
        <p className="text-sm text-muted-foreground">
          Who changed what, and when. Every admin action that changes state is recorded here.
        </p>
      </div>

      <Card>
        <CardContent className="space-y-4 pt-6">
          <div className="flex flex-wrap gap-3">
            <Select
              value={filter.actor ?? 'all'}
              onValueChange={(v) => update({ actor: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Actor" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All actors</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
                <SelectItem value="user">User</SelectItem>
                <SelectItem value="webhook">Webhook</SelectItem>
                <SelectItem value="system">System</SelectItem>
              </SelectContent>
            </Select>

            <Select
              value={filter.eventType ?? 'all'}
              onValueChange={(v) => update({ eventType: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[240px]">
                <SelectValue placeholder="Event type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All events</SelectItem>
                {(eventTypes ?? []).map((type) => (
                  <SelectItem key={type} value={type}>
                    {type}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>When</TableHead>
                <TableHead>Actor</TableHead>
                <TableHead>Performed by</TableHead>
                <TableHead>Event</TableHead>
                <TableHead>Target</TableHead>
                <TableHead>Details</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 8 }).map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={6}>
                      <Skeleton className="h-6 w-full" />
                    </TableCell>
                  </TableRow>
                ))
              ) : data && data.items.length > 0 ? (
                data.items.map((entry) => {
                  const destructive = DESTRUCTIVE.some((word) => entry.eventType.includes(word));
                  return (
                    <TableRow key={entry.id}>
                      <TableCell className="whitespace-nowrap text-sm text-muted-foreground">
                        {formatDateTime(entry.createdAt)}
                      </TableCell>
                      <TableCell>
                        <Badge variant={ACTOR_VARIANT[entry.actor] ?? 'secondary'}>
                          {entry.actor}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-sm">
                        {entry.actorUser?.email ?? entry.actorUser?.name ?? '—'}
                      </TableCell>
                      <TableCell>
                        <span
                          className={
                            destructive ? 'font-mono text-xs text-destructive' : 'font-mono text-xs'
                          }
                        >
                          {entry.eventType}
                        </span>
                      </TableCell>
                      <TableCell className="text-sm">
                        {entry.subject?.email ?? entry.subject?.name ?? '—'}
                      </TableCell>
                      <TableCell className="max-w-[280px]">
                        <span className="block truncate font-mono text-xs text-muted-foreground">
                          {summarise(entry.data)}
                        </span>
                      </TableCell>
                    </TableRow>
                  );
                })
              ) : (
                <TableRow>
                  <TableCell colSpan={6} className="py-8 text-center text-muted-foreground">
                    No audit entries found.
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

/** The request body is the interesting part; the rest is route noise. */
function summarise(data: Record<string, unknown> | null): string {
  if (!data) return '—';
  const body = data.body;
  if (body && typeof body === 'object' && Object.keys(body).length > 0) {
    return JSON.stringify(body);
  }
  return typeof data.path === 'string' ? data.path : '—';
}
