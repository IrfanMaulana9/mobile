// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveBookingAdapter extends TypeAdapter<HiveBooking> {
  @override
  final int typeId = 0;

  @override
  HiveBooking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveBooking()
      ..id = fields[0] as String
      ..customerName = fields[1] as String
      ..phoneNumber = fields[2] as String
      ..serviceName = fields[3] as String
      ..latitude = fields[4] as double
      ..longitude = fields[5] as double
      ..address = fields[6] as String
      ..bookingDate = fields[7] as DateTime
      ..bookingTime = fields[8] as String
      ..totalPrice = fields[9] as double
      ..status = fields[10] as String
      ..createdAt = fields[11] as DateTime
      ..updatedAt = fields[12] as DateTime?
      ..synced = fields[13] as bool;
  }

  @override
  void write(BinaryWriter writer, HiveBooking obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerName)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.serviceName)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.bookingDate)
      ..writeByte(8)
      ..write(obj.bookingTime)
      ..writeByte(9)
      ..write(obj.totalPrice)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveBookingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveCachedWeatherAdapter extends TypeAdapter<HiveCachedWeather> {
  @override
  final int typeId = 1;

  @override
  HiveCachedWeather read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCachedWeather()
      ..locationKey = fields[0] as String
      ..temperature = fields[1] as double
      ..windSpeed = fields[2] as double
      ..rainProbability = fields[3] as int
      ..cachedAt = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, HiveCachedWeather obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.locationKey)
      ..writeByte(1)
      ..write(obj.temperature)
      ..writeByte(2)
      ..write(obj.windSpeed)
      ..writeByte(3)
      ..write(obj.rainProbability)
      ..writeByte(4)
      ..write(obj.cachedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCachedWeatherAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveLastLocationAdapter extends TypeAdapter<HiveLastLocation> {
  @override
  final int typeId = 2;

  @override
  HiveLastLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveLastLocation()
      ..latitude = fields[0] as double
      ..longitude = fields[1] as double
      ..address = fields[2] as String
      ..placeName = fields[3] as String?
      ..usedAt = fields[4] as DateTime;
  }

  @override
  void write(BinaryWriter writer, HiveLastLocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.placeName)
      ..writeByte(4)
      ..write(obj.usedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveLastLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
