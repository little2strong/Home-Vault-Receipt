import { DateTime } from "luxon";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { Timestamp, db, medium, messaging, userPath } from "./common";

export interface Reminder {
  kind: string;
  at: Timestamp;
}

interface Settings {
  timezone: string;
  minutes: number;
  warranties: boolean;
  returns: boolean;
}

export const settingsFrom = (d?: FirebaseFirestore.DocumentData): Settings => ({
  timezone: (d?.timezone as string | undefined) ?? "Europe/London",
  minutes: typeof d?.reminderMinutes === "number" ? d.reminderMinutes : 9 * 60,
  warranties: d?.warrantyReminders !== false,
  returns: d?.returnReminders !== false,
});

/**
 * The instant a reminder fires: the user's reminder time on a calendar
 * date, in their own timezone, so a clock change never shifts it.
 */
export function localInstant(date: string, s: Settings): DateTime {
  return DateTime.fromISO(date, { zone: s.timezone }).startOf("day")
    .plus({ minutes: s.minutes });
}

/** 3 months and 2 weeks before a warranty ends (defaults). */
export function warrantyReminders(
  endDate: string, s: Settings, opts: { threeMonths: boolean; twoWeeks: boolean }, now: DateTime,
): Reminder[] {
  if (!s.warranties) return [];
  const end = DateTime.fromISO(endDate);
  const out: Array<[string, string]> = [];
  if (opts.threeMonths) out.push(["3m", end.minus({ months: 3 }).toISODate()!]);
  if (opts.twoWeeks) out.push(["2w", end.minus({ weeks: 2 }).toISODate()!]);
  return out
    .map(([kind, d]) => ({ kind, at: localInstant(d, s) }))
    .filter((r) => r.at > now)
    .map((r) => ({ kind: r.kind, at: Timestamp.fromMillis(r.at.toMillis()) }));
}

/** 7 days and 1 day before a return deadline, and on the last day. */
export function returnReminders(deadline: string, s: Settings, now: DateTime): Reminder[] {
  if (!s.returns) return [];
  const end = DateTime.fromISO(deadline);
  return ([["7d", 7], ["1d", 1], ["0d", 0]] as Array<[string, number]>)
    .map(([kind, days]) => ({ kind, at: localInstant(end.minus({ days }).toISODate()!, s) }))
    .filter((r) => r.at > now)
    .map((r) => ({ kind: r.kind, at: Timestamp.fromMillis(r.at.toMillis()) }));
}

const nextOf = (list: Reminder[]) =>
  list.length === 0 ? null : list.reduce((a, b) => (a.at.toMillis() <= b.at.toMillis() ? a : b)).at;

const sameSchedule = (a: unknown, b: Reminder[]) =>
  Array.isArray(a) && a.length === b.length &&
  a.every((r, i) => r?.kind === b[i].kind && r?.at?.toMillis?.() === b[i].at.toMillis());

async function scheduleWarranty(ref: FirebaseFirestore.DocumentReference, data: FirebaseFirestore.DocumentData, s: Settings) {
  if (!data.endDate) return;
  const reminders = warrantyReminders(data.endDate, s, {
    threeMonths: data.remind3Months !== false,
    twoWeeks: data.remind2Weeks !== false,
  }, DateTime.now()).filter((r) => !(data.sentKinds ?? []).includes(r.kind));
  if (sameSchedule(data.reminders, reminders)) return;
  await ref.update({ reminders, nextReminderAt: nextOf(reminders) });
}

async function scheduleReturn(ref: FirebaseFirestore.DocumentReference, data: FirebaseFirestore.DocumentData, s: Settings) {
  if (!data.deadline) return;
  const reminders = returnReminders(data.deadline, s, DateTime.now())
    .filter((r) => !(data.sentKinds ?? []).includes(r.kind));
  if (sameSchedule(data.reminders, reminders)) return;
  await ref.update({ reminders, nextReminderAt: nextOf(reminders) });
}

const changedDate = (before: FirebaseFirestore.DocumentData | undefined, after: FirebaseFirestore.DocumentData, key: string) =>
  before?.[key] !== after[key];

export const onWarrantyWritten = onDocumentWritten("users/{uid}/warranties/{itemId}", async (event) => {
  const after = event.data?.after.data();
  if (!after) return;
  const before = event.data?.before.data();
  // A new end date starts a fresh set of reminders.
  if (before && changedDate(before, after, "endDate") && after.sentKinds?.length) {
    await event.data!.after.ref.update({ sentKinds: [] });
    return;
  }
  const profile = await db.doc(userPath(event.params.uid)).get();
  await scheduleWarranty(event.data!.after.ref, after, settingsFrom(profile.data()));
});

