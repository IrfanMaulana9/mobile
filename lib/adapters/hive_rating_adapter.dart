import 'package:hive/hive.dart';
import '../models/hive_models.dart';

/// Manual adapter for HiveRatingReview
class HiveRatingReviewAdapter extends TypeAdapter<HiveRatingReview> {
  @override
  final int typeId = 4;

  @override
  HiveRatingReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }
    return HiveRatingReview(
      id: fields[0] as String? ?? '',
      bookingId: fields[1] as String? ?? '',
      userId: fields[2] as String? ?? '',
      customerName: fields[3] as String? ?? '',
      serviceName: fields[4] as String? ?? '',
      rating: fields[5] as int? ?? 0,
      review: fields[6] as String? ?? '',
      createdAt: fields[7] as DateTime? ?? DateTime.now(),
      updatedAt: fields[8] as DateTime? ?? DateTime.now(),
      synced: fields[9] as bool? ?? false,
      supabaseId: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveRatingReview obj) {
    writer.writeByte(11);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.bookingId);
    writer.writeByte(2);
    writer.write(obj.userId);
    writer.writeByte(3);
    writer.write(obj.customerName);
    writer.writeByte(4);
    writer.write(obj.serviceName);
    writer.writeByte(5);
    writer.write(obj.rating);
    writer.writeByte(6);
    writer.write(obj.review);
    writer.writeByte(7);
    writer.write(obj.createdAt);
    writer.writeByte(8);
    writer.write(obj.updatedAt);
    writer.writeByte(9);
    writer.write(obj.synced);
    writer.writeByte(10);
    writer.write(obj.supabaseId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveRatingReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

