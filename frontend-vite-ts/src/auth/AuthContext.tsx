import React, { createContext, useContext, useEffect, useMemo, useRef, useState } from "react";
import { api } from "../app/api";

export type UserRole = "guest" | "client" | "technologist" | "inspector" | "manager" | "admin";

export type Me = {
  id: number;
  login: string;
  first_name: string;
  last_name: string;
  role: UserRole | string;
};

type AuthState = {
  token: string | null;
  me: Me | null;
  isLoading: boolean;
  login: (login: string, password: string) => Promise<Me | null>;
  logout: () => Promise<void>;
  refreshMe: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

async function fetchMeSafe(): Promise<Me | null> {
  try {
    const res = await api.get("/auth/me");
    return res.data as Me;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setTokenState] = useState<string | null>(() => localStorage.getItem("auth_token"));
  const [me, setMe] = useState<Me | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(!!token);

  // Prevent duplicate /auth/me calls (React 18 StrictMode + multiple callers).
  const inFlightRef = useRef<Promise<Me | null> | null>(null);
  const lastFetchedTokenRef = useRef<string | null>(null);

  const setToken = (t: string | null) => {
    setTokenState(t);
    if (t) localStorage.setItem("auth_token", t);
    else localStorage.removeItem("auth_token");
  };

  const refreshMe = async () => {
    if (!token) {
      setMe(null);
      lastFetchedTokenRef.current = null;
      return;
    }

    // Already fetched for this token and we have a profile.
    if (lastFetchedTokenRef.current === token && me) return;

    // If a fetch is already running, reuse it.
    if (inFlightRef.current) {
      setIsLoading(true);
      const m = await inFlightRef.current;
      setMe(m);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    const p = fetchMeSafe();
    inFlightRef.current = p;
    const m = await p;
    inFlightRef.current = null;

    if (!m) {
      // token expired / session lost
      setToken(null);
      setMe(null);
      lastFetchedTokenRef.current = null;
    } else {
      setMe(m);
      lastFetchedTokenRef.current = token;
    }
    setIsLoading(false);
  };

  useEffect(() => {
    void refreshMe();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  const login = async (loginValue: string, password: string): Promise<Me | null> => {
    const res = await api.post("/auth/login", { login: loginValue, password });
    const t = res.data?.access_token as string | undefined;
    if (!t) throw new Error("No access_token in response");
    setToken(t);

    // Load profile immediately, so UI can route by role without waiting for effect.
    // Also mark it as fetched for this token to avoid a second fetch from the token effect.
    setIsLoading(true);
    const p = fetchMeSafe();
    inFlightRef.current = p;
    const m = await p;
    inFlightRef.current = null;
    setMe(m);
    lastFetchedTokenRef.current = t;
    setIsLoading(false);
    return m;
  };

  const logout = async () => {
    try {
      await api.post("/auth/logout");
    } catch {
      // ignore
    } finally {
      setToken(null);
      setMe(null);
      lastFetchedTokenRef.current = null;
    }
  };

  const value = useMemo(
    () => ({ token, me, isLoading, login, logout, refreshMe }),
    [token, me, isLoading]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
