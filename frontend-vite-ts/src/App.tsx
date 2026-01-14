import { Navigate, Route, Routes } from "react-router-dom";
import PublicLayout from "./layouts/PublicLayout";
import AdminLayout from "./layouts/AdminLayout";
import { RequireAuth } from "./auth/RequireAuth";

// Public / client pages
import Login from "./pages/Login";
import Register from "./pages/public/Register";
import Catalog from "./pages/public/Catalog";
import ClientOrders from "./pages/public/ClientOrders";
import CreateOrder from "./pages/public/CreateOrder";
import Profile from "./pages/public/Profile";

// Admin / staff pages
import AdminDashboard from "./pages/admin/AdminDashboard";
import OrdersAdmin from "./pages/admin/OrdersAdmin";
import Batches from "./pages/admin/Batches";
import Quality from "./pages/admin/Quality";
import Supplies from "./pages/admin/Supplies";
import Users from "./pages/admin/Users";
import Reports from "./pages/admin/Reports";

import NotFound from "./pages/NotFound";

const STAFF_ROLES = ["technologist", "inspector", "manager", "admin"];

export default function App() {
  return (
    <Routes>
      {/* Public + client area */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<Catalog />} />

        <Route path="/login" element={<Login mode="client" />} />
        <Route path="/register" element={<Register />} />
        <Route path="/admin/login" element={<Login mode="staff" />} />

        <Route element={<RequireAuth allowedRoles={["client", "admin"]} redirectTo="/login" />}>
          <Route path="/orders" element={<ClientOrders />} />
          <Route path="/orders/new" element={<CreateOrder />} />
        </Route>

        <Route element={<RequireAuth redirectTo="/login" />}>
          <Route path="/profile" element={<Profile />} />
        </Route>
      </Route>

      {/* Admin / staff area */}
      <Route element={<RequireAuth allowedRoles={STAFF_ROLES} redirectTo="/admin/login" />}>
        <Route element={<AdminLayout />}>
          <Route path="/admin" element={<AdminDashboard />} />

          <Route element={<RequireAuth allowedRoles={["manager", "admin"]} redirectTo="/admin/login" />}>
            <Route path="/admin/orders" element={<OrdersAdmin />} />
          </Route>

          <Route element={<RequireAuth allowedRoles={["technologist", "inspector", "manager", "admin"]} redirectTo="/admin/login" />}>
            <Route path="/admin/batches" element={<Batches />} />
            <Route path="/admin/quality" element={<Quality />} />
          </Route>

          <Route element={<RequireAuth allowedRoles={["technologist", "manager", "admin"]} redirectTo="/admin/login" />}>
            <Route path="/admin/supplies" element={<Supplies />} />
          </Route>

          <Route element={<RequireAuth allowedRoles={["admin"]} redirectTo="/admin/login" />}>
            <Route path="/admin/users" element={<Users />} />
            <Route path="/admin/reports" element={<Reports />} />
          </Route>
        </Route>
      </Route>

      {/* Convenience redirects */}
      <Route path="/client/orders" element={<Navigate to="/orders" replace />} />

      <Route path="*" element={<NotFound />} />
    </Routes>
  );
}
