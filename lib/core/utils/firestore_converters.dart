/// Firestore type converters for DateTime <-> Timestamp.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firestore [Timestamp] to [DateTime].
///
/// Returns current time if [timestamp] is null.
DateTime timestampToDateTime(Timestamp? timestamp) {
  return timestamp?.toDate() ?? DateTime.now();
}

/// Converts [DateTime] to Firestore [Timestamp].
Timestamp dateTimeToTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}

/// Converts Firestore [Timestamp] to [DateTime], returns null if input is null.
DateTime? timestampToDateTimeNullable(Timestamp? timestamp) {
  return timestamp?.toDate();
}

/// Firestore server timestamp placeholder for create/update operations.
FieldValue get serverTimestamp => FieldValue.serverTimestamp();
