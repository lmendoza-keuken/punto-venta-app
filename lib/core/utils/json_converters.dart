int? convertToInt(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is String) {
    return int.tryParse(value);
  } else if (value is int) {
    return value;
  } else if (value is double) {
    return value.toInt();
  } else {
    return null;
  }
}
