import 'package:cloud_firestore/cloud_firestore.dart';

DateTime timestampToDateTime(Timestamp? timestamp) {
  return timestamp?.toDate() ?? DateTime.now();
}

Timestamp dateTimeToTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}

DateTime? timestampToDateTimeNullable(Timestamp? timestamp) {
  return timestamp?.toDate();
}

FieldValue get serverTimestamp => FieldValue.serverTimestamp();
