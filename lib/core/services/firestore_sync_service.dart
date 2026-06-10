import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../storage/hive_helper.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/subscription_model.dart';
import '../models/bill_reminder_model.dart';
import '../models/challenge_model.dart';
import '../models/group_model.dart';

class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Check if user is authenticated with Firebase
  bool get isAuthenticated => _uid != null;

  // Single upload helper
  Future<void> _uploadDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    if (!isAuthenticated) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection(collectionName)
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error uploading to Firestore collection $collectionName: $e');
    }
  }

  // Single delete helper
  Future<void> _deleteDocument(String collectionName, String docId) async {
    if (!isAuthenticated) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection(collectionName)
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting from Firestore collection $collectionName: $e');
    }
  }

  // Push single transaction
  Future<void> syncTransaction(TransactionModel tx) async {
    await _uploadDocument('transactions', tx.id, tx.toMap());
  }

  // Delete single transaction
  Future<void> deleteTransaction(String id) async {
    await _deleteDocument('transactions', id);
  }

  // Push budget details
  Future<void> syncBudget(BudgetModel budget) async {
    if (!isAuthenticated) return;
    try {
      await _firestore
          .collection('users')
          .doc(_uid)
          .collection('budgets')
          .doc('monthly')
          .set(budget.toMap());
    } catch (e) {
      debugPrint('Error syncing budget: $e');
    }
  }

  // Push single goal
  Future<void> syncGoal(GoalModel goal) async {
    await _uploadDocument('goals', goal.id, goal.toMap());
  }

  // Push single subscription
  Future<void> syncSubscription(SubscriptionModel sub) async {
    await _uploadDocument('subscriptions', sub.id, sub.toMap());
  }

  // Push single bill reminder
  Future<void> syncBill(BillReminderModel bill) async {
    await _uploadDocument('bills', bill.id, bill.toMap());
  }

  // Push single challenge
  Future<void> syncChallenge(ChallengeModel challenge) async {
    await _uploadDocument('challenges', challenge.id, challenge.toMap());
  }

  // Push single group
  Future<void> syncGroup(GroupModel group) async {
    await _uploadDocument('groups', group.id, group.toMap());
  }

  // ─── Profile picture (Firebase Storage) ───────────────────────────────────

  /// Upload [localPath] to Storage as `users/{uid}/profile.jpg`.
  /// Uploading to the same path automatically replaces the old file,
  /// so no extra storage is consumed.
  Future<void> syncProfilePicture(String localPath) async {
    if (!isAuthenticated) return;
    try {
      final file = File(localPath);
      if (!await file.exists()) return;

      final ref = FirebaseStorage.instance.ref('users/$_uid/profile.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // Store URL in Firestore user document (replaces old value)
      await _firestore
          .collection('users')
          .doc(_uid)
          .set({'photoUrl': url}, SetOptions(merge: true));

      // Cache the URL locally so syncLocalToCloud can reference it
      final settingsBox = Hive.box(HiveHelper.settingsBox);
      await settingsBox.put('profile_picture_url', url);

      debugPrint('Profile picture uploaded to Firebase Storage');
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
    }
  }

  /// Delete the profile picture from Storage and remove from Firestore.
  Future<void> removeProfilePicture() async {
    if (!isAuthenticated) return;
    try {
      await FirebaseStorage.instance
          .ref('users/$_uid/profile.jpg')
          .delete();
    } catch (_) {}
    try {
      await _firestore.collection('users').doc(_uid).update(
            {'photoUrl': FieldValue.delete()},
          );
    } catch (e) {
      debugPrint('Error removing profile picture from Firestore: $e');
    }
  }

  // ─── 1-year data retention cleanup ────────────────────────────────────────

  /// Delete transactions older than 1 year from both Firestore and Hive.
  /// Called automatically after each cloud→local sync.
  Future<void> cleanupOldData() async {
    if (!isAuthenticated) return;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 365));
      final cutoffStr = cutoff.toIso8601String(); // ISO8601 is lexicographically sortable

      // ── Firestore: batch-delete old transactions ──────────────────────
      final oldDocs = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .where('date', isLessThan: cutoffStr)
          .get();

      if (oldDocs.docs.isNotEmpty) {
        // Firestore batch allows max 500 writes; split if needed
        final chunks = <List<QueryDocumentSnapshot>>[];
        for (int i = 0; i < oldDocs.docs.length; i += 400) {
          chunks.add(oldDocs.docs.sublist(
              i, i + 400 > oldDocs.docs.length ? oldDocs.docs.length : i + 400));
        }
        for (final chunk in chunks) {
          final batch = _firestore.batch();
          for (final doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
        debugPrint('Deleted ${oldDocs.docs.length} transactions older than 1 year from Firestore');
      }

      // ── Hive: remove same old transactions locally ────────────────────
      final txBox = Hive.box(HiveHelper.transactionsBox);
      final oldKeys = <dynamic>[];
      for (final key in txBox.keys) {
        final raw = txBox.get(key);
        if (raw == null) continue;
        final dateVal = Map<String, dynamic>.from(raw)['date'];
        if (dateVal is String) {
          final txDate = DateTime.tryParse(dateVal);
          if (txDate != null && txDate.isBefore(cutoff)) {
            oldKeys.add(key);
          }
        }
      }
      for (final key in oldKeys) {
        await txBox.delete(key);
      }
      if (oldKeys.isNotEmpty) {
        debugPrint('Removed ${oldKeys.length} old transactions from local cache');
      }
    } catch (e) {
      debugPrint('Error during old-data cleanup: $e');
    }
  }

  // Sync entire local Hive database to cloud (useful on first login/manual sync)
  Future<void> syncLocalToCloud() async {
    if (!isAuthenticated) return;

    try {
      // 1. Transactions
      final txBox = Hive.box(HiveHelper.transactionsBox);
      for (var id in txBox.keys) {
        final txMap = Map<String, dynamic>.from(txBox.get(id));
        await _uploadDocument('transactions', id.toString(), txMap);
      }

      // 2. Budget
      final budgetBox = Hive.box(HiveHelper.budgetsBox);
      final budgetData = Map<String, dynamic>.from(budgetBox.toMap());
      if (budgetData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('budgets')
            .doc('monthly')
            .set(budgetData);
      }

      // 3. Goals
      final goalBox = Hive.box(HiveHelper.goalsBox);
      for (var id in goalBox.keys) {
        final goalMap = Map<String, dynamic>.from(goalBox.get(id));
        await _uploadDocument('goals', id.toString(), goalMap);
      }

      // 4. Subscriptions
      final subBox = Hive.box(HiveHelper.subscriptionsBox);
      for (var id in subBox.keys) {
        final subMap = Map<String, dynamic>.from(subBox.get(id));
        await _uploadDocument('subscriptions', id.toString(), subMap);
      }

      // 5. Bills
      final billBox = Hive.box(HiveHelper.billsBox);
      for (var id in billBox.keys) {
        final billMap = Map<String, dynamic>.from(billBox.get(id));
        await _uploadDocument('bills', id.toString(), billMap);
      }

      // 6. Challenges
      final challengeBox = Hive.box(HiveHelper.challengesBox);
      for (var id in challengeBox.keys) {
        final challengeMap = Map<String, dynamic>.from(challengeBox.get(id));
        await _uploadDocument('challenges', id.toString(), challengeMap);
      }

      // 6b. Groups
      final groupBox = Hive.box(HiveHelper.groupsBox);
      for (var id in groupBox.keys) {
        final groupMap = Map<String, dynamic>.from(groupBox.get(id));
        await _uploadDocument('groups', id.toString(), groupMap);
      }

      // 7. Sync user details (XP, name, etc.)
      final settingsBox = Hive.box(HiveHelper.settingsBox);
      final displayName = settingsBox.get('user_name', defaultValue: 'User');
      final profile = {
        'displayName': displayName,
        'displayNameLowercase': displayName.toString().toLowerCase(),
        'email': _auth.currentUser?.email?.toLowerCase(),
        'user_xp': settingsBox.get('user_xp', defaultValue: 0),
        'biometrics_enabled': settingsBox.get('biometrics_enabled', defaultValue: false),
        'currency': settingsBox.get('user_currency', defaultValue: '₹'),
        'has_completed_profile_setup': settingsBox.get('has_completed_profile_setup', defaultValue: false),
      };
      // Profile picture: prefer cached Storage URL, else upload the local file now
      final profilePhotoUrl = settingsBox.get('profile_picture_url') as String?;
      final profilePhotoPath = settingsBox.get('profile_picture_path') as String?;
      if (profilePhotoUrl != null) {
        profile['photoUrl'] = profilePhotoUrl;
      } else if (profilePhotoPath != null) {
        final localFile = File(profilePhotoPath);
        if (await localFile.exists()) {
          try {
            final storageRef = FirebaseStorage.instance.ref('users/$_uid/profile.jpg');
            await storageRef.putFile(localFile, SettableMetadata(contentType: 'image/jpeg'));
            final url = await storageRef.getDownloadURL();
            profile['photoUrl'] = url;
            await settingsBox.put('profile_picture_url', url);
          } catch (_) {}
        }
      }
      await _firestore.collection('users').doc(_uid).set(profile, SetOptions(merge: true));

      debugPrint('Sync Local to Cloud completed successfully!');
    } catch (e) {
      debugPrint('Error syncing local to cloud: $e');
    }
  }

  // Sync entire cloud database to local Hive boxes (overwrites or merges)
  Future<void> syncCloudToLocal() async {
    if (!isAuthenticated) return;

    try {
      // 1. User Profile settings
      final userDoc = await _firestore.collection('users').doc(_uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final settingsBox = Hive.box(HiveHelper.settingsBox);
        if (data.containsKey('displayName')) {
          await settingsBox.put('user_name', data['displayName']);
        }
        if (data.containsKey('photoUrl') && data['photoUrl'] != null) {
          final photoUrl = data['photoUrl'] as String;
          await settingsBox.put('profile_picture_url', photoUrl);
          // Download image from Firebase Storage to a local cache file
          try {
            final bytes = await FirebaseStorage.instance
                .ref('users/$_uid/profile.jpg')
                .getData(5 * 1024 * 1024); // max 5 MB
            if (bytes != null) {
              final tmpDir = await getTemporaryDirectory();
              final cachedFile = File('${tmpDir.path}/profile_cached.jpg');
              await cachedFile.writeAsBytes(bytes);
              await settingsBox.put('profile_picture_path', cachedFile.path);
            }
          } catch (_) {
            // Storage download failed — fall back to storing the URL directly
            await settingsBox.put('profile_picture_path', photoUrl);
          }
        }
        if (data.containsKey('has_completed_profile_setup')) {
          await settingsBox.put('has_completed_profile_setup', data['has_completed_profile_setup']);
        }
        if (data.containsKey('user_xp')) {
          await settingsBox.put('user_xp', data['user_xp']);
        }
        if (data.containsKey('currency')) {
          await settingsBox.put('user_currency', data['currency']);
        }
      } else {
        // User profile doesn't exist on Firestore (e.g. first-time Google sign-in/login)
        // Sync local settings to register the user profile on Firestore
        await syncLocalToCloud();
      }

      // 2. Transactions
      final txQuery = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .get();
      final txBox = Hive.box(HiveHelper.transactionsBox);
      await txBox.clear();
      for (var doc in txQuery.docs) {
        await txBox.put(doc.id, doc.data());
      }

      // 3. Budgets
      final budgetDoc = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('budgets')
          .doc('monthly')
          .get();
      if (budgetDoc.exists) {
        final budgetBox = Hive.box(HiveHelper.budgetsBox);
        await budgetBox.clear();
        final data = budgetDoc.data()!;
        for (var entry in data.entries) {
          await budgetBox.put(entry.key, entry.value);
        }
      }

      // 4. Goals
      final goalsQuery = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('goals')
          .get();
      final goalsBox = Hive.box(HiveHelper.goalsBox);
      await goalsBox.clear();
      for (var doc in goalsQuery.docs) {
        await goalsBox.put(doc.id, doc.data());
      }

      // 5. Subscriptions
      final subsQuery = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('subscriptions')
          .get();
      final subsBox = Hive.box(HiveHelper.subscriptionsBox);
      await subsBox.clear();
      for (var doc in subsQuery.docs) {
        await subsBox.put(doc.id, doc.data());
      }

      // 6. Bills
      final billsQuery = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('bills')
          .get();
      final billsBox = Hive.box(HiveHelper.billsBox);
      await billsBox.clear();
      for (var doc in billsQuery.docs) {
        await billsBox.put(doc.id, doc.data());
      }

      // 7. Challenges
      final challengeQuery = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('challenges')
          .get();
      final challengeBox = Hive.box(HiveHelper.challengesBox);
      await challengeBox.clear();
      for (var doc in challengeQuery.docs) {
        await challengeBox.put(doc.id, doc.data());
      }

      // 7b. Groups
      final groupsQuery = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('groups')
          .get();
      final groupsBox = Hive.box(HiveHelper.groupsBox);
      await groupsBox.clear();
      for (var doc in groupsQuery.docs) {
        await groupsBox.put(doc.id, doc.data());
      }

      // Purge transactions older than 1 year (both Firestore and Hive)
      await cleanupOldData();

      debugPrint('Sync Cloud to Local completed successfully!');
    } catch (e) {
      debugPrint('Error syncing cloud to local: $e');
    }
  }

  // Search users in database by email query for Split Expense
  Future<List<Map<String, dynamic>>> searchUsersByEmail(String emailQuery) async {
    if (emailQuery.trim().isEmpty) return [];
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: emailQuery.trim().toLowerCase())
          .where('email', isLessThanOrEqualTo: emailQuery.trim().toLowerCase() + '\uf8ff')
          .limit(10)
          .get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? 'User',
          'photoUrl': data['photoUrl'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error searching users by email: $e');
      return [];
    }
  }

  // Search users in database by name query (case-insensitive prefix search) for Group
  Future<List<Map<String, dynamic>>> searchUsersByName(String nameQuery) async {
    if (nameQuery.trim().isEmpty) return [];
    try {
      final query = nameQuery.trim();
      final capitalized = query[0].toUpperCase() + query.substring(1);
      final lowercase = query.toLowerCase();

      // Query both variations or do a general query
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      final list = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? 'User',
          'photoUrl': data['photoUrl'] ?? '',
        };
      }).toList();

      // If list is empty, also try search by lowercase
      if (list.isEmpty) {
        final querySnapshot2 = await _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: lowercase)
            .where('displayName', isLessThanOrEqualTo: lowercase + '\uf8ff')
            .limit(10)
            .get();
        list.addAll(querySnapshot2.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'email': data['email'] ?? '',
            'displayName': data['displayName'] ?? 'User',
            'photoUrl': data['photoUrl'] ?? '',
          };
        }));
      }

      // If list is still empty, also try capitalized
      if (list.isEmpty) {
        final querySnapshot3 = await _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: capitalized)
            .where('displayName', isLessThanOrEqualTo: capitalized + '\uf8ff')
            .limit(10)
            .get();
        list.addAll(querySnapshot3.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'email': data['email'] ?? '',
            'displayName': data['displayName'] ?? 'User',
            'photoUrl': data['photoUrl'] ?? '',
          };
        }));
      }

      // De-duplicate if needed
      final seen = <String>{};
      final uniqueList = <Map<String, dynamic>>[];
      for (var item in list) {
        if (seen.add(item['uid'])) {
          uniqueList.add(item);
        }
      }
      return uniqueList;
    } catch (e) {
      debugPrint('Error searching users by name: $e');
      return [];
    }
  }

  Future<void> updateProfileName(String newName, {String? photoUrl, bool? hasCompletedSetup}) async {
    if (!isAuthenticated) return;
    try {
      final Map<String, dynamic> updates = {
        'displayName': newName,
        'displayNameLowercase': newName.toLowerCase(),
      };
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }
      if (hasCompletedSetup != null) {
        updates['has_completed_profile_setup'] = hasCompletedSetup;
      }
      await _firestore.collection('users').doc(_uid).set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating profile name in Firestore: $e');
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    if (username.trim().isEmpty) return false;
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayNameLowercase', isEqualTo: username.trim().toLowerCase())
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        if (doc.id == _uid) {
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking if username is taken: $e');
      return false;
    }
  }
}
