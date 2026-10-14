import { DateTime } from "luxon";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { FieldValue, db, userPath } from "./common";

type Totals = Record<string, number>;
type Nested = Record<string, Record<string, number>>;

const add = (t: Totals, currency: string, v: number) => {
  t[currency] = (t[currency] ?? 0) + v;
};
const addNested = (t: Nested, currency: string, key: string, v: number) => {
  t[currency] ??= {};
  t[currency][key] = (t[currency][key] ?? 0) + v;
};

export interface ReceiptLike {
  totalMinor?: number | null;
  currency?: string;
  purchaseDate?: string | null;
  confirmedAt?: { toDate(): Date } | null;
}

export interface ItemLike {
  receiptId?: string | null;
  lineTotalMinor?: number | null;
  currency?: string;
  purchaseDate?: string | null;
  category?: string;
  purpose?: string;
  carId?: string | null;
}

/**
 * Spending for the last 30 days, last year and lifetime, per currency,
 * from confirmed receipts only. Pure so it can be tested directly.
 */
export function computeStats(receipts: ReceiptLike[], items: ItemLike[], today: string) {
  const day = DateTime.fromISO(today);
  const from30 = day.minus({ days: 29 }).toISODate()!;
  const from365 = day.minus({ years: 1 }).plus({ days: 1 }).toISODate()!;
  const last30Days: Totals = {}, last365Days: Totals = {}, lifetime: Totals = {};
  let receipts30 = 0, receipts365 = 0;
  let firstPurchase: string | null = null;

  for (const r of receipts) {
    const date = r.purchaseDate ?? (r.confirmedAt ? DateTime.fromJSDate(r.confirmedAt.toDate()).toISODate() : null);
    const currency = r.currency ?? "GBP";
    const total = typeof r.totalMinor === "number" ? r.totalMinor : 0;
    add(lifetime, currency, total);
    if (date && (!firstPurchase || date < firstPurchase)) firstPurchase = date;
    if (date && date >= from365 && date <= today) {
      add(last365Days, currency, total);
      receipts365++;
    }
    if (date && date >= from30 && date <= today) {
      add(last30Days, currency, total);
      receipts30++;
    }
  }

  const byCategory30: Nested = {}, byPurpose30: Nested = {};
  const byCategory365: Nested = {}, byPurpose365: Nested = {};
  const byCategoryLifetime: Nested = {}, byPurposeLifetime: Nested = {};
  const cars: Record<string, { last30Days: Totals; last365Days: Totals; itemCount: number }> = {};

  for (const i of items) {
    if (!i.receiptId) continue;
    const v = typeof i.lineTotalMinor === "number" ? i.lineTotalMinor : 0;
    const c = i.currency ?? "GBP";
    const cat = i.category ?? "other";
    const purpose = i.purpose ?? "home";
    const date = i.purchaseDate;
    const in30 = !!date && date >= from30 && date <= today;
    const in365 = !!date && date >= from365 && date <= today;
    addNested(byCategoryLifetime, c, cat, v);
    addNested(byPurposeLifetime, c, purpose, v);
    if (in365) {
      addNested(byCategory365, c, cat, v);
      addNested(byPurpose365, c, purpose, v);
    }
    if (in30) {
      addNested(byCategory30, c, cat, v);
      addNested(byPurpose30, c, purpose, v);
    }
    if (i.carId) {
      const car = (cars[i.carId] ??= { last30Days: {}, last365Days: {}, itemCount: 0 });
      car.itemCount++;
      if (in30) add(car.last30Days, c, v);
      if (in365) add(car.last365Days, c, v);
    }
  }

  return {
    last30Days, last365Days, lifetime,
    receipts30, receipts365, receiptsLifetime: receipts.length,
    byCategory30, byPurpose30, byCategory365, byPurpose365,
    byCategoryLifetime, byPurposeLifetime, cars, firstPurchase,
  };
}

/** Recomputes `users/{uid}/stats/spending`; only Functions write it. */
export async function recomputeStats(uid: string) {
  const [profile, receipts, items] = await Promise.all([
    db.doc(userPath(uid)).get(),
    db.collection(`${userPath(uid)}/receipts`).get(),
    db.collection(`${userPath(uid)}/items`).where("receiptId", "!=", null).get(),
  ]);
  const zone = (profile.data()?.timezone as string | undefined) ?? "Europe/London";
  const today = DateTime.now().setZone(zone).toISODate() ?? DateTime.utc().toISODate()!;
  const stats = computeStats(
    receipts.docs.map((d) => d.data() as ReceiptLike),
    items.docs.map((d) => d.data() as ItemLike),
    today,
  );
  await db.doc(`${userPath(uid)}/stats/spending`).set({
    ...stats,
    updatedAt: FieldValue.serverTimestamp(),
  });
}

/** The 30-day and 1-year windows move every day. */
export const dailyStats = onSchedule(
  { schedule: "every day 03:15", timeZone: "Europe/London", timeoutSeconds: 540 },
  async () => {
    let last: FirebaseFirestore.QueryDocumentSnapshot | undefined;
    for (;;) {
      let q = db.collection("users").orderBy("__name__").limit(200);
      if (last) q = q.startAfter(last);
      const page = await q.get();
      if (page.empty) break;
      for (const u of page.docs) await recomputeStats(u.id).catch(() => undefined);
      last = page.docs[page.docs.length - 1];
    }
  },
);
