import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appwrite_config.dart';

final appwriteClientProvider = Provider<Client>((ref) {
  return Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId)
      .setSelfSigned(status: AppwriteConfig.selfSigned);
});

final accountProvider = Provider<Account>(
  (ref) => Account(ref.watch(appwriteClientProvider)),
);

final databasesProvider = Provider<Databases>(
  (ref) => Databases(ref.watch(appwriteClientProvider)),
);

final storageProvider = Provider<Storage>(
  (ref) => Storage(ref.watch(appwriteClientProvider)),
);

final realtimeProvider = Provider<Realtime>(
  (ref) => Realtime(ref.watch(appwriteClientProvider)),
);

final functionsProvider = Provider<Functions>(
  (ref) => Functions(ref.watch(appwriteClientProvider)),
);
