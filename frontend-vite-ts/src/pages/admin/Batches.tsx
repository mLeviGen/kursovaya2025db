import { useEffect, useMemo, useState } from "react";
import { api } from "../../app/api";
import { useAuth } from "../../auth/AuthContext";

type Batch = {
  id: number;
  code: string;
  product_name: string;
  status: string;
  prod_date?: string;
  best_before?: string;
  qty_kg: number;
  created_at?: string;
  changed_at?: string;
};

type Product = { id: number; name: string };

const STATUSES = ["aging", "testing", "released", "rejected"];

export default function Batches() {
  const { me } = useAuth();
  const role = me?.role;
  const canCreate = role === "technologist" || role === "manager" || role === "admin";
  const canSetStatus = role === "manager" || role === "admin";

  const [rows, setRows] = useState<Batch[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const [productName, setProductName] = useState<string>("");
  const [batchCode, setBatchCode] = useState<string>("");
  const [qtyKg, setQtyKg] = useState<number>(1);

  const load = async () => {
    const res = await api.get("/worker/batches");
    setRows((res.data ?? []) as Batch[]);
  };

  useEffect(() => {
    (async () => {
      try {
        setIsLoading(true);
        setErr(null);
        const [b, p] = await Promise.all([load(), api.get("/public/products")]);
        const list = (p.data ?? []) as Array<{ id: number; name: string }>;
        setProducts(list);
        if (!productName && list.length) setProductName(list[0].name);
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      } finally {
        setIsLoading(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const create = async () => {
    try {
      setErr(null);
      await api.post("/worker/batches", {
        product_name: productName,
        batch_code: batchCode,
        qty_kg: qtyKg,
      });
      setBatchCode("");
      setQtyKg(1);
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  const setStatus = async (code: string, status: string) => {
    try {
      setErr(null);
      await api.post("/worker/batches/status", { batch_code: code, status });
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  const sorted = useMemo(() => {
    return rows.slice().sort((a, b) => String(b.prod_date ?? "").localeCompare(String(a.prod_date ?? "")));
  }, [rows]);

  return (
    <div>
      <div className="pageTitle">
        <h1>Партии</h1>
        <div className="sub">Производство и статусы</div>
      </div>

      {err && <div className="error">{err}</div>}

      {canCreate && (
        <div className="card">
          <h3>Создать партию</h3>
          <div className="row">
            <label>
              Продукт
              <select value={productName} onChange={(e) => setProductName(e.target.value)}>
                {products.map((p) => (
                  <option key={p.id} value={p.name}>{p.name}</option>
                ))}
              </select>
            </label>
            <label>
              Код партии
              <input value={batchCode} onChange={(e) => setBatchCode(e.target.value)} placeholder="BATCH-2026-001" />
            </label>
            <label>
              Кол-во (кг)
              <input type="number" min={0.1} step={0.1} value={qtyKg} onChange={(e) => setQtyKg(Number(e.target.value))} />
            </label>
            <button onClick={() => void create()} disabled={isLoading || !batchCode.trim()}>Создать</button>
          </div>
          <div className="hint" style={{ marginTop: 8 }}>
            Примечание: API сейчас принимает product_name (не id). В форме это выбирается из списка, поэтому опечаток не будет.
          </div>
        </div>
      )}

      <div className="card">
        <table>
          <thead>
            <tr>
              <th>Код</th>
              <th>Продукт</th>
              <th>Статус</th>
              <th>Дата</th>
              <th>Кг</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((b) => (
              <tr key={b.id}>
                <td><b>{b.code}</b></td>
                <td>{b.product_name}</td>
                <td>
                  {canSetStatus ? (
                    <select value={b.status} onChange={(e) => void setStatus(b.code, e.target.value)}>
                      {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
                    </select>
                  ) : (
                    <span className="pill">{b.status}</span>
                  )}
                </td>
                <td>{String(b.prod_date ?? "").slice(0, 10)}</td>
                <td>{Number(b.qty_kg ?? 0).toFixed(2)}</td>
              </tr>
            ))}
            {!isLoading && sorted.length === 0 && <tr><td colSpan={5}>Нет данных</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
