import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "./AuthContext";

type Props = {
  allowedRoles?: string[];
  redirectTo?: string;
};

export function RequireAuth({ allowedRoles, redirectTo }: Props) {
  const { token, me, isLoading } = useAuth();
  const loc = useLocation();

  if (!token) return <Navigate to={redirectTo ?? "/login"} replace state={{ from: loc.pathname }} />;
  if (isLoading) return <div className="page"><div className="card">Loading…</div></div>;

  if (allowedRoles && me && !allowedRoles.includes(me.role)) {
    // Role mismatch: send to a reasonable default
    const to = me.role === "client" ? "/" : "/admin";
    return <Navigate to={to} replace />;
  }

  return <Outlet />;
}
