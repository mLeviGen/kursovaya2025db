import { useEffect, useMemo, useState } from "react";
import { api } from "../../app/api";
import { useAuth } from "../../auth/AuthContext";

type Batch = { id: number; code: string; product_name: string; status: string };
type QualityTest = {
  id?: number;
  test_date?: string;
  result: string;
  ph?: number | null;
  moisture_pct?: number | null;
  comments?: string | null;
  inspector_name?: string | null;
};

export default function Quality() {
  const { me } = useAuth();
  const role = me?.role;
  const canRecord = role === "inspector" || role === "admin";

  const [batches, setBatches] = useState<Batch[]>([]);
  const [selectedCode, setSelectedCode] = useState<string>("");
  const [tests, setTests] = useState<any[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  // Form
  const [result, setResult] = useState<string>("pass");
  const [ph, setPh] = useState<number | "">("");
  const [moisture, setMoisture] = useState<number | "">("");
  const [comments, setComments] = useState<string>("");

  const loadBatches = async () => {
    const res = await api.get("/worker/batches");
    const list = (res.data ?? []) as Batch[];
    setBatches(list);
    if (!selectedCode && list.length) setSelectedCode(list[0].code);
  };

  const loadTests = async (code: string) => {
    if (!code) return;
    const res = await api.get(`/worker/quality-tests/${encodeURIComponent(code)}`);
    setTests((res.data ?? []) as any[]);
  };

  useEffect(() => {
    (async () => {
      try {
        setIsLoading(true);
        setErr(null);
        await loadBatches();
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      } finally {
        setIsLoading(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!selectedCode) return;
    (async () => {
      try {
        setErr(null);
        await loadTests(selectedCode);
      } catch (e: any) {
        setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
      }
    })();
  }, [selectedCode]);

  const submit = async () => {
    try {
      setErr(null);
      if (!selectedCode) {
        setErr("Выберите партию");
        return;
      }
      await api.post("/worker/quality-tests", {
        batch_code: selectedCode,
        result,
        ph: ph === "" ? null : ph,
        moisture_pct: moisture === "" ? null : moisture,
        comments: comments.trim() ? comments.trim() : null,
      });
      setComments("");
      await loadTests(selectedCode);
    } catch (e: any) {
      setErr(e?.response?.data?.detail ?? e?.message ?? String(e));
    }
  };

  const selectedBatch = useMemo(() => batches.find((b) => b.code === selectedCode), [batches, selectedCode]);

  return (
    <div>
      <div className="pageTitle">
        <h1>Качество</h1>
        <div className="sub">Тесты по партиям</div>
      </div>

      {err && <div className="error">{err}</div>}

      <div className="card">
        <div className="row">
          <label>
            Партия
            <select value={selectedCode} onChange={(e) => setSelectedCode(e.target.value)}>
              {batches.map((b) => (
                <option key={b.code} value={b.code}>
                  {b.code} — {b.product_name}
                </option>
              ))}
            </select>
          </label>
          <button className="secondary" onClick={() => void loadBatches()} disabled={isLoading}>Обновить партии</button>
          <button className="secondary" onClick={() => void loadTests(selectedCode)} disabled={!selectedCode}>Обновить тесты</button>
        </div>

        {selectedBatch && (
          <div className="hint" style={{ marginTop: 8 }}>
            Статус партии: <span className="pill">{selectedBatch.status}</span>
          </div>
        )}
      </div>

      {canRecord && (
        <div className="card">
          <h3>Записать тест</h3>
          <div className="row">
            <label>
              Результат
              <select value={result} onChange={(e) => setResult(e.target.value)}>
                <option value="pass">pass</option>
                <option value="fail">fail</option>
              </select>
            </label>
            <label>
              pH
              <input type="number" step={0.01} value={ph} onChange={(e) => setPh(e.target.value === "" ? "" : Number(e.target.value))} />
            </label>
            <label>
              Влажность (%)
              <input type="number" step={0.01} value={moisture} onChange={(e) => setMoisture(e.target.value === "" ? "" : Number(e.target.value))} />
            </label>
          </div>
          <label style={{ marginTop: 10 }}>
            Комментарий
            <textarea rows={3} value={comments} onChange={(e) => setComments(e.target.value)} />
          </label>
          <div className="row" style={{ marginTop: 10 }}>
            <button onClick={() => void submit()} disabled={!selectedCode}>Сохранить</button>
          </div>
        </div>
      )}

      <div className="card">
        <h3>Тесты</h3>
        <table>
          <thead>
            <tr>
              <th>Дата</th>
              <th>Результат</th>
              <th>pH</th>
              <th>Влажность</th>
              <th>Комментарий</th>
            </tr>
          </thead>
          <tbody>
            {tests.map((t: any, idx) => (
              <tr key={t.id ?? idx}>
                <td>{String(t.test_date ?? t.created_at ?? "").slice(0, 10)}</td>
                <td><span className="pill">{t.result ?? t.test_result ?? "?"}</span></td>
                <td>{t.ph ?? "—"}</td>
                <td>{t.moisture_pct ?? "—"}</td>
                <td>{t.comments ?? "—"}</td>
              </tr>
            ))}
            {tests.length === 0 && <tr><td colSpan={5}>Нет данных</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
