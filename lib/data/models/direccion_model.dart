class DireccionModel {
  final String? id;
  final String usuarioId;
  final String nombre;
  final String direccion;
  final String? referencias;
  final double? latitud;
  final double? longitud;
  final bool esPredeterminada;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;

  DireccionModel({
    this.id,
    required this.usuarioId,
    required this.nombre,
    required this.direccion,
    this.referencias,
    this.latitud,
    this.longitud,
    this.esPredeterminada = false,
    required this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory DireccionModel.fromJson(Map<String, dynamic> json) {
    return DireccionModel(
      id: json['id']?.toString(),
      usuarioId: json['usuario_id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      referencias: json['referencias']?.toString(),
      latitud: json['latitud']?.toDouble(),
      longitud: json['longitud']?.toDouble(),
      esPredeterminada: json['es_predeterminada'] ?? false,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] ?? DateTime.now().toIso8601String()),
      fechaActualizacion: json['fecha_actualizacion'] != null 
          ? DateTime.parse(json['fecha_actualizacion']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'usuario_id': usuarioId,
      'nombre': nombre,
      'direccion': direccion,
      'referencias': referencias,
      'latitud': latitud,
      'longitud': longitud,
      'es_predeterminada': esPredeterminada,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
    
    // Solo incluir id si no es null (para actualizaciones)
    if (id != null) {
      json['id'] = id;
    }
    
    // Solo incluir fecha_actualizacion si no es null
    if (fechaActualizacion != null) {
      json['fecha_actualizacion'] = fechaActualizacion!.toIso8601String();
    }
    
    return json;
  }

  DireccionModel copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? direccion,
    String? referencias,
    double? latitud,
    double? longitud,
    bool? esPredeterminada,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return DireccionModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      referencias: referencias ?? this.referencias,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      esPredeterminada: esPredeterminada ?? this.esPredeterminada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return 'DireccionModel(id: $id, usuarioId: $usuarioId, nombre: $nombre, direccion: $direccion, esPredeterminada: $esPredeterminada)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DireccionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 