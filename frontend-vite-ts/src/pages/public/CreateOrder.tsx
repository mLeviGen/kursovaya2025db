import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../../app/api";

type Product = {
  id: number;
  name: string;
  base_price?: number;
  cheese_type?: string;
  aging_days?: number;
  is_active?: boolean;
};

export default function CreateOrder() {
  const navigate = useNavigate();
  const [products, setProducts] = useState<Product[]>([]);
  const [qty, setQty] = useState<Record<number, number>>({});
  const [comments, setComments] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        setIsLoading(true);
        setErr(null);
        const res = await api.get("/public/products");
        const list = (res.data ?? []) as Product[];
        setProducts(list.filter((p) => p.is_active));
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      } finally {
        setIsLoading(false);
      }
    })();
  }, []);

  const selected = useMemo(() => {
    const items = Object.entries(qty)
      .map(([k, v]) => ({ product_id: Number(k), qty: Number(v) }))
      .filter((x) => Number.isFinite(x.product_id) && x.qty > 0);
    return items;
  }, [qty]);

  const estTotal = useMemo(() => {
    let sum = 0;
    for (const it of selected) {
      const p = products.find((x) => x.id === it.product_id);
      sum += (Number(p?.base_price ?? 0) * it.qty);
    }
    return sum;
  }, [selected, products]);

  const submit = async () => {
    try {
      setErr(null);
      if (selected.length === 0) {
        setErr("Выберите хотя бы один товар (кол-во > 0)");
        return;
      }
      setIsSubmitting(true);
      await api.post("/client/orders", {
        items: selected,
        comments: comments.trim() ? comments.trim() : null,
      });
      navigate("/orders", { replace: true });
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div>
      <div className="pageTitle">
        <h1>Новый заказ</h1>
        <div className="sub">Выберите товары и количество</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <label>
          Комментарий
          <textarea value={comments} onChange={(e) => setComments(e.target.value)} rows={3} placeholder="Например: доставка после 18:00" />
        </label>
        <div className="hint" style={{ marginTop: 8 }}>
          Оценка суммы (по базовым ценам): <b>{estTotal.toFixed(2)}</b>
        </div>
        <div className="row" style={{ marginTop: 10 }}>
          <button onClick={() => void submit()} disabled={isSubmitting || isLoading}>Отправить заказ</button>
          <button className="secondary" onClick={() => navigate("/orders")} disabled={isSubmitting}>Назад</button>
        </div>
      </div>

      <div className="card">
        {isLoading ? (
          <div>Загрузка каталога…</div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Товар</th>
                <th>Тип</th>
                <th>Цена</th>
                <th style={{ width: 160 }}>Кол-во</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.id}>
                  <td><b>{p.name}</b> <span className="hint">(id: {p.id})</span></td>
                  <td>{p.cheese_type ?? "—"}{typeof p.aging_days === "number" ? `, ${p.aging_days}д` : ""}</td>
                  <td>{typeof p.base_price === "number" ? p.base_price.toFixed(2) : "—"}</td>
                  <td>
                    <input
                      type="number"
                      min={0}
                      step={1}
                      value={qty[p.id] ?? 0}
                      onChange={(e) => {
                        const v = Number(e.target.value);
                        setQty((prev) => ({ ...prev, [p.id]: Number.isFinite(v) ? v : 0 }));
                      }}
                    />
                  </td>
                </tr>
              ))}
              {products.length === 0 && (
                <tr><td colSpan={4}>Нет доступных товаров</td></tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
