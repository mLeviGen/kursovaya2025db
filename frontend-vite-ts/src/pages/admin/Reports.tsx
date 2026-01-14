import { useEffect, useState } from "react";
import { api } from "../../app/api";

type AnyRow = Record<string, any>;

export default function Reports() {
  const [ps, setPs] = useState<AnyRow[]>([]);
  const [clients, setClients] = useState<AnyRow[]>([]);
  const [prod, setProd] = useState<AnyRow[]>([]);
  const [q, setQ] = useState<AnyRow[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const load = async () => {
    const [r1, r2, r3, r4] = await Promise.all([
      api.get("/admin/reports/product-sales"),
      api.get("/admin/reports/clients"),
      api.get("/admin/reports/production"),
      api.get("/admin/reports/quality"),
    ]);
    setPs(r1.data ?? []);
    setClients(r2.data ?? []);
    setProd(r3.data ?? []);
    setQ(r4.data ?? []);
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

  return (
    <div>
      <div className="pageTitle">
        <h1>Отчёты</h1>
        <div className="sub">Полные выборки (вью в БД)</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <button className="secondary" onClick={() => void load()} disabled={isLoading}>Обновить все</button>
      </div>

      <Block title="Продажи по продуктам" rows={ps} />
      <Block title="Статистика клиентов" rows={clients} />
      <Block title="Статистика производства" rows={prod} />
      <Block title="Журнал качества" rows={q} />
    </div>
  );
}

function Block({ title, rows }: { title: string; rows: AnyRow[] }) {
  const cols = rows.length ? Object.keys(rows[0]) : [];

  return (
    <div className="card">
      <h3>{title}</h3>
      {rows.length === 0 ? (
        <div className="hint">Нет данных</div>
      ) : (
        <div style={{ overflowX: "auto" }}>
          <table>
            <thead>
              <tr>
                {cols.map((c) => <th key={c}>{c}</th>)}
              </tr>
            </thead>
            <tbody>
              {rows.map((r, idx) => (
                <tr key={idx}>
                  {cols.map((c) => (
                    <td key={c}>{String(r[c] ?? "")}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
