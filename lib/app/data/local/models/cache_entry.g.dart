// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final int typeId = 0;

  @override
  CacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheEntry(
      key: fields[0] as String,
      path: fields[1] as String,
      queryParams: (fields[2] as Map).cast<String, dynamic>(),
      responseData: (fields[3] as Map).cast<String, dynamic>(),
      statusCode: fields[4] as int,
      cachedAt: fields[5] as DateTime,
      expiresAt: fields[6] as DateTime,
      headers: (fields[7] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.queryParams)
      ..writeByte(3)
      ..write(obj.responseData)
      ..writeByte(4)
      ..write(obj.statusCode)
      ..writeByte(5)
      ..write(obj.cachedAt)
      ..writeByte(6)
      ..write(obj.expiresAt)
      ..writeByte(7)
      ..write(obj.headers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
