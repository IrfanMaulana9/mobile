import 'package:hive/hive.dart';
import '../models/hive_models.dart';

/// Updated adapter - removed bookingId field dependency, standalone notes only
class HiveNoteAdapter extends TypeAdapter<HiveNote> {
  @override
  final int typeId = 3;

  @override
  HiveNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }
    return HiveNote(
      id: fields[0] as String? ?? '',
      userId: fields[1] as String? ?? '',
      title: fields[2] as String? ?? '',
      content: fields[3] as String? ?? '',
      createdAt: fields[4] as DateTime? ?? DateTime.now(),
      updatedAt: fields[5] as DateTime?,
      synced: fields[6] as bool? ?? false,
      supabaseId: fields[7] as String?,
      imageUrls: fields[8] as List<String>? ?? [],
      localImagePaths: fields[9] as List<String>? ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, HiveNote obj) {
    writer.writeByte(10);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.userId);
    writer.writeByte(2);
    writer.write(obj.title);
    writer.writeByte(3);
    writer.write(obj.content);
    writer.writeByte(4);
    writer.write(obj.createdAt);
    writer.writeByte(5);
    writer.write(obj.updatedAt);
    writer.writeByte(6);
    writer.write(obj.synced);
    writer.writeByte(7);
    writer.write(obj.supabaseId);
    writer.writeByte(8);
    writer.write(obj.imageUrls);
    writer.writeByte(9);
    writer.write(obj.localImagePaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}