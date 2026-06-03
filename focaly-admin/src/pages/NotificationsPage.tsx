import { Send } from 'lucide-react';
import { useState } from 'react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { useBroadcasts, useSendBroadcast } from '@/hooks/admin';
import { apiErrorMessage } from '@/lib/api';
import { formatDateTime } from '@/lib/utils';

export function NotificationsPage(): JSX.Element {
  const send = useSendBroadcast();
  const { data: broadcasts } = useBroadcasts();

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [type, setType] = useState('system');
  const [target, setTarget] = useState('all');
  const [push, setPush] = useState('false');

  const onSend = (e: React.FormEvent): void => {
    e.preventDefault();
    send.mutate(
      { title, body: body || undefined, type, target, push: push === 'true' },
      {
        onSuccess: (res) => {
          toast.success(`Sent to ${res.recipients} users (${res.pushed} pushed)`);
          setTitle('');
          setBody('');
        },
        onError: (err) => toast.error(apiErrorMessage(err)),
      },
    );
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Notifications</h1>
        <p className="text-sm text-muted-foreground">Broadcast announcements to your users.</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>New broadcast</CardTitle>
            <CardDescription>Delivered to each user&apos;s in-app inbox.</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={onSend} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="title">Title</Label>
                <Input
                  id="title"
                  required
                  maxLength={120}
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="New feature available!"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="body">Message</Label>
                <textarea
                  id="body"
                  rows={4}
                  maxLength={500}
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="Tell your users what's new…"
                  className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
                />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div className="space-y-2">
                  <Label>Audience</Label>
                  <Select value={target} onValueChange={setTarget}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Everyone</SelectItem>
                      <SelectItem value="premium">Premium</SelectItem>
                      <SelectItem value="free">Free</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Type</Label>
                  <Select value={type} onValueChange={setType}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="system">System</SelectItem>
                      <SelectItem value="reminder">Reminder</SelectItem>
                      <SelectItem value="reward">Reward</SelectItem>
                      <SelectItem value="streak">Streak</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Push</Label>
                  <Select value={push} onValueChange={setPush}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="false">Inbox only</SelectItem>
                      <SelectItem value="true">Also push (FCM)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <Button type="submit" disabled={send.isPending} className="w-full">
                <Send className="h-4 w-4" /> Send broadcast
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent broadcasts</CardTitle>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Title</TableHead>
                  <TableHead>Recipients</TableHead>
                  <TableHead>Sent</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {broadcasts && broadcasts.length > 0 ? (
                  broadcasts.map((b, i) => (
                    <TableRow key={i}>
                      <TableCell className="font-medium">{b.title}</TableCell>
                      <TableCell>{b.recipients}</TableCell>
                      <TableCell className="text-muted-foreground">
                        {formatDateTime(b.sentAt)}
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={3} className="py-8 text-center text-muted-foreground">
                      No broadcasts yet.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
