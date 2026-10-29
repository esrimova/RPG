/// Activity field types for telemetry configuration
enum ActivityFieldType {
  integer('integer'),
  seconds('seconds'),
  slider1to10('slider_1_10'),
  boolean('boolean'),
  text('text');

  const ActivityFieldType(this.value);
  final String value;

  static ActivityFieldType fromString(String value) {
    return ActivityFieldType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityFieldType.integer,
    );
  }
}

/// Represents a configurable field for an activity
class ActivityField {
  final String id;
  final String name;
  final ActivityFieldType type;
  final String? unit;
  final bool required;
  final int? minValue;
  final int? maxValue;
  final double? step;
  final String? placeholder;
  final Map<String, dynamic>? validation;

  const ActivityField({
    required this.id,
    required this.name,
    required this.type,
    this.unit,
    this.required = true,
    this.minValue,
    this.maxValue,
    this.step,
    this.placeholder,
    this.validation,
  });

  /// Creates a copy with updated fields
  ActivityField copyWith({
    String? id,
    String? name,
    ActivityFieldType? type,
    String? unit,
    bool? required,
    int? minValue,
    int? maxValue,
    double? step,
    String? placeholder,
    Map<String, dynamic>? validation,
  }) {
    return ActivityField(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      required: required ?? this.required,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      step: step ?? this.step,
      placeholder: placeholder ?? this.placeholder,
      validation: validation ?? this.validation,
    );
  }

  /// Serializes to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      if (unit != null) 'unit': unit,
      'required': required,
      if (minValue != null) 'min_value': minValue,
      if (maxValue != null) 'max_value': maxValue,
      if (step != null) 'step': step,
      if (placeholder != null) 'placeholder': placeholder,
      if (validation != null) 'validation': validation,
    };
  }

  /// Deserializes from JSON
  factory ActivityField.fromJson(Map<String, dynamic> json) {
    return ActivityField(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ActivityFieldType.fromString(json['type'] as String),
      unit: json['unit'] as String?,
      required: json['required'] as bool? ?? true,
      minValue: json['min_value'] as int?,
      maxValue: json['max_value'] as int?,
      step: (json['step'] as num?)?.toDouble(),
      placeholder: json['placeholder'] as String?,
      validation: json['validation'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityField &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          unit == other.unit &&
          required == other.required &&
          minValue == other.minValue &&
          maxValue == other.maxValue &&
          step == other.step &&
          placeholder == other.placeholder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        unit,
        required,
        minValue,
        maxValue,
        step,
        placeholder,
      );

  @override
  String toString() =>
      'ActivityField(id: $id, name: $name, type: $type, required: $required)';
}