import { randomUUID } from "node:crypto";
import { PassThrough } from "node:stream";

import archiver from "archiver";
import PDFDocument from "pdfkit";
import sharp from "sharp";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

import { CATEGORY_LABELS, Timestamp, bucket, db, medium, money, userPath } from "./common";

const DAY_MS = 24 * 60 * 60 * 1000;

type Doc = FirebaseFirestore.DocumentData & { id: string };

interface Vault {
  profile: FirebaseFirestore.DocumentData;
  items: Doc[];
  receipts: Doc[];
  rooms: Doc[];
  cars: Doc[];
  warranties: Doc[];
  returns: Doc[];
}

async function loadVault(uid: string): Promise<Vault> {
  const col = async (name: string) =>
    (await db.collection(`${userPath(uid)}/${name}`).get()).docs.map((d): Doc => ({ id: d.id, ...d.data() }));
  const [profile, items, receipts, rooms, cars, warranties, returns] = await Promise.all([
    db.doc(userPath(uid)).get(), col("items"), col("receipts"), col("rooms"), col("cars"),
    col("warranties"), col("returns"),
  ]);
  rooms.sort((a, b) => ((a as Doc).order ?? 0) - ((b as Doc).order ?? 0));
  return { profile: profile.data() ?? {}, items, receipts, rooms, cars, warranties, returns };
}

const csvCell = (v: unknown) => {
  const s = v == null ? "" : String(v);
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
const csv = (rows: unknown[][]) => rows.map((r) => r.map(csvCell).join(",")).join("\r\n") + "\r\n";
const pounds = (minor: number | null | undefined) => (minor == null ? "" : (minor / 100).toFixed(2));

export const inInventory = (i: Doc) => i.type === "physical" && i.inHome === true && (i.status ?? "owned") === "owned";

export interface Filters {
  includePhotos?: boolean;
  includeReceiptNumbers?: boolean;
  includeWithoutReceipts?: boolean;
  from?: string | null;
  purpose?: string | null;
}

/** One row per item per room it sits in. */
export function inventoryRows(v: Vault, f: Filters) {
  const roomName = (id: string) => v.rooms.find((r) => r.id === id)?.name ?? "Room";
  const out: Array<{ room: string; roomId: string | null; item: Doc; quantity: number; value: number | null }> = [];
  for (const i of v.items.filter(inInventory)) {
    if (f.includeWithoutReceipts === false && !i.receiptId) continue;
    const alloc = Object.entries((i.allocations ?? {}) as Record<string, number>);
    const unit = i.unitPriceMinor ?? (i.lineTotalMinor != null && i.quantity ? Math.round(i.lineTotalMinor / i.quantity) : null);
    if (alloc.length === 0) {
      out.push({ room: "No room yet", roomId: null, item: i, quantity: i.quantity ?? 1, value: i.lineTotalMinor ?? unit });
    } else {
      for (const [roomId, q] of alloc) {
        out.push({
          room: roomName(roomId), roomId, item: i, quantity: q,
          value: alloc.length > 1 && unit != null ? unit * q : (i.lineTotalMinor ?? unit),
        });
      }
    }
  }
  const order = (id: string | null) => {
    if (id == null) return 1e9;
    const room = v.rooms.find((r) => r.id === id);
    return (room?.order as number | undefined) ?? 0;
  };
  return out.sort((a, b) => order(a.roomId) - order(b.roomId) || String(a.item.name).localeCompare(b.item.name));
}

export function productItems(v: Vault, f: Filters) {
  return v.items.filter((i) =>
    (f.includeWithoutReceipts !== false || i.receiptId) &&
    (!f.from || (i.purchaseDate && i.purchaseDate >= f.from)) &&
    (!f.purpose || i.purpose === f.purpose),
  ).sort((a, b) => String(b.purchaseDate ?? "").localeCompare(String(a.purchaseDate ?? "")));
}

export function inventoryCsv(v: Vault, f: Filters): string {
  const warranty = (id: string) => v.warranties.find((w) => w.id === id)?.endDate ?? "";
  return csv([
    ["Room", "Item", "Quantity", "Price paid", "Currency", "Price is", "Bought", "Shop",
      ...(f.includeReceiptNumbers !== false ? ["Receipt"] : []), "Serial", "Model", "High value", "Photos", "Warranty ends"],
    ...inventoryRows(v, f).map((r) => [
      r.room, r.item.name, r.quantity, pounds(r.value), r.item.currency ?? "GBP",
      r.item.estimated ? "Estimate" : "Paid", r.item.purchaseDate ?? (r.item.yearBought ? `About ${r.item.yearBought}` : ""),
      r.item.shop ?? "", ...(f.includeReceiptNumbers !== false ? [r.item.receiptNumber ?? "No receipt"] : []),
      r.item.serial ?? "", r.item.model ?? "", r.item.highValue ? "Yes" : "", r.item.photoCount ?? 0, warranty(r.item.id),
    ]),
  ]);
}

export function productsCsv(v: Vault, f: Filters): string {
  const car = (id?: string) => v.cars.find((c) => c.id === id)?.name ?? "";
  const rooms = (i: Doc) => Object.keys(i.allocations ?? {}).map((id) => v.rooms.find((r) => r.id === id)?.name ?? "").join("; ");
  return csv([
    ["Item", "Category", "Type", "Purpose", "Car", "Quantity", "Unit price", "Line total", "Currency",
      "Bought", "Shop", ...(f.includeReceiptNumbers !== false ? ["Receipt"] : []), "Status", "Rooms", "Warranty ends"],
    ...productItems(v, f).map((i) => [
      i.name, CATEGORY_LABELS[i.category] ?? i.category, i.type, i.purpose, car(i.carId), i.quantity ?? 1,
      pounds(i.unitPriceMinor), pounds(i.lineTotalMinor), i.currency ?? "GBP", i.purchaseDate ?? "", i.shop ?? "",
      ...(f.includeReceiptNumbers !== false ? [i.receiptNumber ?? "No receipt"] : []),
      i.status ?? "owned", rooms(i), i.warrantyEnd ?? "",
    ]),
  ]);
}

/** Thumbnails for the PDF. Re-encoding drops all metadata, GPS included. */
async function thumbFor(item: Doc): Promise<Buffer | null> {
  if (!item.coverThumbPath) return null;
  try {
    const [b] = await bucket().file(item.coverThumbPath).download();
    return await sharp(b).resize(120, 120, { fit: "cover" }).jpeg({ quality: 70 }).toBuffer();
  } catch {
    return null;
  }
}

function pdfToBuffer(doc: PDFKit.PDFDocument): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    doc.on("data", (c: Buffer) => chunks.push(c));
    doc.on("end", () => resolve(Buffer.concat(chunks)));
    doc.on("error", reject);
    doc.end();
  });
}

