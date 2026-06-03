import { useState } from 'react';

import { Pagination } from '@/components/Pagination';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { useAiJobs, usePlannedItems, useSubjects } from '@/hooks/admin';
import { formatDate, formatNumber } from '@/lib/utils';

const AI_STATUS: Record<string, 'success' | 'warning' | 'destructive' | 'secondary'> = {
  completed: 'success',
  processing: 'warning',
  queued: 'secondary',
  failed: 'destructive',
};

export function ContentPage(): JSX.Element {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Content</h1>
        <p className="text-sm text-muted-foreground">
          Inspect user-generated content and AI processing jobs.
        </p>
      </div>

      <Tabs defaultValue="subjects">
        <TabsList>
          <TabsTrigger value="subjects">Subjects</TabsTrigger>
          <TabsTrigger value="items">Planned items</TabsTrigger>
          <TabsTrigger value="ai">AI jobs</TabsTrigger>
        </TabsList>

        <TabsContent value="subjects">
          <SubjectsTab />
        </TabsContent>
        <TabsContent value="items">
          <ItemsTab />
        </TabsContent>
        <TabsContent value="ai">
          <AiTab />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function SubjectsTab(): JSX.Element {
  const [page, setPage] = useState(1);
  const { data } = useSubjects(page);
  return (
    <Card>
      <CardContent className="pt-6">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Progress</TableHead>
              <TableHead>Archived</TableHead>
              <TableHead>Created</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data?.items.map((s) => (
              <TableRow key={s.id}>
                <TableCell className="font-medium">{s.name}</TableCell>
                <TableCell>{s.progressPercent}%</TableCell>
                <TableCell>{s.isArchived ? 'Yes' : 'No'}</TableCell>
                <TableCell className="text-muted-foreground">{formatDate(s.createdAt)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {data ? (
          <Pagination page={data.page} pages={data.pages} total={data.total} onPageChange={setPage} />
        ) : null}
      </CardContent>
    </Card>
  );
}

function ItemsTab(): JSX.Element {
  const [page, setPage] = useState(1);
  const { data } = usePlannedItems(page);
  return (
    <Card>
      <CardContent className="pt-6">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Title</TableHead>
              <TableHead>Kind</TableHead>
              <TableHead>Completed</TableHead>
              <TableHead>Planned</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data?.items.map((it) => (
              <TableRow key={it.id}>
                <TableCell className="font-medium">{it.title}</TableCell>
                <TableCell className="capitalize">{it.kind}</TableCell>
                <TableCell>
                  {it.completed ? (
                    <Badge variant="success">done</Badge>
                  ) : (
                    <Badge variant="secondary">pending</Badge>
                  )}
                </TableCell>
                <TableCell className="text-muted-foreground">{formatDate(it.plannedAt)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {data ? (
          <Pagination page={data.page} pages={data.pages} total={data.total} onPageChange={setPage} />
        ) : null}
      </CardContent>
    </Card>
  );
}

function AiTab(): JSX.Element {
  const [page, setPage] = useState(1);
  const { data } = useAiJobs(page);
  return (
    <Card>
      <CardContent className="pt-6">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Job</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Tokens</TableHead>
              <TableHead>Created</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {data?.items.map((j) => (
              <TableRow key={j.id}>
                <TableCell className="font-mono text-xs">{j.id.slice(-8)}</TableCell>
                <TableCell>
                  <Badge variant={AI_STATUS[j.status] ?? 'secondary'}>{j.status}</Badge>
                  {j.failureReason ? (
                    <span className="ml-2 text-xs text-destructive">{j.failureReason}</span>
                  ) : null}
                </TableCell>
                <TableCell>
                  {formatNumber((j.tokensIn ?? 0) + (j.tokensOut ?? 0))}
                </TableCell>
                <TableCell className="text-muted-foreground">{formatDate(j.createdAt)}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        {data ? (
          <Pagination page={data.page} pages={data.pages} total={data.total} onPageChange={setPage} />
        ) : null}
      </CardContent>
    </Card>
  );
}
