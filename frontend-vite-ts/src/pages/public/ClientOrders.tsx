import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../../app/api";

type Order = {
  id?: number;
  order_id?: number;
  status: string;
  total_price: number;
  comments?: string | null;
  created_at?: string | null;
  changed_at?: string | null;
  items: Array<{ product_id?: number; product: string; qty: number; unit_price: number }>;
};

export default function ClientOrders() {
  const [rows, setRows] = useState<Order[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const load = async () => {
    const res = await api.get("/client/orders");
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

  const cancel = async (orderId: number) => {
    try {
      setErr(null);
      await api.post(`/client/orders/${orderId}/cancel`);
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  return (
    <div>
      <div className="pageTitle">
        <h1>Мои заказы</h1>
        <div className="sub">История и статусы</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <div className="row">
          <Link to="/orders/new"><button>Новый заказ</button></Link>
          <button className="secondary" onClick={() => void load()} disabled={isLoading}>Обновить</button>
        </div>
      </div>

      {rows.map((o, idx) => {
        const orderNo = o.id ?? o.order_id;
        return (
        <div key={orderNo ?? idx} className="card">
          <div style={{ display: "flex", justifyContent: "space-between", gap: 12, flexWrap: "wrap" }}>
            <div>
              <div><b>Заказ #{orderNo ?? "?"}</b> <span className="pill">{o.status}</span></div>
              <div className="hint">Сумма: {Number(o.total_price ?? 0).toFixed(2)}</div>
              {o.comments ? <div className="hint">Комментарий: {o.comments}</div> : null}
            </div>
            <div>
              <button
                className="secondary"
                disabled={!orderNo}
                onClick={() => orderNo && void cancel(orderNo)}
              >
                Отменить
              </button>
            </div>
          </div>

          <div style={{ marginTop: 10 }}>
            <table>
              <thead>
                <tr>
                  <th>Товар</th>
                  <th>Кол-во</th>
                  <th>Цена</th>
                  <th>Итого</th>
                </tr>
              </thead>
              <tbody>
                {(o.items ?? []).map((it, idx) => (
                  <tr key={idx}>
                    <td>{it.product}</td>
                    <td>{it.qty}</td>
                    <td>{Number(it.unit_price ?? 0).toFixed(2)}</td>
                    <td>{(Number(it.unit_price ?? 0) * Number(it.qty ?? 0)).toFixed(2)}</td>
                  </tr>
                ))}
                {(!o.items || o.items.length === 0) && (
                  <tr><td colSpan={4}>Нет позиций</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
        );
      })}

      {!isLoading && rows.length === 0 && (
        <div className="card">Пока нет заказов. <Link to="/orders/new">Создать первый</Link></div>
      )}
    </div>
  );
}
