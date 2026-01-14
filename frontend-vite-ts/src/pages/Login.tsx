import { useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export default function Login({ mode }: { mode: "client" | "staff" }) {
  const nav = useNavigate();
  const { login, me, logout } = useAuth();

  const title = mode === "staff" ? "Вход в панель" : "Вход клиента";

  const allowedRoles = useMemo(() => {
    return mode === "staff"
      ? new Set(["technologist", "inspector", "manager", "admin"])
      : new Set(["client", "admin"]);
  }, [mode]);

  const [loginValue, setLoginValue] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setIsSubmitting(true);
      setErr(null);
      const freshMe = await login(loginValue, password);
      const role = (freshMe?.role ?? "").toString();
      if (!allowedRoles.has(role)) {
        await logout();
        setErr(
          mode === "staff"
            ? `Роль “${role}” не имеет доступа к админке.`
            : `Роль “${role}” не может входить как клиент.`
        );
        return;
      }

      nav(mode === "staff" ? "/admin" : "/", { replace: true });
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div>
      <div className="pageTitle">
        <h1>{title}</h1>
        <div className="sub">
          {mode === "staff" ? "Только для сотрудников" : "Для оформления заказов"}
        </div>
      </div>

      <div className="card">
        <form onSubmit={onSubmit}>
          <div className="row">
            <label>
              Логин
              <input value={loginValue} onChange={(e) => setLoginValue(e.target.value)} autoComplete="username" />
            </label>
            <label>
              Пароль
              <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
            </label>
            <button type="submit" disabled={isSubmitting || !loginValue || !password}>Войти</button>
          </div>
        </form>

        {err && <div className="error">{err}</div>}

        <div className="hint" style={{ marginTop: 10 }}>
          {mode === "staff" ? (
            <>
              Клиентский сайт: <Link to="/">/</Link> • Клиентский вход: <Link to="/login">/login</Link> • Регистрация клиента: <Link to="/register">/register</Link>
            </>
          ) : (
            <>
              Нет аккаунта? <Link to="/register">Регистрация</Link> • Вход персонала: <Link to="/admin/login">/admin/login</Link>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
