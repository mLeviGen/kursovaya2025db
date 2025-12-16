import { useEffect, useState } from "react";
import { api } from "../app/api";

type AnyRow = Record<string, any>;

export default function Dashboard() {
  const [productSales, setProductSales] = useState<AnyRow[]>([]);
  const [customerSpending, setCustomerSpending] = useState<AnyRow[]>([]);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        setErr(null);
        const [ps, cs] = await Promise.all([
          api.get("/reports/product-sales?limit=10&offset=0"),
          api.get("/reports/customer-spending?limit=10&offset=0"),
        ]);
        setProductSales(ps.data ?? []);
        setCustomerSpending(cs.data ?? []);
      } catch (e: any) {
        setErr(e?.message ?? String(e));
      }
    })();
  }, []);

  return (
    <div className="container">
      <h2>Dashboard</h2>
      {err && <div className="error">{err}</div>}

      <div className="grid2">
        <div className="card">
          <h3>Top products</h3>
          <pre className="pre">{JSON.stringify(productSales, null, 2)}</pre>
        </div>

        <div className="card">
          <h3>Top customers</h3>
          <pre className="pre">{JSON.stringify(customerSpending, null, 2)}</pre>
        </div>
      </div>
    </div>
  );
}
