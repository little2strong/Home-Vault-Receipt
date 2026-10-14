/// Route names. Numbers are the page numbers in the Developer Spec and the
/// "All 44 Pages" design file.
abstract final class Routes {
  // Start (1–5)
  static const splash = '/'; // 01
  static const welcome = '/welcome'; // 02
  static const signIn = '/sign-in'; // 03
  static const checkEmail = '/check-email'; // 04
  static const finishSignIn = '/finish-sign-in';
  static const notifications = '/notifications'; // 05

  // Tabs: Home (06), Products (19), Warranties (30), Account (32)
  static const shell = '/home';
  static const search = '/search'; // 07

  // Add (8–18). The Add sheet (08) opens over the shell.
  static const camera = '/capture/camera'; // 09
  static const pages = '/capture/pages'; // 10
  static const reading = '/capture/reading'; // 11
  static const reviewDetails = '/review/details'; // 12
  static const reviewItems = '/review/items'; // 13 (14, 15 open over it)
  static const saved = '/saved'; // 16
  static const manual = '/manual'; // 17
  static const addItem = '/add-item'; // 18

  // Products (20–25). The Filters sheet (20) opens over Products.
  static String item(String id) => '/item/$id'; // 21
  static const itemPattern = '/item/:id';
  static String receipt(String id) => '/receipt/$id'; // 22
  static const receiptPattern = '/receipt/:id';
  static String original(String receiptId) => '/receipt/$receiptId/original';
  static const originalPattern = '/receipt/:id/original'; // 23
  static String photos(String itemId) => '/item/$itemId/photos';
  static const photosPattern = '/item/:id/photos'; // 24
  static const photoTips = '/photo-tips'; // 25

  // Rooms (26–29)
  static const homeSetup = '/home-setup'; // 26
  static const rooms = '/rooms'; // 27
  static String room(String id) => '/room/$id';
  static const roomPattern = '/room/:id'; // 28
  static String roomVideo(String id) => '/room/$id/video';
  static const roomVideoPattern = '/room/:id/video'; // 29

  // Warranties (31)
  static String warranty(String itemId) => '/item/$itemId/warranty';
  static const warrantyPattern = '/item/:id/warranty'; // 31

  // Account (33–38)
  static const spending = '/spending'; // 33
  static const cars = '/cars'; // 34
  static const export = '/export'; // 35
  static String exportReady(String id) => '/export/$id';
  static const exportReadyPattern = '/export/:id'; // 36
  static const settings = '/settings'; // 37
  static const deleteAccount = '/delete-account'; // 38
  static const pending = '/pending';
  static const help = '/help';
  static const privacy = '/privacy';
  static const terms = '/terms';

  // Website (W1–W6)
  static const webSignIn = '/sign-in'; // W1
  static const webDashboard = '/dashboard'; // W2
  static const webProducts = '/products'; // W3
  static String webItem(String id) => '/products/$id';
  static const webItemPattern = '/products/:id'; // W4
  static const webInventory = '/inventory'; // W5
  static const webDownloads = '/downloads'; // W6
  static const webDeleteAccount = '/account/delete';
}
