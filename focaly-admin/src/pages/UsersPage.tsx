import { Search } from 'lucide-react';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

import { Pagination } from '@/components/Pagination';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
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
import { useUsers, type UsersFilter } from '@/hooks/admin';
import { formatDate } from '@/lib/utils';

function PlanBadge({ plan }: { plan: string }): JSX.Element {
  return <Badge variant={plan === 'premium' ? 'default' : 'secondary'}>{plan}</Badge>;
}

function StatusBadge({
  banned,
  deleted,
}: {
  banned: boolean;
  deleted: boolean;
}): JSX.Element {
  if (deleted) return <Badge variant="destructive">deleted</Badge>;
  if (banned) return <Badge variant="warning">banned</Badge>;
  return <Badge variant="success">active</Badge>;
}

export function UsersPage(): JSX.Element {
  const navigate = useNavigate();
  const [filter, setFilter] = useState<UsersFilter>({ page: 1 });
  const [search, setSearch] = useState('');
  const { data, isLoading } = useUsers(filter);

  const update = (patch: Partial<UsersFilter>): void =>
    setFilter((f) => ({ ...f, ...patch, page: patch.page ?? 1 }));

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Users</h1>
        <p className="text-sm text-muted-foreground">Manage accounts, plans, and roles.</p>
      </div>

      <Card>
        <CardContent className="space-y-4 pt-6">
          <div className="flex flex-wrap items-center gap-3">
            <form
              className="relative flex-1 min-w-[200px]"
              onSubmit={(e) => {
                e.preventDefault();
                update({ q: search || undefined });
              }}
            >
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                className="pl-8"
                placeholder="Search email or name…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </form>

            <Select
              value={filter.plan ?? 'all'}
              onValueChange={(v) => update({ plan: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue placeholder="Plan" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All plans</SelectItem>
                <SelectItem value="free">Free</SelectItem>
                <SelectItem value="premium">Premium</SelectItem>
              </SelectContent>
            </Select>

            <Select
              value={filter.role ?? 'all'}
              onValueChange={(v) => update({ role: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue placeholder="Role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All roles</SelectItem>
                <SelectItem value="user">User</SelectItem>
                <SelectItem value="admin">Admin</SelectItem>
              </SelectContent>
            </Select>

            <Select
              value={filter.status ?? 'all'}
              onValueChange={(v) => update({ status: v === 'all' ? undefined : v })}
            >
              <SelectTrigger className="w-[140px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="banned">Banned</SelectItem>
                <SelectItem value="deleted">Deleted</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Joined</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading ? (
                Array.from({ length: 8 }).map((_, i) => (
                  <TableRow key={i}>
                    <TableCell colSpan={5}>
                      <Skeleton className="h-6 w-full" />
                    </TableCell>
                  </TableRow>
                ))
              ) : data && data.items.length > 0 ? (
                data.items.map((u) => (
                  <TableRow
                    key={u.id}
                    className="cursor-pointer"
                    onClick={() => navigate(`/users/${u.id}`)}
                  >
                    <TableCell>
                      <div className="font-medium">{u.name}</div>
                      <div className="text-xs text-muted-foreground">{u.email}</div>
                    </TableCell>
                    <TableCell>
                      <PlanBadge plan={u.plan} />
                    </TableCell>
                    <TableCell>
                      <Badge variant={u.role === 'admin' ? 'default' : 'outline'}>{u.role}</Badge>
                    </TableCell>
                    <TableCell>
                      <StatusBadge banned={u.isBanned} deleted={u.isDeleted} />
                    </TableCell>
                    <TableCell className="text-muted-foreground">{formatDate(u.createdAt)}</TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={5} className="py-8 text-center text-muted-foreground">
                    No users found.
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
