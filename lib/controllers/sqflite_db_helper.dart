// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Databasehelper {
  static const _databasename = "health.db";
  static const _databaseversion = 1;

  static const table = "medicinedatabase";

  // Columns
  static const columnID = 'id';
  static const columnMedicineName = "medicineName";
  static const columnMedicinePrice = "medicinePrice";
  static const columnQuantity = "quantity";
  static const columnNote = "note";
  static const columnCritical = "critical";

  static Database? _database;

  // Singleton constructor
  Databasehelper._privateConstructor();
  static final Databasehelper instance = Databasehelper._privateConstructor();

  // Correct getter name → database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize DB
  Future<Database> _initDatabase() async {
    Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, _databasename);

    return await openDatabase(
      path,
      version: _databaseversion,
      onCreate: _onCreate,
    );
  }

  // Create table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnID INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnMedicineName TEXT NOT NULL,
        $columnMedicinePrice INTEGER NOT NULL,
        $columnQuantity INTEGER NOT NULL,
        $columnNote TEXT NOT NULL,
        $columnCritical INTEGER NOT NULL
      );
    ''');
  }

  // Insert
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Query all
  Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // Delete
  Future<int> deleteData(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: "$columnID = ?", whereArgs: [id]);
  }
}