export const onReturnWritten = onDocumentWritten("users/{uid}/returns/{receiptId}", async (event) => {
  const after = event.data?.after.data();
  if (!after) return;
  const before = event.data?.before.data();
  if (before && changedDate(before, after, "deadline") && after.sentKinds?.length) {
    await event.data!.after.ref.update({ sentKinds: [] });
    return;
  }
  const profile = await db.doc(userPath(event.params.uid)).get();
  await scheduleReturn(event.data!.after.ref, after, settingsFrom(profile.data()));
});

/** Reminder time, timezone or on/off changed: reschedule everything. */
export const onProfileWritten = onDocumentWritten("users/{uid}", async (event) => {
  const before = settingsFrom(event.data?.before.data());
  const afterData = event.data?.after.data();
  if (!afterData) return;
  const after = settingsFrom(afterData);
  if (JSON.stringify(before) === JSON.stringify(after)) return;
  const uid = event.params.uid;
  const [w, r] = await Promise.all([
    db.collection(`${userPath(uid)}/warranties`).get(),
    db.collection(`${userPath(uid)}/returns`).get(),
  ]);
  for (const d of w.docs) await scheduleWarranty(d.ref, d.data(), after);
  for (const d of r.docs) await scheduleReturn(d.ref, d.data(), after);
});

export function messageFor(collection: "warranties" | "returns", kind: string, d: FirebaseFirestore.DocumentData) {
  if (collection === "warranties") {
    const what = d.itemName ?? "An item";
    const where = d.shop ? ` · bought at ${d.shop}` : "";
    return kind === "3m"
      ? { title: "Warranty ends in 3 months", body: `${what}${where}. Ends ${medium(d.endDate)}.` }
      : {
          title: "Warranty ends in 2 weeks",
          body: `${what}${where}. Book a repair now if it has a fault.`,
        };
  }
  const what = [d.label, d.shop].filter(Boolean).join(" · ") || "A purchase";
  return kind === "0d"
    ? { title: "Last day to return", body: what }
    : kind === "1d"
      ? { title: "1 day left to return", body: `${what}. Last day ${medium(d.deadline)}.` }
      : { title: "7 days left to return", body: `${what}. Last day ${medium(d.deadline)}.` };
}

/** Sends due reminders. Runs often so each lands at the user's local time. */
export async function sendDueReminders(now = Timestamp.now()) {
  let sent = 0;
  for (const collection of ["warranties", "returns"] as const) {
    const due = await db.collectionGroup(collection).where("nextReminderAt", "<=", now).limit(500).get();
    for (const doc of due.docs) {
      const uid = doc.ref.parent.parent!.id;
      const data = doc.data();
      const reminders = (data.reminders ?? []) as Reminder[];
      const fired = reminders.filter((r) => r.at.toMillis() <= now.toMillis());
      const remaining = reminders.filter((r) => r.at.toMillis() > now.toMillis());
      const devices = await db.collection(`${userPath(uid)}/devices`).get();
      const tokens = devices.docs.map((d) => d.id);
      // Only the latest due reminder is sent if several were missed.
      const latest = fired.sort((a, b) => b.at.toMillis() - a.at.toMillis())[0];
      if (latest && tokens.length) {
        const route = collection === "warranties" ? `/item/${doc.id}` : `/receipt/${doc.id}`;
        const res = await messaging.sendEachForMulticast({
          tokens,
          notification: messageFor(collection, latest.kind, data),
          data: { route },
          android: { notification: { channelId: "reminders" } },
        });
        sent += res.successCount;
        const stale = res.responses
          .map((r, i) => (!r.success && /registration-token-not-registered|invalid-argument/.test(r.error?.code ?? "") ? tokens[i] : null))
          .filter((t): t is string => t != null);
        await Promise.all(stale.map((t) => db.doc(`${userPath(uid)}/devices/${t}`).delete()));
      }
      await doc.ref.update({
        reminders: remaining,
        nextReminderAt: nextOf(remaining),
        sentKinds: [...(data.sentKinds ?? []), ...fired.map((r) => r.kind)],
      });
    }
  }
  return sent;
}

export const sendReminders = onSchedule(
  { schedule: "every 15 minutes", timeZone: "Europe/London", timeoutSeconds: 300 },
  async () => {
    await sendDueReminders();
  },
);
