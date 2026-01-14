import { Link, NavLink, Outlet } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export default function PublicLayout() {
  const { token, me, logout } = useAuth();
  const isStaff = !!me && me.role !== "client" && me.role !== "guest";

  return (
    <>
      <header className="topbar">
        <Link to="/" className="brand">Сирний світ</Link>

        <nav className="nav">
          <NavLink to="/" end>Каталог</NavLink>
          {me?.role === "client" && (
            <NavLink to="/orders">Мои заказы</NavLink>
          )}
          {token && <NavLink to="/profile">Профиль</NavLink>}

          <span className="divider" />
          {isStaff ? (
            <NavLink to="/admin">Панель</NavLink>
          ) : (
            <NavLink to="/admin/login">Панель</NavLink>
          )}
        </nav>

        <div className="right">
          {!token ? (
            <div className="row" style={{ gap: 8 }}>
              <Link to="/login"><button className="secondary" type="button">Вход</button></Link>
              <Link to="/register"><button className="secondary" type="button">Регистрация</button></Link>
              <Link to="/admin/login"><button type="button">Вход персонала</button></Link>
            </div>
          ) : (
            <div className="row" style={{ gap: 8 }}>
              <span className="pill">{me?.login} · {String(me?.role ?? "")}</span>
              {isStaff ? (
                <Link to="/admin"><button className="secondary" type="button">Панель</button></Link>
              ) : (
                <Link to="/orders"><button className="secondary" type="button">Заказы</button></Link>
              )}
              <button type="button" onClick={logout}>Выйти</button>
            </div>
          )}
        </div>
      </header>
      <main className="container">
        <Outlet />
      </main>
    </>
  );
}
