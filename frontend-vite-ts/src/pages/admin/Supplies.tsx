import { useEffect, useState } from "react";
import { api } from "../../app/api";
import { useAuth } from "../../auth/AuthContext";

type Supply = {
  supply_id?: number;
  supplier_name: string;
  raw_material_name: string;
  unit: string;
  cost_numeric: number;
  lead_time_days: number;
};

export default function Supplies() {
  const { me } = useAuth();
  const role = me?.role;
  const canUpsert = role === "technologist" || role === "admin";
  const canUpdateTerms = role === "technologist" || role === "manager" || role === "admin";

  const [rows, setRows] = useState<Supply[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Upsert form
  const [supplierName, setSupplierName] = useState<string>("");
  const [rawName, setRawName] = useState<string>("");
  const [unit, setUnit] = useState<string>("kg");
  const [cost, setCost] = useState<number>(0);
  const [leadTime, setLeadTime] = useState<number>(1);

  const load = async () => {
    const res = await api.get("/worker/supplies");
    setRows((res.data ?? []) as Supply[]);
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

  const upsert = async () => {
    try {
      setErr(null);
      await api.post("/worker/supplies", {
        supplier_name: supplierName,
        raw_material_name: rawName,
        unit,
        cost_numeric: cost,
        lead_time_days: leadTime,
      });
      setSupplierName("");
      setRawName("");
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  const patchTerms = async (supplyId: number | undefined, cost_numeric: number, lead_time_days: number) => {
    if (!supplyId) {
      setErr("У этой строки нет supply_id — обновление условий невозможно");
      return;
    }
    try {
      setErr(null);
      await api.patch(`/worker/supplies/${supplyId}`, { cost_numeric, lead_time_days });
      await load();
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  return (
    <div>
      <div className="pageTitle">
        <h1>Поставки</h1>
        <div className="sub">Условия закупки сырья</div>
      </div>

      {err && <div className="error">{err}</div>}

      {canUpsert && (
        <div className="card">
          <h3>Добавить / обновить условие</h3>
          <div className="row">
            <label>
              Поставщик
              <input value={supplierName} onChange={(e) => setSupplierName(e.target.value)} />
            </label>
            <label>
              Сырьё
              <input value={rawName} onChange={(e) => setRawName(e.target.value)} />
            </label>
            <label>
              Ед.
              <input value={unit} onChange={(e) => setUnit(e.target.value)} />
            </label>
            <label>
              Цена
              <input type="number" step={0.01} value={cost} onChange={(e) => setCost(Number(e.target.value))} />
            </label>
            <label>
              Срок (дн)
              <input type="number" step={1} value={leadTime} onChange={(e) => setLeadTime(Number(e.target.value))} />
            </label>
            <button onClick={() => void upsert()} disabled={!supplierName.trim() || !rawName.trim()}>
              Сохранить
            </button>
          </div>
          <div className="hint" style={{ marginTop: 8 }}>
            Важно: PATCH /worker/supplies/{`{id}`} доступен менеджеру (и выше), но POST /worker/supplies — только технологу/админу.
          </div>
        </div>
      )}

      <div className="card">
        <div className="row">
          <button className="secondary" onClick={() => void load()} disabled={isLoading}>Обновить</button>
        </div>

        <table style={{ marginTop: 10 }}>
          <thead>
            <tr>
              <th>Поставщик</th>
              <th>Сырьё</th>
              <th>Ед.</th>
              <th>Цена</th>
              <th>Срок (дн)</th>
              {canUpdateTerms && <th>Действия</th>}
            </tr>
          </thead>
          <tbody>
            {rows.map((r, idx) => (
              <SupplyRow
                key={`${r.supplier_name}-${r.raw_material_name}-${idx}`}
                row={r}
                canUpdate={canUpdateTerms}
                onSave={patchTerms}
              />
            ))}
            {!isLoading && rows.length === 0 && <tr><td colSpan={canUpdateTerms ? 6 : 5}>Нет данных</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function SupplyRow({
  row,
  canUpdate,
  onSave,
}: {
  row: Supply;
  canUpdate: boolean;
  onSave: (supplyId: number | undefined, cost: number, lead: number) => Promise<void>;
}) {
  const [cost, setCost] = useState<number>(Number(row.cost_numeric ?? 0));
  const [lead, setLead] = useState<number>(Number(row.lead_time_days ?? 0));

  return (
    <tr>
      <td>{row.supplier_name}</td>
      <td>{row.raw_material_name}</td>
      <td>{row.unit}</td>
      <td>
        {canUpdate ? (
          <input type="number" step={0.01} value={cost} onChange={(e) => setCost(Number(e.target.value))} />
        ) : (
          Number(row.cost_numeric ?? 0).toFixed(2)
        )}
      </td>
      <td>
        {canUpdate ? (
          <input type="number" step={1} value={lead} onChange={(e) => setLead(Number(e.target.value))} />
        ) : (
          row.lead_time_days
        )}
      </td>
      {canUpdate && (
        <td>
          <button className="secondary" onClick={() => void onSave(row.supply_id, cost, lead)}>
            Применить
          </button>
        </td>
      )}
    </tr>
  );
}
