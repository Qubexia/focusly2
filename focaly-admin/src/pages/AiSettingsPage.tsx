import { Bot, CheckCircle2, KeyRound, Loader2, XCircle } from 'lucide-react';
import { useEffect, useState } from 'react';
import { toast } from 'sonner';

import { Badge } from '@/components/ui/badge';
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
import { Skeleton } from '@/components/ui/skeleton';
import { useAiSettings, useTestAiConnection, useUpdateAiSettings } from '@/hooks/admin';
import { apiErrorMessage } from '@/lib/api';
import { formatDateTime } from '@/lib/utils';

export function AiSettingsPage(): JSX.Element {
  const { data, isLoading } = useAiSettings();
  const updateMut = useUpdateAiSettings();
  const testMut = useTestAiConnection();

  const [enabled, setEnabled] = useState('true');
  const [model, setModel] = useState('');
  const [temperature, setTemperature] = useState('0.2');
  const [apiKey, setApiKey] = useState('');
  const [systemPrompt, setSystemPrompt] = useState('');

  useEffect(() => {
    if (data) {
      setEnabled(String(data.enabled));
      setModel(data.model);
      setTemperature(String(data.temperature));
      setSystemPrompt(data.systemPrompt ?? '');
    }
  }, [data]);

  if (isLoading || !data) {
    return <Skeleton className="h-96 w-full" />;
  }

  const onSave = (e: React.FormEvent): void => {
    e.preventDefault();
    updateMut.mutate(
      {
        enabled: enabled === 'true',
        model,
        temperature: Number(temperature),
        systemPrompt,
        // Only send apiKey when the admin typed a new one (avoid clearing the stored key).
        ...(apiKey ? { apiKey } : {}),
      },
      {
        onSuccess: () => {
          toast.success('AI settings saved');
          setApiKey('');
        },
        onError: (err) => toast.error(apiErrorMessage(err)),
      },
    );
  };

  const onTest = (): void => {
    testMut.mutate(apiKey || undefined, {
      onSuccess: (res) => {
        if (res.ok) toast.success(`Connection OK${res.model ? ` · ${res.model}` : ''}`);
        else toast.error(res.error ?? 'Connection failed');
      },
      onError: (err) => toast.error(apiErrorMessage(err)),
    });
  };

  const onClearKey = (): void => {
    updateMut.mutate(
      { apiKey: '' },
      {
        onSuccess: () => toast.success('Stored key cleared (falling back to env)'),
        onError: (err) => toast.error(apiErrorMessage(err)),
      },
    );
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-bold">
          <Bot className="h-6 w-6" /> AI Settings
        </h1>
        <p className="text-sm text-muted-foreground">
          Configure the OpenAI integration used for note summaries, flashcards, and quizzes.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Status</CardTitle>
          </CardHeader>
          <CardContent>
            {data.enabled ? (
              <Badge variant="success">Enabled</Badge>
            ) : (
              <Badge variant="destructive">Disabled</Badge>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">API key</CardTitle>
          </CardHeader>
          <CardContent>
            {data.apiKeySet ? (
              <div className="flex items-center gap-2">
                <KeyRound className="h-4 w-4 text-emerald-500" />
                <span className="font-mono text-sm">{data.apiKeyPreview}</span>
                <Badge variant="outline">{data.apiKeySource}</Badge>
              </div>
            ) : (
              <Badge variant="warning">Not set</Badge>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Model</CardTitle>
          </CardHeader>
          <CardContent className="font-medium">{data.model}</CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Configuration</CardTitle>
          <CardDescription>
            {data.updatedAt ? `Last updated ${formatDateTime(data.updatedAt)}` : 'Not yet configured'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSave} className="space-y-5">
            <div className="grid gap-4 sm:grid-cols-3">
              <div className="space-y-2">
                <Label>Status</Label>
                <Select value={enabled} onValueChange={setEnabled}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="model">Model</Label>
                <Input
                  id="model"
                  value={model}
                  onChange={(e) => setModel(e.target.value)}
                  placeholder="gpt-4o-mini"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="temp">Temperature</Label>
                <Input
                  id="temp"
                  type="number"
                  min={0}
                  max={2}
                  step={0.1}
                  value={temperature}
                  onChange={(e) => setTemperature(e.target.value)}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="apiKey">OpenAI API key</Label>
              <div className="flex gap-2">
                <Input
                  id="apiKey"
                  type="password"
                  autoComplete="off"
                  value={apiKey}
                  onChange={(e) => setApiKey(e.target.value)}
                  placeholder={data.apiKeySet ? '•••••• (leave blank to keep current)' : 'sk-…'}
                />
                <Button type="button" variant="outline" onClick={onTest} disabled={testMut.isPending}>
                  {testMut.isPending ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <CheckCircle2 className="h-4 w-4" />
                  )}
                  Test
                </Button>
              </div>
              {data.apiKeySource === 'database' ? (
                <button
                  type="button"
                  onClick={onClearKey}
                  className="flex items-center gap-1 text-xs text-destructive hover:underline"
                >
                  <XCircle className="h-3 w-3" /> Clear stored key (use env var instead)
                </button>
              ) : null}
            </div>

            <div className="space-y-2">
              <Label htmlFor="prompt">System prompt (optional)</Label>
              <textarea
                id="prompt"
                rows={4}
                value={systemPrompt}
                onChange={(e) => setSystemPrompt(e.target.value)}
                placeholder="Override the default study-assistant instructions…"
                className="flex w-full rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
              />
            </div>

            <Button type="submit" disabled={updateMut.isPending}>
              {updateMut.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Save settings
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
