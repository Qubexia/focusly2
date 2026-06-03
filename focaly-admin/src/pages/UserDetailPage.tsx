import { ArrowLeft, Ban, Crown, ShieldCheck, Trash2 } from 'lucide-react';
import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { toast } from 'sonner';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
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
import {
  useUpdateUser,
  useUser,
  useUserAction,
  useUserSessions,
  useSubscriptionActions,
} from '@/hooks/admin';
import { apiErrorMessage } from '@/lib/api';
import { formatDate, formatDateTime, formatNumber } from '@/lib/utils';

export function UserDetailPage(): JSX.Element {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: user, isLoading } = useUser(id);
  const { data: sessions } = useUserSessions(id);
  const update = useUpdateUser(id ?? '');
  const actions = useUserAction(id ?? '');
  const subActions = useSubscriptionActions();

  const [editOpen, setEditOpen] = useState(false);
  const [extendDays, setExtendDays] = useState('30');

  if (isLoading || !user) {
    return <Skeleton className="h-96 w-full" />;
  }

  const onExtend = (): void => {
    subActions.extend.mutate(
      { userId: user.id, days: Number(extendDays) },
      {
        onSuccess: () => toast.success(`Extended premium by ${extendDays} days`),
        onError: (e) => toast.error(apiErrorMessage(e)),
      },
    );
  };

  return (
    <div className="space-y-6">
      <Button variant="ghost" size="sm" onClick={() => navigate('/users')}>
        <ArrowLeft className="h-4 w-4" /> Back to users
      </Button>

      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold">{user.name}</h1>
          <p className="text-sm text-muted-foreground">{user.email}</p>
          <div className="mt-2 flex flex-wrap gap-2">
            <Badge variant={user.plan === 'premium' ? 'default' : 'secondary'}>{user.plan}</Badge>
            <Badge variant={user.role === 'admin' ? 'default' : 'outline'}>{user.role}</Badge>
            {user.emailVerified ? (
              <Badge variant="success">verified</Badge>
            ) : (
              <Badge variant="warning">unverified</Badge>
            )}
            {user.isBanned ? <Badge variant="destructive">banned</Badge> : null}
          </div>
        </div>

        <div className="flex flex-wrap gap-2">
          <EditDialog
            open={editOpen}
            onOpenChange={setEditOpen}
            user={user}
            onSave={(payload) =>
              update.mutate(payload, {
                onSuccess: () => {
                  toast.success('User updated');
                  setEditOpen(false);
                },
                onError: (e) => toast.error(apiErrorMessage(e)),
              })
            }
            saving={update.isPending}
          />

          {user.isBanned ? (
            <Button
              variant="outline"
              onClick={() =>
                actions.unban.mutate(undefined, {
                  onSuccess: () => toast.success('User unbanned'),
                })
              }
            >
              <ShieldCheck className="h-4 w-4" /> Unban
            </Button>
          ) : (
            <Button
              variant="outline"
              onClick={() =>
                actions.ban.mutate(undefined, {
                  onSuccess: () => toast.success('User banned'),
                })
              }
            >
              <Ban className="h-4 w-4" /> Ban
            </Button>
          )}

          <Button
            variant="destructive"
            onClick={() => {
              if (!window.confirm('Delete this user account? This cannot be undone.')) return;
              actions.remove.mutate(undefined, {
                onSuccess: () => {
                  toast.success('User deleted');
                  navigate('/users');
                },
              });
            }}
          >
            <Trash2 className="h-4 w-4" /> Delete
          </Button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Focus minutes</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">
            {formatNumber(user.activity.focusMinutes)}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Tasks completed</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">
            {formatNumber(user.activity.plannedItemsCompleted)}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Current streak</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">{user.streak?.current ?? 0}</CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Crown className="h-4 w-4" /> Subscription
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-2 text-sm sm:grid-cols-2">
            <Info label="Plan" value={user.plan} />
            <Info label="Premium until" value={formatDate(user.premiumUntil)} />
            <Info label="Provider" value={user.subscription?.provider ?? '—'} />
            <Info label="Status" value={user.subscription?.status ?? 'none'} />
          </div>
          <div className="flex flex-wrap items-end gap-2">
            <div className="space-y-1">
              <Label htmlFor="days" className="text-xs">
                Extend premium (days)
              </Label>
              <Input
                id="days"
                type="number"
                min={1}
                className="w-28"
                value={extendDays}
                onChange={(e) => setExtendDays(e.target.value)}
              />
            </div>
            <Button onClick={onExtend} disabled={subActions.extend.isPending}>
              Extend
            </Button>
            <Button
              variant="outline"
              onClick={() =>
                subActions.cancel.mutate(user.id, {
                  onSuccess: () => toast.success('Subscription canceled'),
                  onError: (e) => toast.error(apiErrorMessage(e)),
                })
              }
            >
              Cancel premium
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Active sessions ({sessions?.length ?? 0})</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Device</TableHead>
                <TableHead>IP</TableHead>
                <TableHead>Created</TableHead>
                <TableHead className="text-right">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sessions && sessions.length > 0 ? (
                sessions.map((s) => (
                  <TableRow key={s.id}>
                    <TableCell className="max-w-[220px] truncate">{s.userAgent ?? s.deviceId}</TableCell>
                    <TableCell>{s.ip ?? '—'}</TableCell>
                    <TableCell>{formatDateTime(s.createdAt)}</TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() =>
                          actions.revokeSession.mutate(s.id, {
                            onSuccess: () => toast.success('Session revoked'),
                          })
                        }
                      >
                        Revoke
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={4} className="py-6 text-center text-muted-foreground">
                    No active sessions.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }): JSX.Element {
  return (
    <div>
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className="font-medium capitalize">{value}</div>
    </div>
  );
}

interface EditDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: { name: string; role: string; plan: string; emailVerified: boolean };
  onSave: (payload: {
    name: string;
    role: string;
    plan: string;
    emailVerified: boolean;
  }) => void;
  saving: boolean;
}

function EditDialog({ open, onOpenChange, user, onSave, saving }: EditDialogProps): JSX.Element {
  const [name, setName] = useState(user.name);
  const [role, setRole] = useState(user.role);
  const [plan, setPlan] = useState(user.plan);
  const [verified, setVerified] = useState(user.emailVerified);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogTrigger asChild>
        <Button>Edit</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit user</DialogTitle>
          <DialogDescription>Update profile, role, and plan.</DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Name</Label>
            <Input value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label>Role</Label>
              <Select value={role} onValueChange={setRole}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="user">User</SelectItem>
                  <SelectItem value="admin">Admin</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Plan</Label>
              <Select value={plan} onValueChange={setPlan}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="free">Free</SelectItem>
                  <SelectItem value="premium">Premium</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-2">
            <Label>Email verified</Label>
            <Select value={verified ? 'yes' : 'no'} onValueChange={(v) => setVerified(v === 'yes')}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="yes">Verified</SelectItem>
                <SelectItem value="no">Unverified</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        <DialogFooter>
          <Button
            onClick={() => onSave({ name, role, plan, emailVerified: verified })}
            disabled={saving}
          >
            Save changes
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
