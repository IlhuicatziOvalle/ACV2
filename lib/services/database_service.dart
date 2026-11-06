import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/emergency_contact.dart';
import '../models/test_result.dart';
import '../models/app_consent.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('alerta_acv.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = '${documentsDirectory.path}/$filePath';

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE emergency_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await _createTestResultsTable(db);
    await _createAppConsentsTable(db);
  }

  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion,) async {
    if (oldVersion < 2) {
      await _createTestResultsTable(db);
    }
    if (oldVersion < 3) {
      await _createAppConsentsTable(db);
    }
  }

  Future<void> _createTestResultsTable(Database db) async {
    await db.execute('''
      CREATE TABLE test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        speechLevel TEXT NOT NULL,
        faceLevel TEXT NOT NULL,
        armDrop INTEGER NOT NULL,
        riskLevel TEXT NOT NULL
      )
    ''');
  }

  // Emergency Contacts CRUD

  Future<int> createContact(EmergencyContact contact) async {
    final db = await database;
    return await db.insert('emergency_contacts', contact.toMap());
  }

  Future<List<EmergencyContact>> getAllContacts() async {
    final db = await database;
    final result = await db.query(
      'emergency_contacts',
      orderBy: 'name ASC',
    );
    return result.map((map) => EmergencyContact.fromMap(map)).toList();
  }

  Future<EmergencyContact?> getContact(int id) async {
    final db = await database;
    final result = await db.query(
      'emergency_contacts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return EmergencyContact.fromMap(result.first);
  }

  Future<int> updateContact(EmergencyContact contact) async {
    final db = await database;
    return await db.update(
      'emergency_contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(
      'emergency_contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Test Results CRUD

  Future<int> saveTestResult(TestResult result) async {
    final db = await database;
    return await db.insert('test_results', result.toMap());
  }

  Future<List<TestResult>> getAllTestResults() async {
    final db = await database;
    final result = await db.query(
      'test_results',
      orderBy: 'date DESC',
    );
    return result.map((map) => TestResult.fromMap(map)).toList();
  }

  Future<int> deleteTestResult(int id) async {
    final db = await database;
    return await db.delete(
      'test_results',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> _createAppConsentsTable(Database db) async {
    await db.execute('''
    CREATE TABLE app_consents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      informedConsentAccepted INTEGER NOT NULL,
      privacyAccepted INTEGER NOT NULL,
      acceptedAt TEXT NOT NULL,
      consentVersion TEXT NOT NULL,
      appName TEXT NOT NULL,
      appVersion TEXT NOT NULL
    )
  ''');
  }

  Future<int> saveConsent(AppConsent consent) async {
    final db = await database;

    return await db.insert(
      'app_consents',
      consent.toMap(),
    );
  }

  Future<AppConsent?> getLatestConsent() async {
    final db = await database;

    final result = await db.query(
      'app_consents',
      orderBy: 'acceptedAt DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return AppConsent.fromMap(result.first);
  }

  Future<bool> hasValidConsent(
      String requiredVersion,
      ) async {
    final consent = await getLatestConsent();

    if (consent == null) {
      return false;
    }

    return consent.informedConsentAccepted &&
        consent.privacyAccepted &&
        consent.consentVersion == requiredVersion;
  }
}
