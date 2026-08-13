import { Loader2, Settings2, Shield, Wrench } from 'lucide-react';
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
import { usePlatformSettings, useUpdatePlatformSettings } from '@/hooks/admin';
import { apiErrorMessage } from '@/lib/api';
import { formatDateTime, formatMoney } from '@/lib/utils';

/** Major units in the form, minor units on the wire; blank means "use the env var". */
function toCents(value: string): number | null {
  const trimmed = value.trim();
  if (!trimmed) return null;
  const amount = Number(trimmed);
  return Number.isFinite(amount) ? Math.round(amount * 100) : null;
}

export function PlatformSettingsPage(): JSX.Element {
  const { data, isLoading } = usePlatformSettings();
  const updateMut = useUpdatePlatformSettings();

  const [premiumGatingEnabled, setPremiumGatingEnabled] = useState('false');
  const [freeSubjectLimit, setFreeSubjectLimit] = useState('3');
  const [aiHourlyLimit, setAiHourlyLimit] = useState('5');
  const [aiMonthlyLimit, setAiMonthlyLimit] = useState('30');
  const [maintenanceMode, setMaintenanceMode] = useState('false');
  const [maintenanceMessage, setMaintenanceMessage] = useState('');
  const [monthlyPrice, setMonthlyPrice] = useState('');
  const [yearlyPrice, setYearlyPrice] = useState('');
  const [currency, setCurrency] = useState('EGP');

  useEffect(() => {
    if (data) {
      setPremiumGatingEnabled(String(data.premiumGatingEnabled));
      setFreeSubjectLimit(String(data.freeSubjectLimit));
      setAiHourlyLimit(String(data.aiHourlyLimit));
      setAiMonthlyLimit(String(data.aiMonthlyLimit));
      setMaintenanceMode(String(data.maintenanceMode));
      setMaintenanceMessage(data.maintenanceMessage ?? '');
      setMonthlyPrice((data.pricing.monthlyCents / 100).toFixed(2));
      setYearlyPrice((data.pricing.yearlyCents / 100).toFixed(2));
      setCurrency(data.pricing.currency);
    }
  }, [data]);

  if (isLoading || !data) {
    return <Skeleton className="h-96 w-full" />;
  }

  const onSave = (e: React.FormEvent): void => {
    e.preventDefault();
    updateMut.mutate(
      {
        premiumGatingEnabled: premiumGatingEnabled === 'true',
        freeSubjectLimit: Number(freeSubjectLimit),
        aiHourlyLimit: Number(aiHourlyLimit),
        aiMonthlyLimit: Number(aiMonthlyLimit),
        maintenanceMode: maintenanceMode === 'true',
        maintenanceMessage,
        // Blank hands the price back to the env var rather than setting zero.
        premiumMonthlyPriceCents: toCents(monthlyPrice),
        premiumYearlyPriceCents: toCents(yearlyPrice),
        currency: currency.trim() ? currency.trim().toUpperCase() : null,
      },
      {
        onSuccess: () => toast.success('Platform settings saved'),
        onError: (err) => toast.error(apiErrorMessage(err)),
      },
    );
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-bold">
          <Settings2 className="h-6 w-6" /> Platform Settings
        </h1>
        <p className="text-sm text-muted-foreground">
          Control premium gating, free-tier limits, AI quotas, and maintenance mode across the app.
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm text-muted-foreground">
              <Shield className="h-4 w-4" /> Premium gating
            </CardTitle>
          </CardHeader>
          <CardContent>
            {data.premiumGatingEnabled ? (
              <Badge variant="success">Enforced</Badge>
            ) : (
              <Badge variant="warning">Disabled (all features free)</Badge>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Premium price</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-semibold">
              {formatMoney(data.pricing.monthlyCents, data.pricing.currency)}
              <span className="text-sm font-normal text-muted-foreground"> /mo</span>
            </div>
            <p className="mt-1 text-xs text-muted-foreground">
              {formatMoney(data.pricing.yearlyCents, data.pricing.currency)} /year
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-sm text-muted-foreground">
              <Wrench className="h-4 w-4" /> Maintenance
            </CardTitle>
          </CardHeader>
          <CardContent>
            {data.maintenanceMode ? (
              <Badge variant="destructive">Active</Badge>
            ) : (
              <Badge variant="outline">Off</Badge>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Configuration</CardTitle>
          <CardDescription>
            {data.updatedAt ? `Last updated ${formatDateTime(data.updatedAt)}` : 'Using defaults'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSave} className="space-y-6">
            <div className="space-y-4">
              <h3 className="text-sm font-semibold">Monetization</h3>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label>Premium gating</Label>
                  <Select value={premiumGatingEnabled} onValueChange={setPremiumGatingEnabled}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="false">Disabled — all users get premium features</SelectItem>
                      <SelectItem value="true">Enabled — enforce free vs premium</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="subjectLimit">Free subject limit</Label>
                  <Input
                    id="subjectLimit"
                    type="number"
                    min={0}
                    max={100}
                    value={freeSubjectLimit}
                    onChange={(e) => setFreeSubjectLimit(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <h3 className="text-sm font-semibold">Premium pricing</h3>
                <Badge variant={data.pricing.source.monthly === 'database' ? 'success' : 'outline'}>
                  {data.pricing.source.monthly === 'database' ? 'Set here' : 'From env'}
                </Badge>
              </div>
              <p className="text-xs text-muted-foreground">
                Charged by Paymob at checkout. Clear a field to fall back to the server env var.
                Store (Google Play / App Store) prices are set in their own consoles.
              </p>
              <div className="grid gap-4 sm:grid-cols-3">
                <div className="space-y-2">
                  <Label htmlFor="monthlyPrice">Monthly price</Label>
                  <Input
                    id="monthlyPrice"
                    type="number"
                    min={0}
                    step="0.01"
                    value={monthlyPrice}
                    onChange={(e) => setMonthlyPrice(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="yearlyPrice">Yearly price</Label>
                  <Input
                    id="yearlyPrice"
                    type="number"
                    min={0}
                    step="0.01"
                    value={yearlyPrice}
                    onChange={(e) => setYearlyPrice(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="currency">Currency</Label>
                  <Input
                    id="currency"
                    maxLength={3}
                    value={currency}
                    onChange={(e) => setCurrency(e.target.value.toUpperCase())}
                    placeholder="EGP"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="text-sm font-semibold">AI rate limits</h3>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="aiHourly">Jobs per hour (per user)</Label>
                  <Input
                    id="aiHourly"
                    type="number"
                    min={1}
                    max={1000}
                    value={aiHourlyLimit}
                    onChange={(e) => setAiHourlyLimit(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="aiMonthly">Jobs per month (per user)</Label>
                  <Input
                    id="aiMonthly"
                    type="number"
                    min={1}
                    max={10000}
                    value={aiMonthlyLimit}
                    onChange={(e) => setAiMonthlyLimit(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="text-sm font-semibold">Maintenance mode</h3>
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label>Status</Label>
                  <Select value={maintenanceMode} onValueChange={setMaintenanceMode}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="false">Off — app works normally</SelectItem>
                      <SelectItem value="true">On — block users (admins exempt)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2 sm:col-span-2">
                  <Label htmlFor="maintenanceMsg">Maintenance message (optional)</Label>
                  <Input
                    id="maintenanceMsg"
                    value={maintenanceMessage}
                    onChange={(e) => setMaintenanceMessage(e.target.value)}
                    placeholder="We are performing scheduled maintenance…"
                  />
                </div>
              </div>
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
