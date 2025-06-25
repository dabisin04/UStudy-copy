class EstadoPsicologico {
  final String nivel;
  final String descripcion;

  EstadoPsicologico({
    required this.nivel,
    required this.descripcion,
  });

  factory EstadoPsicologico.fromMap(Map<String, dynamic> json) {
    return EstadoPsicologico(
      nivel: json['nivel'] ?? 'amarillo',
      descripcion: json['descripcion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nivel': nivel,
      'descripcion': descripcion,
    };
  }
}
