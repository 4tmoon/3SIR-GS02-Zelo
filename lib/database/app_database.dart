import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/issue.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  AppDatabase._();

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final String path;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      path = 'zelo.db';
    } else {
      path = join(await getDatabasesPath(), 'zelo.db');
    }
    return openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE issues (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        address TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        likes INTEGER NOT NULL,
        activeRegionalUsers INTEGER NOT NULL,
        status TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        supported INTEGER NOT NULL DEFAULT 0
      )
    ''');
    for (final issue in _initialData) {
      await db.insert('issues', issue.toMap());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE issues ADD COLUMN supported INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<int> insert(Issue issue) async {
    final db = await database;
    return db.insert('issues', issue.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Issue>> getAll() async {
    final db = await database;
    final rows = await db.query('issues', orderBy: 'CAST(id AS INTEGER) DESC');
    return rows.map(Issue.fromMap).toList();
  }

  Future<int> update(Issue issue) async {
    final db = await database;
    return db.update('issues', issue.toMap(), where: 'id = ?', whereArgs: [issue.id]);
  }

  static const _initialData = [
    Issue(
      id: '1',
      title: 'Calçada esburacada',
      description: 'Impossível passar com cadeira de rodas.',
      category: IssueCategory.accessibility,
      address: 'Av. Paulista, 1000 - SP',
      imageUrl: 'https://picsum.photos/seed/zelo1/400/240',
      likes: 35,
      activeRegionalUsers: 50,
      status: IssueStatus.collecting,
      latitude: -23.5614,
      longitude: -46.6559,
    ),
    Issue(
      id: '2',
      title: 'Poste sem luz',
      description: 'Escuridão total à noite, o que deixa a rua perigosa.',
      category: IssueCategory.safety,
      address: 'Rua Augusta, 500 - SP',
      imageUrl: 'https://picsum.photos/seed/zelo2/400/240',
      likes: 42,
      activeRegionalUsers: 50,
      status: IssueStatus.formal,
      latitude: -23.5534,
      longitude: -46.6509,
    ),
    Issue(
      id: '3',
      title: 'Falta de rampa de acesso',
      description: 'A praça não tem rampa para cadeirantes e carrinhos de bebê.',
      category: IssueCategory.accessibility,
      address: 'Praça da Sé - SP',
      imageUrl: 'https://picsum.photos/seed/zelo3/400/240',
      likes: 12,
      activeRegionalUsers: 40,
      status: IssueStatus.collecting,
      latitude: -23.5503,
      longitude: -46.6339,
    ),
    Issue(
      id: '4',
      title: 'Buraco na avenida',
      description: 'Buraco grande no meio da pista, risco de acidentes.',
      category: IssueCategory.infrastructure,
      address: 'Av. Pedro Álvares Cabral - SP',
      imageUrl: 'https://picsum.photos/seed/zelo4/400/240',
      likes: 20,
      activeRegionalUsers: 60,
      status: IssueStatus.collecting,
      latitude: -23.5874,
      longitude: -46.6576,
    ),
  ];
}
