class AppUser {
  AppUser({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.fechaNacimiento,
    required this.pj,
    required this.goles,
    required this.asistencias,
    required this.valoracion,
    required this.posicion,
    required this.fotoUrl,
    required this.totalEstrellas,
    required this.votosRecibidos,
  });

  final String id;
  final String nombre;
  final String correo;
  final String fechaNacimiento;
  final int pj;
  final int goles;
  final int asistencias;
  final double valoracion;
  final String posicion;
  final String fotoUrl;
  final double totalEstrellas;
  final int votosRecibidos;

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      nombre: (data['nombre'] as String?) ?? 'Jugador',
      correo: (data['correo'] as String?) ?? '',
      fechaNacimiento: (data['fechaNacimiento'] as String?) ?? '',
      pj: (data['pj'] as num?)?.toInt() ?? 0,
      goles: (data['goles'] as num?)?.toInt() ?? 0,
      asistencias: (data['asistencias'] as num?)?.toInt() ?? 0,
      valoracion: (data['valoracion'] as num?)?.toDouble() ?? 0,
      posicion: (data['posicion'] as String?) ?? 'Sin definir',
      fotoUrl: (data['fotoUrl'] as String?) ?? '',
      totalEstrellas: (data['totalEstrellas'] as num?)?.toDouble() ?? 0,
      votosRecibidos: (data['votosRecibidos'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'fechaNacimiento': fechaNacimiento,
      'pj': pj,
      'goles': goles,
      'asistencias': asistencias,
      'valoracion': valoracion,
      'posicion': posicion,
      'fotoUrl': fotoUrl,
      'totalEstrellas': totalEstrellas,
      'votosRecibidos': votosRecibidos,
    };
  }
}
