import { useEffect, useState } from "react";
import { api } from "../../app/api";

type Order = {
  id?: number;
  order_id?: number;
  client_login: string;
  status: string;
  total_price: number;
  comments?: string | null;
  created_at?: string | null;
  items: Array<{ product_id?: number; product: string; qty: number; unit_price: number }>;
};

const STATUSES = ["new", "paid", "shipped", "completed", "cancelled"];

export default function OrdersAdmin() {
  const [rows, setRows] = useState<Order[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const load = async () => {
    const res = await api.get("/worker/orders");
    setRows((res.data ?? []) as Order[]);
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

  const setStatus = async (orderId: number, status: string) => {
    try {
      setErr(null);
      await api.post(`/worker/orders/${orderId}/status`, null, { params: { status } });
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  return (
    <div>
      <div className="pageTitle">
        <h1>Заказы</h1>
        <div className="sub">Управление статусами</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <div className="row">
          <button className="secondary" onClick={() => void load()} disabled={isLoading}>Обновить</button>
        </div>
      </div>

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Клиент</th>
              <th>Статус</th>
              <th>Сумма</th>
              <th>Позиции</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((o, idx) => {
              const orderNo = o.id ?? o.order_id;
              return (
              <tr key={orderNo ?? idx}>
                <td>{orderNo ?? "—"}</td>
                <td>{o.client_login}</td>
                <td>
                  <select
                    value={o.status}
                    disabled={!orderNo}
                    onChange={(e) => orderNo && void setStatus(orderNo, e.target.value)}
                  >
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </td>
                <td>{Number(o.total_price ?? 0).toFixed(2)}</td>
                <td>
                  {(o.items ?? []).map((it, idx) => (
                    <div key={idx} className="hint">
                      {it.product} — {it.qty} × {Number(it.unit_price ?? 0).toFixed(2)}
                    </div>
                  ))}
                </td>
                <td>
                  <button className="secondary" disabled={!orderNo} onClick={() => orderNo && void setStatus(orderNo, "cancelled")}>Отменить</button>
                </td>
              </tr>
              );
            })}
            {!isLoading && rows.length === 0 && (
              <tr><td colSpan={6}>Нет заказов</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
