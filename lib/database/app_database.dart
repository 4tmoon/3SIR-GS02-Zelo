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
    return openDatabase(path, version: 4, onCreate: _onCreate, onUpgrade: _onUpgrade);
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
        supported INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER,
        reachedAt INTEGER,
        noticeGeneratedAt INTEGER,
        decisionAt INTEGER,
        decision TEXT
      )
    ''');
    for (final issue in _initialData()) {
      await db.insert('issues', issue.toMap());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE issues ADD COLUMN supported INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      for (final column in [
        'createdAt INTEGER',
        'reachedAt INTEGER',
        'noticeGeneratedAt INTEGER',
        'decisionAt INTEGER',
        'decision TEXT',
      ]) {
        await db.execute('ALTER TABLE issues ADD COLUMN $column');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final rows = await db.query('issues');
      for (final row in rows) {
        final id = row['id'] as String;
        final parsed = int.tryParse(id) ?? 0;
        final created = parsed > 1000000000000 ? parsed : now;
        final hasNotice = row['status'] == IssueStatus.formal;
        await db.update(
          'issues',
          {
            'createdAt': created,
            'reachedAt': hasNotice ? now : null,
            'noticeGeneratedAt': hasNotice ? now : null,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    if (oldVersion < 4) {
      await db.update(
        'issues',
        {'decision': null, 'decisionAt': null, 'status': IssueStatus.formal},
        where: 'decision = ?',
        whereArgs: ['rejected'],
      );
      for (final issue in _initialData()) {
        await db.insert('issues', issue.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<int> insert(Issue issue) async {
    final db = await database;
    return db.insert('issues', issue.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Mais recentes primeiro (pela data de criação).
  Future<List<Issue>> getAll() async {
    final db = await database;
    final rows = await db.query('issues', orderBy: 'COALESCE(createdAt, CAST(id AS INTEGER)) DESC');
    return rows.map(Issue.fromMap).toList();
  }

  Future<int> update(Issue issue) async {
    final db = await database;
    return db.update('issues', issue.toMap(), where: 'id = ?', whereArgs: [issue.id]);
  }

  List<Issue> _initialData() {
    final now = DateTime.now();
    DateTime days(int n) => now.subtract(Duration(days: n));

    Issue seed({
      required String id,
      required String title,
      required String description,
      required String category,
      required String address,
      required int likes,
      required int active,
      required double lat,
      required double lng,
      required DateTime created,
      DateTime? reached,
      DateTime? accepted,
      required String imageName,
    }) {
      return Issue(
        id: id,
        title: title,
        description: description,
        category: category,
        address: address,
        imageUrl: 'assets/images/$imageName',
        likes: likes,
        activeRegionalUsers: active,
        status: accepted != null
            ? IssueStatus.accepted
            : (reached != null ? IssueStatus.formal : IssueStatus.collecting),
        latitude: lat,
        longitude: lng,
        createdAt: created,
        reachedAt: reached,
        noticeGeneratedAt: reached,
        decisionAt: accepted,
        decision: accepted != null ? IssueDecision.accepted : null,
      );
    }

    return [
      seed(
        id: '1',
        title: 'Calçada esburacada',
        description: 'Impossível passar com cadeira de rodas.',
        category: IssueCategory.accessibility,
        address: 'Av. Paulista, 1000 - SP',
        likes: 35, active: 50, lat: -23.5614, lng: -46.6559,
        created: days(3),
        imageName: 'calcada-com-buraco.jpg',
      ),
      seed(
        id: '3',
        title: 'Falta de rampa de acesso',
        description: 'A praça não tem rampa para cadeirantes e carrinhos de bebê.',
        category: IssueCategory.accessibility,
        address: 'Praça da Sé - SP',
        likes: 12, active: 40, lat: -23.5503, lng: -46.6339,
        created: days(2),
        imageName: 'sem-rampa-de-acesso.jpg',
      ),
      seed(
        id: '4',
        title: 'Buraco na avenida',
        description: 'Buraco grande no meio da pista, risco de acidentes.',
        category: IssueCategory.infrastructure,
        address: 'Av. Pedro Álvares Cabral - SP',
        likes: 20, active: 60, lat: -23.5874, lng: -46.6576,
        created: days(1),
        imageName: 'avenida-com-buraco.jpg',
      ),
      seed(
        id: '9',
        title: 'Ponto de ônibus sem cobertura',
        description: 'Os passageiros esperam o ônibus sem proteção contra sol e chuva.',
        category: IssueCategory.infrastructure,
        address: 'Av. Santo Amaro, 3000 - SP',
        likes: 8, active: 30, lat: -23.6076, lng: -46.6718,
        created: now.subtract(const Duration(hours: 5)),
        imageName: 'ponto-de-onibus.jpg',
      ),
      seed(
        id: '11',
        title: 'Praça sem iluminação',
        description: 'A praça fica totalmente escura à noite e os moradores evitam passar por ela.',
        category: IssueCategory.safety,
        address: 'Praça Roosevelt - SP',
        likes: 22, active: 50, lat: -23.5509, lng: -46.6504,
        created: days(4),
        imageName: 'poste-sem-luz.jpg',
      ),
      seed(
        id: '6',
        title: 'Bueiro entupido',
        description: 'A água da chuva não escoa e alaga a rua inteira.',
        category: IssueCategory.infrastructure,
        address: 'Rua da Consolação, 1500 - SP',
        likes: 41, active: 50, lat: -23.5527, lng: -46.6602,
        created: days(9),
        reached: days(2),
        imageName: 'bueiro-entupido.jpg',
      ),
      seed(
        id: '10',
        title: 'Escada sem corrimão',
        description: 'A escada de acesso ao metrô não tem corrimão, o que dificulta a subida de idosos.',
        category: IssueCategory.accessibility,
        address: 'Largo São Bento - SP',
        likes: 25, active: 30, lat: -23.5445, lng: -46.6338,
        created: days(8),
        reached: days(5),
        imageName: 'escada-sem-corrimao.jpg',
      ),
      seed(
        id: '2',
        title: 'Poste sem luz',
        description: 'Escuridão total à noite, o que deixa a rua perigosa.',
        category: IssueCategory.safety,
        address: 'Rua Augusta, 500 - SP',
        likes: 42, active: 50, lat: -23.5534, lng: -46.6509,
        created: days(12),
        reached: days(6),
        accepted: days(2),
        imageName: 'poste-sem-luz.jpg',
      ),
      seed(
        id: '5',
        title: 'Semáforo com defeito',
        description: 'O semáforo fica piscando em amarelo e causa confusão no cruzamento.',
        category: IssueCategory.infrastructure,
        address: 'Av. Brigadeiro Faria Lima - SP',
        likes: 49, active: 60, lat: -23.5868, lng: -46.6820,
        created: days(20),
        reached: days(12),
        accepted: days(3),
        imageName: 'semaforo-quebrado.jpg',
      ),
      seed(
        id: '7',
        title: 'Faixa de pedestres apagada',
        description: 'A faixa de pedestres está desgastada e os motoristas não param.',
        category: IssueCategory.safety,
        address: 'Av. Rebouças, 2000 - SP',
        likes: 38, active: 45, lat: -23.5667, lng: -46.6728,
        created: days(30),
        reached: days(21),
        accepted: days(8),
        imageName: 'faixa-pedestre.jpg',
      ),
    ];
  }
}