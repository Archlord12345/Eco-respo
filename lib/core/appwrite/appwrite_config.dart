import 'package:appwrite/appwrite.dart';

/// Configuration Appwrite — valeurs injectées via `--dart-define`.
class AppwriteConfig {
  static const endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://fra.cloud.appwrite.io/v1',
  );
  static const projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: 'eco-responsable-cm',
  );
  static const selfSigned = bool.fromEnvironment(
    'APPWRITE_SELF_SIGNED',
    defaultValue: false,
  );
  static const databaseId = 'eco_responsable_db';

  // Tables TablesDB (voir appwrite.config.json).
  static const usersCollection = 'users';
  static const reportsCollection = 'waste_reports';
  static const requestsCollection = 'collection_requests';
  static const collectorsCollection = 'collectors';
  static const rewardsCollection = 'reward_items';
  static const zonesCollection = 'zones';
  static const notificationsCollection = 'notifications';

  /// Canal Realtime des lignes d'une table (format SDK 26 :
  /// `tablesdb.<db>.tables.<table>.rows`).
  static String rowsChannel(String table) =>
      Channel.tablesdb(databaseId).table(table).row().toString();

  static const reportPhotosBucket = 'report_photos';
  static const collectionProofsBucket = 'collection_proofs';

  static const matchCollectorFn = 'matchCollector';
  static const computeRewardPointsFn = 'computeRewardPoints';
  static const paymentWebhookFn = 'paymentWebhook';
  static const generateAdminReportFn = 'generateAdminReport';
}
