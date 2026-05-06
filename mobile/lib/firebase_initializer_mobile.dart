// 
// ⚠️ FIREBASE IS DISABLED ⚠️
// This app doesn't use Firebase - all code commented out
//
/*
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Push Notifications
  await NotificationService().initialize();
  
  print('Firebase initialized for mobile platform');
}
*/

Future<void> initializeFirebase() async {
  // Firebase not used - no initialization needed
  print('Firebase initialization skipped (not configured)');
}
