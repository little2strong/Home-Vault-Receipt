import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { getStorage } from "firebase-admin/storage";
import { CallableRequest, HttpsError } from "firebase-functions/v2/https";

if (getApps().length === 0) initializeApp();

export const db = getFirestore();
export const auth = getAuth();
export const messaging = getMessaging();
export const bucket = () => getStorage().bucket();
export { FieldValue, Timestamp };

/** UK region for Firestore, Storage and Functions. */
export const REGION = "europe-west2";

export const userPath = (uid: string) => `users/${uid}`;

/** Every callable needs a signed-in user. */
export function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Please sign in.");
  return uid;
}

export const isId = (v: unknown): v is string =>
  typeof v === "string" && /^[A-Za-z0-9_-]{1,64}$/.test(v);

export function str(v: unknown, max = 200): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t.length === 0 ? null : t.slice(0, max);
}

export function int(v: unknown, min = -1e12, max = 1e12): number | null {
  if (typeof v !== "number" || !Number.isFinite(v)) return null;
  const n = Math.round(v);
  return n < min || n > max ? null : n;
}

export const isoDate = (v: unknown): string | null =>
  typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v) ? v : null;

export function oneOf<T extends string>(v: unknown, values: readonly T[], fallback: T): T {
  return values.includes(v as T) ? (v as T) : fallback;
}

export const ITEM_TYPES = ["physical", "digital", "service", "consumable"] as const;
export const PURPOSES = ["home", "car", "work", "gift", "other"] as const;
export const STATUSES = ["owned", "returned", "sold", "broken", "givenAway"] as const;
export const SOURCES = ["camera", "photo", "pdf", "manual"] as const;
export const CATEGORIES = [
  "groceries", "electronics", "appliances", "furniture", "homeDiy", "lighting",
  "clothing", "accessories", "jewellery", "car", "health", "software",
  "services", "other",
] as const;
export const CURRENCIES = ["GBP", "EUR", "USD"] as const;

export const CATEGORY_LABELS: Record<string, string> = {
  groceries: "Groceries",
  electronics: "Electronics",
  appliances: "Appliances",
  furniture: "Furniture",
  homeDiy: "Home & DIY",
  lighting: "Lighting",
  clothing: "Clothing",
  accessories: "Accessories",
  jewellery: "Jewellery & watches",
  car: "Car",
  health: "Health & beauty",
  software: "Software & subscriptions",
  services: "Services",
  other: "Other",
};

/** Mirrors the app's `SearchText.tokens`: every prefix of every word. */
export function searchTokens(fields: Array<string | null | undefined>, maxLength = 20): string[] {
  const out = new Set<string>();
  for (const f of fields) {
    if (!f) continue;
    const words = f.toLowerCase().replace(/"/g, " ").split(/[^a-z0-9£€$'&]+/).filter(Boolean);
    for (const w of words) {
      const limit = Math.min(w.length, maxLength);
      for (let i = 1; i <= limit; i++) out.add(w.slice(0, i));
    }
  }
  return [...out].sort();
}

/** `HV-000123` */
export const receiptNumber = (n: number) => `HV-${String(n).padStart(6, "0")}`;

export const sameArray = (a: unknown, b: unknown[]) =>
  Array.isArray(a) && a.length === b.length && a.every((v, i) => v === b[i]);

/** Money from minor units, e.g. `£1,099.00`. */
export function money(minor: number | null | undefined, currency = "GBP"): string {
  if (minor == null) return "Not stated";
  const symbol = currency === "GBP" ? "£" : currency === "EUR" ? "€" : currency === "USD" ? "$" : `${currency} `;
  const sign = minor < 0 ? "-" : "";
  const abs = Math.abs(minor);
  const whole = Math.floor(abs / 100).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  return `${sign}${symbol}${whole}.${String(abs % 100).padStart(2, "0")}`;
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

/** `12 Sep 2026` from `2026-09-12`. */
export function medium(iso: string | null | undefined): string {
  if (!iso) return "Not stated";
  const [y, m, d] = iso.split("-").map(Number);
  return `${d} ${MONTHS[m - 1]} ${y}`;
}
