import { Link, NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

function can(role: string | undefined, allowed: string[]) {
  if (!role) return false;
  return allowed.includes(role);
}

export default function AdminLayout() {
  const { token, me, logout } = useAuth();
  const role = me?.role;

  // If someone hits /admin without auth, they will be redirected by RequireAuth.
  // Here we only render the menu.
  return (
    <>
      <header className="topbar">
        <Link to="/admin" className="brand">Сирний світ — панель</Link>

        <nav className="nav">
          <NavLink to="/admin" end>Дашборд</NavLink>

          <NavLink
            to="/admin/orders"
            className={({ isActive }) => {
              if (!can(role, ["manager", "admin"])) return "disabled";
              return isActive ? "active" : "";
            }}
          >
            Заказы
          </NavLink>

          <NavLink
            to="/admin/batches"
            className={({ isActive }) => {
              if (!can(role, ["technologist", "inspector", "manager", "admin"])) return "disabled";
              return isActive ? "active" : "";
            }}
          >
            Партии
          </NavLink>

          <NavLink
            to="/admin/quality"
            className={({ isActive }) => {
              if (!can(role, ["inspector", "technologist", "manager", "admin"])) return "disabled";
              return isActive ? "active" : "";
            }}
          >
            Качество
          </NavLink>

          <NavLink
            to="/admin/supplies"
            className={({ isActive }) => {
              if (!can(role, ["technologist", "manager", "admin"])) return "disabled";
              return isActive ? "active" : "";
            }}
          >
            Поставки
          </NavLink>

          <NavLink
            to="/admin/users"
            className={({ isActive }) => {
              if (!can(role, ["admin"])) return "disabled";
              return isActive ? "active" : "";
            }}
          >
            Пользователи
          </NavLink>

          <NavLink
            to="/admin/reports"
            className={({ isActive }) => {
              if (!can(role, ["admin"])) return "disabled";
              return isActive ? "active" : "";
            }}
          >
            Отчёты
          </NavLink>

          <span className="divider" />
          <NavLink to="/" end>Клиентский сайт</NavLink>
        </nav>

        <div className="right">
          {token ? (
            <button onClick={logout}>Выйти</button>
          ) : (
            <NavLink to="/admin/login">Вход</NavLink>
          )}
        </div>
      </header>
      <main className="container">
        <Outlet />
      </main>
    </>
  );
}
