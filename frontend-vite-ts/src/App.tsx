import { Link, NavLink, Route, Routes } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Orders from "./pages/Orders";
import Login from "./pages/Login";
import NotFound from "./pages/NotFound";
import { RequireAuth } from "./auth/RequireAuth";
import { useAuth } from "./auth/AuthContext";

function TopNav() {
  const { token, logout } = useAuth();

  return (
    <header className="topbar">
      <Link to="/" className="brand">Cheese IS</Link>

      <nav className="nav">
        <NavLink to="/" end>Главная</NavLink>
        <NavLink to="/orders">Заказы</NavLink>

        {/* Заготовки под “кнопки таблиц” */}
        <span className="divider" />
        <a href="#" className="disabled">Продукты</a>
        <a href="#" className="disabled">Партии</a>
        <a href="#" className="disabled">Поставки</a>
        <a href="#" className="disabled">Отчеты</a>
      </nav>

      <div className="right">
        {token ? (
          <button onClick={logout}>Logout</button>
        ) : (
          <NavLink to="/login">Login</NavLink>
        )}
      </div>
    </header>
  );
}

export default function App() {
  return (
    <>
      <TopNav />
      <Routes>
        <Route path="/login" element={<Login />} />

        <Route element={<RequireAuth />}>
          <Route path="/" element={<Dashboard />} />
          <Route path="/orders" element={<Orders />} />
        </Route>

        <Route path="*" element={<NotFound />} />
      </Routes>
    </>
  );
}
