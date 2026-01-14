import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../../app/api";
import { useAuth } from "../../auth/AuthContext";

type RegisterPayload = {
  login: string;
  password: string;
  email: string;
  phone?: string | null;
  first_name: string;
  last_name: string;
};

export default function Register() {
  const nav = useNavigate();
  const { login: doLogin } = useAuth();

  const [form, setForm] = useState<RegisterPayload>({
    login: "",
    password: "",
    email: "",
    phone: "",
    first_name: "",
    last_name: "",
  });
  const [password2, setPassword2] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const set = (k: keyof RegisterPayload, v: string) => {
    setForm((p) => ({ ...p, [k]: v }));
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setErr(null);
      if (form.password.length < 8) {
        setErr("Пароль должен быть не короче 8 символов");
        return;
      }
      if (form.password !== password2) {
        setErr("Пароли не совпадают");
        return;
      }

      setIsSubmitting(true);
      await api.post("/auth/register", {
        ...form,
        phone: form.phone?.trim() ? form.phone.trim() : null,
      });

      // Auto-login for a smoother UX.
      const me = await doLogin(form.login, form.password);
      const role = (me?.role ?? "").toString();
      if (role !== "client" && role !== "admin") {
        // Shouldn't happen for register, but keep it safe.
        setErr(`Учетная запись создана, но роль “${role}” не может войти как клиент.`);
        return;
      }

      nav("/orders/new", { replace: true });
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    } finally {
      setIsSubmitting(false);
    }
  };

  const canSubmit =
    form.login.trim() &&
    form.password &&
    password2 &&
    form.first_name.trim() &&
    form.last_name.trim() &&
    form.email.trim();

  return (
    <div>
      <div className="pageTitle">
        <h1>Регистрация</h1>
        <div className="sub">Создайте аккаунт клиента, чтобы оформлять заказы</div>
      </div>

      <div className="card">
        <form onSubmit={submit}>
          <div className="row">
            <label>
              Логин
              <input value={form.login} onChange={(e) => set("login", e.target.value)} autoComplete="username" />
            </label>
            <label>
              Email
              <input value={form.email} onChange={(e) => set("email", e.target.value)} autoComplete="email" />
            </label>
            <label>
              Телефон (опционально)
              <input value={form.phone ?? ""} onChange={(e) => set("phone", e.target.value)} autoComplete="tel" />
            </label>
          </div>

          <div className="row" style={{ marginTop: 10 }}>
            <label>
              Имя
              <input value={form.first_name} onChange={(e) => set("first_name", e.target.value)} />
            </label>
            <label>
              Фамилия
              <input value={form.last_name} onChange={(e) => set("last_name", e.target.value)} />
            </label>
          </div>

          <div className="row" style={{ marginTop: 10 }}>
            <label>
              Пароль
              <input type="password" value={form.password} onChange={(e) => set("password", e.target.value)} autoComplete="new-password" />
            </label>
            <label>
              Повтор пароля
              <input type="password" value={password2} onChange={(e) => setPassword2(e.target.value)} autoComplete="new-password" />
            </label>
            <button type="submit" disabled={!canSubmit || isSubmitting}>Создать аккаунт</button>
          </div>
        </form>

        {err && <div className="error">{err}</div>}

        <div className="hint" style={{ marginTop: 10 }}>
          Уже есть аккаунт? <Link to="/login">Войти</Link> • Вход персонала: <Link to="/admin/login">/admin/login</Link>
        </div>
      </div>
    </div>
  );
}
