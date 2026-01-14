import { useEffect, useState } from "react";
import { api } from "../../app/api";
import { useAuth } from "../../auth/AuthContext";

type AnyRow = Record<string, any>;

export default function AdminDashboard() {
  const { me } = useAuth();
  const isAdmin = me?.role === "admin";

  const [topProducts, setTopProducts] = useState<AnyRow[]>([]);
  const [topClients, setTopClients] = useState<AnyRow[]>([]);
  const [production, setProduction] = useState<AnyRow[]>([]);
  const [quality, setQuality] = useState<AnyRow[]>([]);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!isAdmin) return;
    (async () => {
      try {
        setErr(null);
        const [ps, cs, prod, ql] = await Promise.all([
          api.get("/admin/reports/product-sales"),
          api.get("/admin/reports/clients"),
          api.get("/admin/reports/production"),
          api.get("/admin/reports/quality"),
        ]);
        setTopProducts((ps.data ?? []).slice(0, 10));
        setTopClients((cs.data ?? []).slice(0, 10));
        setProduction((prod.data ?? []).slice(0, 10));
        setQuality((ql.data ?? []).slice(0, 10));
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      }
    })();
  }, [isAdmin]);

  if (!isAdmin) {
    return (
      <div>
        <div className="pageTitle">
          <h1>Панель</h1>
          <div className="sub">Разделы доступны в меню сверху</div>
        </div>
        <div className="card">
          Ваша роль: <span className="pill">{me?.role ?? "?"}</span>. Аналитика доступна только администратору.
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="pageTitle">
        <h1>Дашборд</h1>
        <div className="sub">Аналитика (4 блока)</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="grid2">
        <div className="card">
          <h3>Топ продуктов</h3>
          <table>
            <thead>
              <tr>
                <th>Продукт</th>
                <th>Выручка</th>
                <th>Шт.</th>
              </tr>
            </thead>
            <tbody>
              {topProducts.map((r, idx) => (
                <tr key={idx}>
                  <td>{r.product_name}</td>
                  <td>{Number(r.revenue ?? 0).toFixed(2)}</td>
                  <td>{r.units_sold ?? 0}</td>
                </tr>
              ))}
              {topProducts.length === 0 && <tr><td colSpan={3}>Нет данных</td></tr>}
            </tbody>
          </table>
        </div>

        <div className="card">
          <h3>Топ покупателей</h3>
          <table>
            <thead>
              <tr>
                <th>Клиент</th>
                <th>Заказы</th>
                <th>Сумма</th>
              </tr>
            </thead>
            <tbody>
              {topClients
                .slice()
                .sort((a, b) => Number(b.total_spent_money ?? 0) - Number(a.total_spent_money ?? 0))
                .slice(0, 10)
                .map((r, idx) => (
                  <tr key={idx}>
                    <td>{r.login}</td>
                    <td>{r.total_orders}</td>
                    <td>{Number(r.total_spent_money ?? 0).toFixed(2)}</td>
                  </tr>
                ))}
              {topClients.length === 0 && <tr><td colSpan={3}>Нет данных</td></tr>}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid2">
        <div className="card">
          <h3>Производство</h3>
          <table>
            <thead>
              <tr>
                <th>Продукт</th>
                <th>Кг</th>
                <th>Брак %</th>
              </tr>
            </thead>
            <tbody>
              {production
                .slice()
                .sort((a, b) => Number(b.total_kg_produced ?? 0) - Number(a.total_kg_produced ?? 0))
                .slice(0, 10)
                .map((r, idx) => (
                  <tr key={idx}>
                    <td>{r.product_name}</td>
                    <td>{Number(r.total_kg_produced ?? 0).toFixed(2)}</td>
                    <td>{Number(r.rejection_rate_pct ?? 0).toFixed(2)}</td>
                  </tr>
                ))}
              {production.length === 0 && <tr><td colSpan={3}>Нет данных</td></tr>}
            </tbody>
          </table>
        </div>

        <div className="card">
          <h3>Качество (последние тесты)</h3>
          <table>
            <thead>
              <tr>
                <th>Дата</th>
                <th>Партия</th>
                <th>Результат</th>
              </tr>
            </thead>
            <tbody>
              {quality
                .slice()
                .sort((a, b) => String(b.test_date ?? "").localeCompare(String(a.test_date ?? "")))
                .slice(0, 10)
                .map((r, idx) => (
                  <tr key={idx}>
                    <td>{String(r.test_date ?? "").slice(0, 10)}</td>
                    <td>{r.batch_code}</td>
                    <td><span className="pill">{r.test_result}</span></td>
                  </tr>
                ))}
              {quality.length === 0 && <tr><td colSpan={3}>Нет данных</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
