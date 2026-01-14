import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../app/api";
import { useAuth } from "../../auth/AuthContext";

type Product = {
  id: number;
  name: string;
  cheese_type?: string;
  aging_days?: number;
  base_price?: number;
  is_active?: boolean;
  recipe_name?: string | null;
};

export default function Catalog() {
  const { me } = useAuth();
  const [rows, setRows] = useState<Product[]>([]);
  const [q, setQ] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        setIsLoading(true);
        setErr(null);
        const res = await api.get("/public/products");
        setRows((res.data ?? []) as Product[]);
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      } finally {
        setIsLoading(false);
      }
    })();
  }, []);

  const filtered = useMemo(() => {
    const qq = q.trim().toLowerCase();
    if (!qq) return rows;
    return rows.filter((r) =>
      [r.name, r.cheese_type, r.recipe_name]
        .filter(Boolean)
        .join(" ")
        .toLowerCase()
        .includes(qq)
    );
  }, [rows, q]);

  return (
    <div>
      <div className="pageTitle">
        <h1>Каталог</h1>
        <div className="sub">Описание сыра, цена и прочее</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <div className="row">
          <label style={{ minWidth: 260 }}>
            Поиск
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Название, тип, рецепт…" />
          </label>

          {me?.role === "client" && (
            <Link to="/orders/new">
              <button>Оформить заказ</button>
            </Link>
          )}

          {!me && (
            <Link to="/login">
              <button>Войти, чтобы заказать</button>
            </Link>
          )}

          {me && me.role !== "client" && me.role !== "guest" && (
            <Link to="/admin">
              <button className="secondary">Перейти в панель</button>
            </Link>
          )}
        </div>
        <div className="hint" style={{ marginTop: 8 }}>
          {isLoading ? "Загрузка…" : `Показано: ${filtered.length}`}
        </div>
      </div>

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Название</th>
              <th>Тип</th>
              <th>Выдержка (дни)</th>
              <th>Цена</th>
              <th>Рецепт</th>
              <th>Статус</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((p) => (
              <tr key={p.id}>
                <td><b>{p.name}</b></td>
                <td>{p.cheese_type ?? "—"}</td>
                <td>{typeof p.aging_days === "number" ? p.aging_days : "—"}</td>
                <td>{typeof p.base_price === "number" ? p.base_price.toFixed(2) : "—"}</td>
                <td>{p.recipe_name ?? "—"}</td>
                <td>{p.is_active ? <span className="pill">активен</span> : <span className="pill">скрыт</span>}</td>
              </tr>
            ))}
            {!isLoading && filtered.length === 0 && (
              <tr><td colSpan={6}>Ничего не найдено</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