export async function buildPdf(v: Vault, kind: "inventory" | "products", f: Filters): Promise<Buffer> {
  const doc = new PDFDocument({ size: "A4", margin: 48, info: { Title: "Home Vault", Author: "Home Vault" } });
  const ink = "#183A34", muted = "#5D6C65", line = "#DFE5DE";
  const name = (v.profile.displayName as string | undefined) ?? "";
  const today = new Date().toISOString().slice(0, 10);
  doc.fillColor(ink).fontSize(22).font("Helvetica-Bold")
    .text(kind === "inventory" ? "Home inventory" : "Itemised product list");
  doc.moveDown(0.2).fontSize(11).font("Helvetica").fillColor(muted)
    .text([name, `Created ${medium(today)}`].filter(Boolean).join(" · "));
  doc.moveDown(0.4).fontSize(9).text(
    "Prices are what was paid, not replacement value. Estimates are marked. " +
    "Home Vault records what the owner confirmed; the insurer decides what is covered.",
  );
  doc.moveDown(1);

  const row = async (item: Doc, title: string, sub: string, price: string) => {
    if (doc.y > 760) doc.addPage();
    const y = doc.y;
    let x = 48;
    if (f.includePhotos !== false) {
      const t = await thumbFor(item);
      if (t) doc.image(t, 48, y, { width: 36, height: 36 });
      x = 92;
    }
    doc.fillColor(ink).font("Helvetica-Bold").fontSize(10).text(title, x, y, { width: 330 });
    doc.fillColor(muted).font("Helvetica").fontSize(8.5).text(sub, x, doc.y + 1, { width: 330 });
    doc.fillColor(ink).font("Helvetica-Bold").fontSize(10).text(price, 430, y, { width: 117, align: "right" });
    const bottom = Math.max(doc.y, y + (f.includePhotos !== false ? 38 : 24)) + 6;
    doc.moveTo(48, bottom).lineTo(547, bottom).strokeColor(line).lineWidth(0.5).stroke();
    doc.y = bottom + 6;
    doc.x = 48;
  };

  if (kind === "inventory") {
    const rows = inventoryRows(v, f);
    let room = "";
    for (const r of rows) {
      if (r.room !== room) {
        room = r.room;
        const inRoom = rows.filter((x) => x.room === room);
        if (doc.y > 720) doc.addPage();
        doc.moveDown(0.6).fillColor(ink).font("Helvetica-Bold").fontSize(14)
          .text(`${room} · ${inRoom.length} item${inRoom.length === 1 ? "" : "s"}`, 48);
        doc.moveDown(0.4);
      }
      const i = r.item;
      const evidence = [
        i.receiptId ? (f.includeReceiptNumbers !== false ? `Receipt ${i.receiptNumber}` : "Receipt") : "No receipt",
        `${i.photoCount ?? 0} photo${i.photoCount === 1 ? "" : "s"}`,
        i.serial ? `Serial ${i.serial}` : null,
        i.purchaseDate ? `Bought ${medium(i.purchaseDate)}` : i.yearBought ? `About ${i.yearBought}` : null,
        i.shop,
        i.highValue ? "High value" : null,
      ].filter(Boolean).join(" · ");
      const qty = (i.allocations && Object.keys(i.allocations).length > 1) ? ` (${r.quantity} of ${i.quantity})` : (r.quantity > 1 ? ` × ${r.quantity}` : "");
      const price = i.estimated ? `~${money(r.value, i.currency)}` : money(r.value, i.currency);
      await row(i, `${i.name}${qty}`, evidence, price);
    }
    if (rows.length === 0) doc.fillColor(muted).text("No items in the home inventory yet.");
  } else {
    for (const i of productItems(v, f)) {
      const sub = [
        CATEGORY_LABELS[i.category] ?? i.category, i.purpose, i.shop,
        i.purchaseDate ? medium(i.purchaseDate) : null,
        f.includeReceiptNumbers !== false ? (i.receiptNumber ?? "No receipt") : null,
      ].filter(Boolean).join(" · ");
      await row(i, `${i.name}${(i.quantity ?? 1) > 1 ? ` × ${i.quantity}` : ""}`, sub, money(i.lineTotalMinor, i.currency));
    }
  }
  return pdfToBuffer(doc);
}

