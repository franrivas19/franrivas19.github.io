bool isMatchStarted(String fecha, String hora) {
  try {
    final now = DateTime.now();
    final ddmm = fecha.split('/');
    final hhmm = hora.split(':');
    if (ddmm.length != 2 || hhmm.length != 2) {
      return false;
    }

    var year = now.year;
    final month = int.parse(ddmm[1]);
    if (now.month == 12 && month == 1) {
      year += 1;
    }

    final date = DateTime(
      year,
      month,
      int.parse(ddmm[0]),
      int.parse(hhmm[0]),
      int.parse(hhmm[1]),
    );

    return now.isAfter(date) || now.isAtSameMomentAs(date);
  } catch (_) {
    return false;
  }
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
