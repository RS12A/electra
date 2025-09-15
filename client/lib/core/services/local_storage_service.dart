import 'package:hive/hive.dart';

abstract class LocalStorageService {
  Future<void> storeData(String box, String key, dynamic data);
  Future<T?> getData<T>(String box, String key);
  Future<void> removeData(String box, String key);
  Future<void> clearBox(String box);
  Future<List<T>> getAll<T>(String box);
}

class LocalStorageServiceImpl implements LocalStorageService {
  @override
  Future<void> storeData(String box, String key, dynamic data) async {
    final hiveBox = await Hive.openBox(box);
    await hiveBox.put(key, data);
  }

  @override
  Future<T?> getData<T>(String box, String key) async {
    final hiveBox = await Hive.openBox(box);
    return hiveBox.get(key) as T?;
  }

  @override
  Future<void> removeData(String box, String key) async {
    final hiveBox = await Hive.openBox(box);
    await hiveBox.delete(key);
  }

  @override
  Future<void> clearBox(String box) async {
    final hiveBox = await Hive.openBox(box);
    await hiveBox.clear();
  }

  @override
  Future<List<T>> getAll<T>(String box) async {
    final hiveBox = await Hive.openBox(box);
    return hiveBox.values.cast<T>().toList();
  }
}