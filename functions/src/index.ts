import { setGlobalOptions } from "firebase-functions/v2";

import { REGION } from "./common";

setGlobalOptions({ region: REGION, maxInstances: 10 });

export { deleteAccount, onUserCreated } from "./account";
export { cleanupExports, onExportRequested } from "./exports";
export { deleteItem, deletePhoto, deleteRoom, deleteRoomVideo, onItemWritten } from "./items";
export { onFileUploaded } from "./photos";
export { deleteReceipt, onReceiptWritten, saveReceipt } from "./receipts";
export { onProfileWritten, onReturnWritten, onWarrantyWritten, sendReminders } from "./reminders";
export { dailyStats } from "./stats";
