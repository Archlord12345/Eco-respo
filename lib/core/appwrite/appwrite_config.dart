/// Configuration Appwrite — valeurs injectées via `--dart-define`.
class AppwriteConfig {
  static const endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://appwrite.kernelforge.codes/v1',
  );
  static const projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '6aad2f1a000a6a6de281',
  );
  static const selfSigned = bool.fromEnvironment(
    'APPWRITE_SELF_SIGNED',
    defaultValue: false,
  );
  static const databaseId = 'eco_responsable_db';

  static const usersCollection = 'users';
  static const reportsCollection = 'waste_reports';
  static const requestsCollection = 'collection_requests';
  static const collectorsCollection = 'collectors';
  static const rewardsCollection = 'reward_items';
  static const zonesCollection = 'zones';
  static const notificationsCollection = 'notifications';

  static const reportPhotosBucket = 'report_photos';
  static const collectionProofsBucket = 'collection_proofs';

  static const matchCollectorFn = 'matchCollector';
  static const computeRewardPointsFn = 'computeRewardPoints';
  static const paymentWebhookFn = 'paymentWebhook';
  static const generateAdminReportFn = 'generateAdminReport';
}
