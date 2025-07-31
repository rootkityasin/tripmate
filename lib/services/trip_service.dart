import 'package:hive_flutter/hive_flutter.dart';
import '../models/trip_details.dart';

class TripService {
  static const String _boxName = 'trips';
  Box<TripDetails>? _tripsBox;

  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _tripsBox = await Hive.openBox<TripDetails>(_boxName);
    } else {
      _tripsBox = Hive.box<TripDetails>(_boxName);
    }
  }

  Future<void> addTrip(TripDetails trip) async {
    await _tripsBox?.put(trip.id, trip);
  }

  Future<void> updateTrip(TripDetails trip) async {
    await _tripsBox?.put(trip.id, trip);
  }

  Future<void> deleteTrip(String tripId) async {
    await _tripsBox?.delete(tripId);
  }

  List<TripDetails> getAllTrips() {
    return _tripsBox?.values.toList() ?? [];
  }

  List<TripDetails> getRecentTrips({int limit = 5}) {
    final allTrips = getAllTrips();
    allTrips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allTrips.take(limit).toList();
  }

  List<TripDetails> getCompletedTrips() {
    return getAllTrips().where((trip) => trip.isCompleted).toList();
  }

  List<TripDetails> getActiveTrips() {
    return getAllTrips().where((trip) => trip.isActive).toList();
  }

  List<TripDetails> getPlannedTrips() {
    return getAllTrips().where((trip) => trip.isPlanned).toList();
  }

  TripDetails? getTripById(String id) {
    return _tripsBox?.get(id);
  }

  Future<void> updateJournalCount(String tripId, int count) async {
    final trip = getTripById(tripId);
    if (trip != null) {
      trip.journalEntriesCount = count;
      await updateTrip(trip);
    }
  }

  Future<void> markTripAsActive(String tripId) async {
    final trip = getTripById(tripId);
    if (trip != null) {
      trip.status = 'active';
      await updateTrip(trip);
    }
  }

  Future<void> markTripAsCompleted(String tripId) async {
    final trip = getTripById(tripId);
    if (trip != null) {
      trip.status = 'completed';
      await updateTrip(trip);
    }
  }
}
