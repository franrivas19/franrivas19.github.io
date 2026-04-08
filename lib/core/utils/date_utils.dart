DateTime? parseMatchDateTime(String fecha, String hora) {
  try {
    final now = DateTime.now();
    final normalizedDate = fecha.trim().replaceAll('-', '/');
    final dateParts = normalizedDate
        .split('/')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (dateParts.length < 2 || dateParts.length > 3) {
      return null;
    }

    int day;
    int month;
    int year;

    if (dateParts.first.length == 4) {
      year = int.parse(dateParts[0]);
      month = int.parse(dateParts[1]);
      day = int.parse(dateParts[2]);
    } else {
      day = int.parse(dateParts[0]);
      month = int.parse(dateParts[1]);
      if (dateParts.length == 3) {
        year = int.parse(dateParts[2]);
      } else {
        year = now.year;
      }
    }

    final normalizedTime = hora.trim();
    final timeParts = normalizedTime.split(':');
    final hour = timeParts.isNotEmpty && timeParts.first.isNotEmpty
        ? int.parse(timeParts[0])
        : 0;
    final minute = timeParts.length > 1 && timeParts[1].isNotEmpty
        ? int.parse(timeParts[1])
        : 0;

    return DateTime(year, month, day, hour, minute);
  } catch (_) {
    return null;
  }
}

bool isMatchStarted(String fecha, String hora) {
  final dt = parseMatchDateTime(fecha, hora);
  if (dt == null) {
    return false;
  }
  final now = DateTime.now();
  return now.isAfter(dt) || now.isAtSameMomentAs(dt);
}

Duration? timeUntilMatch(String fecha, String hora) {
  final dt = parseMatchDateTime(fecha, hora);
  if (dt == null) {
    return null;
  }
  return dt.difference(DateTime.now());
}

int calculateAge(String ddmmyyyy) {
  try {
    final parts = ddmmyyyy.split('/');
    if (parts.length != 3) {
      return 0;
    }
    final birth = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
    final now = DateTime.now();
    var age = now.year - birth.year;
    final hadBirthday =
        now.month > birth.month || (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) {
      age--;
    }
    return age;
  } catch (_) {
    return 0;
  }
}
