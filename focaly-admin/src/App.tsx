import { Navigate, Route, Routes } from 'react-router-dom';

import { DashboardLayout } from '@/components/layout/DashboardLayout';
import { ProtectedRoute } from '@/components/ProtectedRoute';
import { AiSettingsPage } from '@/pages/AiSettingsPage';
import { AnalyticsPage } from '@/pages/AnalyticsPage';
import { ContentPage } from '@/pages/ContentPage';
import { LoginPage } from '@/pages/LoginPage';
import { NotificationsPage } from '@/pages/NotificationsPage';
import { OverviewPage } from '@/pages/OverviewPage';
import { SubscriptionsPage } from '@/pages/SubscriptionsPage';
import { UserDetailPage } from '@/pages/UserDetailPage';
import { UsersPage } from '@/pages/UsersPage';

export default function App(): JSX.Element {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<DashboardLayout />}>
          <Route path="/" element={<OverviewPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="/users/:id" element={<UserDetailPage />} />
          <Route path="/subscriptions" element={<SubscriptionsPage />} />
          <Route path="/analytics" element={<AnalyticsPage />} />
          <Route path="/notifications" element={<NotificationsPage />} />
          <Route path="/content" element={<ContentPage />} />
          <Route path="/ai" element={<AiSettingsPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
