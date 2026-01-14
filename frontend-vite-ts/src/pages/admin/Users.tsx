import { useEffect, useState } from "react";
import { api } from "../../app/api";

type UserRow = {
  id: number;
  login: string;
  email: string;
  phone: string | null;
  first_name: string;
  last_name: string;
  role: string;
};

const ROLES = ["client", "technologist", "inspector", "manager", "admin"];

export default function Users() {
  const [rows, setRows] = useState<UserRow[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Create form
  const [login, setLogin] = useState("");
  const [password, setPassword] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [role, setRole] = useState("client");

  const load = async () => {
    const res = await api.get("/admin/users");
    setRows((res.data ?? []) as UserRow[]);
  };

  useEffect(() => {
    (async () => {
      try {
        setIsLoading(true);
        setErr(null);
        await load();
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      } finally {
        setIsLoading(false);
      }
    })();
  }, []);

  const create = async () => {
    try {
      setErr(null);
      await api.post("/admin/users", {
        login,
        password,
        email,
        phone: phone.trim() ? phone.trim() : null,
        first_name: firstName,
        last_name: lastName,
        role,
      });
      setLogin("");
      setPassword("");
      setEmail("");
      setPhone("");
      setFirstName("");
      setLastName("");
      setRole("client");
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  return (
    <div>
      <div className="pageTitle">
        <h1>Пользователи</h1>
        <div className="sub">Создание аккаунтов и список</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <h3>Создать пользователя</h3>
        <div className="row">
          <label>
            Логин
            <input value={login} onChange={(e) => setLogin(e.target.value)} />
          </label>
          <label>
            Пароль
            <input value={password} onChange={(e) => setPassword(e.target.value)} type="password" />
          </label>
          <label>
            Роль
            <select value={role} onChange={(e) => setRole(e.target.value)}>
              {ROLES.map((r) => (
                <option key={r} value={r}>{r}</option>
              ))}
            </select>
          </label>
        </div>

        <div className="row" style={{ marginTop: 8 }}>
          <label>
            Email
            <input value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          <label>
            Телефон
            <input value={phone} onChange={(e) => setPhone(e.target.value)} />
          </label>
          <label>
            Имя
            <input value={firstName} onChange={(e) => setFirstName(e.target.value)} />
          </label>
          <label>
            Фамилия
            <input value={lastName} onChange={(e) => setLastName(e.target.value)} />
          </label>
        </div>

        <div className="row" style={{ marginTop: 10 }}>
          <button onClick={() => void create()} disabled={!login.trim() || !password || !email || !firstName || !lastName}>
            Создать
          </button>
          <button className="secondary" onClick={() => void load()} disabled={isLoading}>Обновить список</button>
        </div>
      </div>

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Логин</th>
              <th>Имя</th>
              <th>Роль</th>
              <th>Email</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((u) => (
              <tr key={u.id}>
                <td>{u.id}</td>
                <td><b>{u.login}</b></td>
                <td>{u.first_name} {u.last_name}</td>
                <td><span className="pill">{u.role}</span></td>
                <td>{u.email}</td>
              </tr>
            ))}
            {!isLoading && rows.length === 0 && <tr><td colSpan={5}>Нет данных</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
