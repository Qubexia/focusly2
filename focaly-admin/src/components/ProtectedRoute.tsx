import { Loader2 } from 'lucide-react';
import { Navigate, Outlet } from 'react-router-dom';

import { useAuth } from '@/context/AuthContext';

export function ProtectedRoute(): JSX.Element {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}
