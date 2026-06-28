import 'purchase_service.dart';

/// アプリ全体で1つだけ持つサービスのインスタンス。
final purchaseService = PurchaseService();

/// 無料版の参加人数の上限(親機を含む)。
const int freePlayerLimit = 5;

/// 無料版で許可する子機の最大台数(親機1人分を引いた人数)。
const int freeClientLimit = freePlayerLimit - 1;