/** A ZIP of named files; photos and originals are added from Storage. */
async function buildZip(entries: Array<{ name: string; data: Buffer | string }>, storageFiles: Array<{ name: string; path: string; image: boolean }>): Promise<Buffer> {
  const zip = archiver("zip", { zlib: { level: 6 } });
  const out = new PassThrough();
  const chunks: Buffer[] = [];
  out.on("data", (c: Buffer) => chunks.push(c));
  const done = new Promise<void>((resolve, reject) => {
    out.on("end", resolve);
    zip.on("error", reject);
  });
  zip.pipe(out);
  for (const e of entries) zip.append(e.data, { name: e.name });
  for (const f of storageFiles) {
    try {
      const [b] = await bucket().file(f.path).download();
      // Photos are re-encoded so no location or other metadata leaves.
      const data = f.image ? await sharp(b).rotate().jpeg({ quality: 90 }).toBuffer() : b;
      zip.append(data, { name: f.name });
    } catch {
      // A missing file is skipped rather than failing the whole export.
    }
  }
  await zip.finalize();
  await done;
  return Buffer.concat(chunks);
}

async function archive(uid: string, v: Vault, f: Filters): Promise<Buffer> {
  const strip = (d: Doc) => {
    const { searchTokens: _t, ocrText: _o, ...rest } = d;
    void _t; void _o;
    return rest;
  };
  const files: Array<{ name: string; path: string; image: boolean }> = [];
  for (const r of v.receipts) {
    (r.originalPaths ?? []).forEach((p: string, n: number) =>
      files.push({ name: `originals/${r.number}-${n + 1}.${p.endsWith(".pdf") ? "pdf" : "jpg"}`, path: p, image: !p.endsWith(".pdf") }));
  }
  if (f.includePhotos !== false) {
    for (const i of v.items) {
      const photos = await db.collection(`${userPath(uid)}/items/${i.id}/photos`).get();
      photos.docs.forEach((p, n) =>
        files.push({ name: `photos/${String(i.name).replace(/[^A-Za-z0-9-]+/g, "-")}-${n + 1}.jpg`, path: p.data().path, image: true }));
    }
  }
  const data = {
    exportedAt: new Date().toISOString(),
    profile: v.profile, receipts: v.receipts.map(strip), items: v.items.map(strip),
    rooms: v.rooms, cars: v.cars, warranties: v.warranties, returns: v.returns,
  };
  return buildZip([
    { name: "home-vault-data.json", data: JSON.stringify(data, (_k, val) => (val instanceof Timestamp ? val.toDate().toISOString() : val), 2) },
    { name: "products.csv", data: productsCsv(v, f) },
    { name: "home-inventory.csv", data: inventoryCsv(v, f) },
    { name: "README.txt", data: "Your Home Vault data. Location has been removed from photos.\r\n" },
  ], files);
}

