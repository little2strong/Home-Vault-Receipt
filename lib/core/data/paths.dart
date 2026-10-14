/// All user data lives under `users/{uid}`, so one rule locks every
/// document and file to its owner.
abstract final class Paths {
  static String user(String uid) => 'users/$uid';
  static String receipts(String uid) => 'users/$uid/receipts';
  static String items(String uid) => 'users/$uid/items';
  static String photos(String uid, String itemId) =>
      'users/$uid/items/$itemId/photos';
  static String rooms(String uid) => 'users/$uid/rooms';
  static String cars(String uid) => 'users/$uid/cars';
  static String warranties(String uid) => 'users/$uid/warranties';
  static String returns(String uid) => 'users/$uid/returns';
  static String exports(String uid) => 'users/$uid/exports';
  static String devices(String uid) => 'users/$uid/devices';
  static String stats(String uid) => 'users/$uid/stats/spending';

  // Storage objects. Only paths are stored in Firestore, never URLs.
  static String original(String uid, String receiptId, int n, String ext) =>
      'users/$uid/receipts/$receiptId/original-$n.$ext';
  static String photo(String uid, String itemId, String photoId) =>
      'users/$uid/items/$itemId/photos/$photoId.jpg';
  static String warrantyCard(String uid, String itemId) =>
      'users/$uid/items/$itemId/warranty-card.jpg';
  static String roomVideo(String uid, String roomId) =>
      'users/$uid/rooms/$roomId/walkthrough.mp4';
}
