import React, { createContext, useContext, useMemo, useState } from "react";
import { api } from "../app/api";

type AuthState = {
  token: string | null;
  setToken: (t: string | null) => void;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setTokenState] = useState<string | null>(() => localStorage.getItem("auth_token"));

  const setToken = (t: string | null) => {
    setTokenState(t);
    if (t) localStorage.setItem("auth_token", t);
    else localStorage.removeItem("auth_token");
  };

  // Пока backend может не иметь /auth/login — это “проводка”.
  const login = async (username: string, password: string) => {
    const res = await api.post("/auth/login", { username, password });
    const t = res.data?.access_token as string | undefined;
    if (!t) throw new Error("No access_token in response");
    setToken(t);
  };

  const logout = () => setToken(null);

  const value = useMemo(() => ({ token, setToken, login, logout }), [token]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
