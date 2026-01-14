import { useEffect, useState } from "react";
import { useAuth } from "../../auth/AuthContext";

export default function Profile() {
  const { me, refreshMe, logout } = useAuth();
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    void refreshMe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div>
      <div className="pageTitle">
        <h1>Профиль</h1>
        <div className="sub">Информация об аккаунте</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        {!me ? (
          <div>Нет данных профиля</div>
        ) : (
          <table>
            <tbody>
              <tr><th>Логин</th><td>{me.login}</td></tr>
              <tr><th>Имя</th><td>{me.first_name} {me.last_name}</td></tr>
              <tr><th>Роль</th><td><span className="pill">{me.role}</span></td></tr>
              <tr><th>ID</th><td>{me.id}</td></tr>
            </tbody>
          </table>
        )}
        <div className="row" style={{ marginTop: 12 }}>
          <button className="secondary" onClick={() => void refreshMe().catch((e) => setErr(String(e)))}>Обновить</button>
          <button onClick={() => void logout()}>Выйти</button>
        </div>
      </div>
    </div>
  );
}
