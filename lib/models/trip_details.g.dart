// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_details.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripDetailsAdapter extends TypeAdapter<TripDetails> {
  @override
  final int typeId = 4;

  @override
  TripDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripDetails(
      id: fields[0] as String,
      destinationName: fields[1] as String,
      description: fields[2] as String,
      region: fields[3] as String,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      createdAt: fields[6] as DateTime,
      startDate: fields[7] as DateTime?,
      endDate: fields[8] as DateTime?,
      attractions: (fields[9] as List).cast<String>(),
      status: fields[10] as String,
      coverImage: fields[11] as String?,
      journalEntriesCount: fields[12] as int,
      hasOfflineMaps: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TripDetails obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.destinationName)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.region)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.attractions)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.coverImage)
      ..writeByte(12)
      ..write(obj.journalEntriesCount)
      ..writeByte(13)
      ..write(obj.hasOfflineMaps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
