import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";

export default function Login() {
  const nav = useNavigate();
  const { login, setToken } = useAuth();

  const [mode, setMode] = useState<"login" | "paste">("paste");
  const [username, setUsername] = useState("admin");
  const [password, setPassword] = useState("");
  const [token, setTokenText] = useState("");
  const [err, setErr] = useState<string | null>(null);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null);

    try {
      if (mode === "paste") {
        if (!token.trim()) throw new Error("Paste JWT token");
        setToken(token.trim());
      } else {
        await login(username, password);
      }
      nav("/");
    } catch (e: any) {
      setErr(e?.message ?? String(e));
    }
  };

  return (
    <div className="container">
      <h2>Login</h2>

      <div className="tabs">
        <button className={mode === "paste" ? "active" : ""} onClick={() => setMode("paste")}>
          Paste JWT
        </button>
        <button className={mode === "login" ? "active" : ""} onClick={() => setMode("login")}>
          Username/Password
        </button>
      </div>

      <form onSubmit={onSubmit} className="card">
        {mode === "login" ? (
          <>
            <label>
              Username
              <input value={username} onChange={(e) => setUsername(e.target.value)} />
            </label>
            <label>
              Password
              <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
            </label>
            <p className="hint">
              Требует backend endpoint <code>/api/auth/login</code>. Пока можно использовать вкладку “Paste JWT”.
            </p>
          </>
        ) : (
          <>
            <label>
              JWT token
              <textarea rows={4} value={token} onChange={(e) => setTokenText(e.target.value)} />
            </label>
            <p className="hint">Пока backend не делает реальную аутентификацию — вставь любой токен (хоть “dev”).</p>
          </>
        )}

        {err && <div className="error">{err}</div>}
        <button type="submit">Enter</button>
      </form>
    </div>
  );
}