/** A link that expires with the export. */
async function linkFor(path: string): Promise<string> {
  const file = bucket().file(path);
  try {
    const [url] = await file.getSignedUrl({ action: "read", expires: Date.now() + DAY_MS });
    return url;
  } catch {
    // Without signBlob permission: a token link; the file itself is
    // deleted after 24 hours by cleanupExports.
    const token = randomUUID();
    await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
    const b = bucket().name;
    return `https://firebasestorage.googleapis.com/v0/b/${b}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
  }
}

export async function buildExport(uid: string, exportId: string, data: FirebaseFirestore.DocumentData) {
  const kind = ["inventory", "products", "archive"].includes(data.kind) ? data.kind : "inventory";
  const format = ["pdf", "csv", "both", "zip"].includes(data.format) ? data.format : "pdf";
  const f: Filters = data.filters ?? {};
  const v = await loadVault(uid);
  let body: Buffer;
  let ext: string;
  let contentType: string;
  if (kind === "archive") {
    body = await archive(uid, v, f);
    ext = "zip";
    contentType = "application/zip";
  } else {
    const listKind = kind as "inventory" | "products";
    const csvText = listKind === "inventory" ? inventoryCsv(v, f) : productsCsv(v, f);
    if (format === "csv") {
      body = Buffer.from(csvText, "utf8");
      ext = "csv";
      contentType = "text/csv";
    } else if (format === "both") {
      body = await buildZip([
        { name: `${listKind}.pdf`, data: await buildPdf(v, listKind, f) },
        { name: `${listKind}.csv`, data: csvText },
      ], []);
      ext = "zip";
      contentType = "application/zip";
    } else {
      body = await buildPdf(v, listKind, f);
      ext = "pdf";
      contentType = "application/pdf";
    }
  }
  const path = `users/${uid}/exports/${exportId}.${ext}`;
  await bucket().file(path).save(body, { contentType, resumable: false });
  const itemCount = kind === "inventory"
    ? new Set(inventoryRows(v, f).map((r) => r.item.id)).size
    : kind === "products" ? productItems(v, f).length : v.items.length;
  const roomCount = new Set(inventoryRows(v, f).map((r) => r.roomId).filter(Boolean)).size;
  return {
    status: "ready",
    path,
    paths: [path],
    url: await linkFor(path),
    sizeBytes: body.length,
    itemCount,
    roomCount,
    expiresAt: Timestamp.fromMillis(Date.now() + DAY_MS),
    readyAt: Timestamp.now(),
  };
}

/** Created by the app, filled here. Stored privately. */
export const onExportRequested = onDocumentCreated(
  { document: "users/{uid}/exports/{exportId}", memory: "1GiB", timeoutSeconds: 540 },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    try {
      await snap.ref.update(await buildExport(event.params.uid, event.params.exportId, snap.data()));
    } catch (e) {
      console.error("export failed", { exportId: event.params.exportId, error: (e as Error).message });
      await snap.ref.update({ status: "failed", error: "The list could not be built. Try again." });
    }
  },
);

/** Links work for 24 hours; then the file is deleted. */
export async function expireExports(now = Timestamp.now()) {
  const due = await db.collectionGroup("exports").where("status", "==", "ready")
    .where("expiresAt", "<=", now).limit(500).get();
  for (const d of due.docs) {
    for (const p of (d.data().paths ?? []) as string[]) {
      await bucket().file(p).delete({ ignoreNotFound: true }).catch(() => undefined);
    }
    await d.ref.update({ status: "expired", url: null });
  }
  return due.size;
}

export const cleanupExports = onSchedule({ schedule: "every 60 minutes", timeoutSeconds: 300 }, async () => {
  await expireExports();
});
