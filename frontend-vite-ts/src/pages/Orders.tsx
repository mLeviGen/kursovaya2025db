import { useEffect, useState } from "react";
import { api } from "../app/api";

type OrderRow = Record<string, any>;

export default function Orders() {
  const [orders, setOrders] = useState<OrderRow[]>([]);
  const [err, setErr] = useState<string | null>(null);

  const [customerId, setCustomerId] = useState(1);
  const [productId, setProductId] = useState(1);
  const [qty, setQty] = useState(1);

  const load = async () => {
    const res = await api.get("/orders?limit=50&offset=0");
    setOrders(res.data ?? []);
  };

  useEffect(() => {
    (async () => {
      try {
        setErr(null);
        await load();
      } catch (e: any) {
        setErr(e?.message ?? String(e));
      }
    })();
  }, []);

  const createOrder = async () => {
    try {
      setErr(null);
      await api.post("/orders", {
        customer_id: customerId,
        status: "NEW",
        comments: "from frontend",
        items: [{ product_id: productId, qty }],
      });
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  const cancelOrder = async (orderId: number) => {
    try {
      setErr(null);
      await api.post(`/orders/${orderId}/cancel`, null, { params: { reason: "frontend cancel" } });
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  return (
    <div className="container">
      <h2>Orders</h2>
      {err && <div className="error">{err}</div>}

      <div className="card">
        <h3>Create order (minimal)</h3>
        <div className="row">
          <label>
            customer_id
            <input type="number" value={customerId} onChange={(e) => setCustomerId(Number(e.target.value))} />
          </label>
          <label>
            product_id
            <input type="number" value={productId} onChange={(e) => setProductId(Number(e.target.value))} />
          </label>
          <label>
            qty
            <input type="number" value={qty} min={0.1} step={0.1} onChange={(e) => setQty(Number(e.target.value))} />
          </label>
          <button onClick={createOrder}>Create</button>
        </div>
      </div>

      <div className="card">
        <h3>Orders list</h3>
        <pre className="pre">{JSON.stringify(orders, null, 2)}</pre>
        <div className="row">
          <input id="cancelId" type="number" placeholder="order_id" />
          <button
            onClick={() => {
              const el = document.getElementById("cancelId") as HTMLInputElement | null;
              const id = el?.value ? Number(el.value) : NaN;
              if (!Number.isFinite(id)) return;
              cancelOrder(id);
            }}
          >
            Cancel by id
          </button>
          <button onClick={load}>Refresh</button>
        </div>
      </div>
    </div>
  );
}
