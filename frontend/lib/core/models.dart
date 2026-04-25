class AppUser {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final int? familyId;
  final String mood;
  final bool checkedOn;
  final bool inEmergency;

  AppUser({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.familyId,
    required this.mood,
    required this.checkedOn,
    required this.inEmergency,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final family = json['family'] as Map<String, dynamic>?;
    return AppUser(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      familyId: family?['id'],
      mood: json['mood'] ?? 'happy',
      checkedOn: json['checked_on'] ?? false,
      inEmergency: json['in_emergency'] ?? false,
    );
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) return firstName!;
    return username;
  }
}

class FamilyMember {
  final int id;
  final String username;
  final String? firstName;
  final String mood;
  final bool inEmergency;
  final double? latitude;
  final double? longitude;

  FamilyMember({
    required this.id,
    required this.username,
    this.firstName,
    required this.mood,
    required this.inEmergency,
    this.latitude,
    this.longitude,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final geotag = json['geotag'] as Map<String, dynamic>?;
    return FamilyMember(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      mood: json['mood'] ?? 'happy',
      inEmergency: json['in_emergency'] ?? false,
      latitude: geotag != null ? double.tryParse(geotag['latitude'].toString()) : null,
      longitude: geotag != null ? double.tryParse(geotag['longitude'].toString()) : null,
    );
  }

  String get displayName {
    if (firstName != null && firstName!.isNotEmpty) return firstName!;
    return username;
  }
}

class Medicine {
  final int id;
  final String name;
  final String? dosage;
  final String scheduledTime;
  final bool isOverdue;
  final String? skipMessage;
  final String? lastTakenAt;

  Medicine({
    required this.id,
    required this.name,
    this.dosage,
    required this.scheduledTime,
    required this.isOverdue,
    this.skipMessage,
    this.lastTakenAt,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      scheduledTime: json['scheduled_time'] ?? '',
      isOverdue: json['is_overdue'] ?? false,
      skipMessage: json['skip_message'],
      lastTakenAt: json['last_taken_at'],
    );
  }

  String get formattedScheduledTime {
    try {
      final parts = scheduledTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour % 12 == 0 ? 12 : hour % 12;
      return '$h:$minute $period';
    } catch (_) {
      return scheduledTime;
    }
  }

  bool get takenToday {
    if (lastTakenAt == null) return false;
    try {
      final taken = DateTime.parse(lastTakenAt!).toLocal();
      final now = DateTime.now();
      return taken.year == now.year &&
          taken.month == now.month &&
          taken.day == now.day;
    } catch (_) {
      return false;
    }
  }
}

class Reminder {
  final int id;
  final String title;
  final String? description;
  final String remindAt;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.remindAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      remindAt: json['remind_at'] ?? '',
    );
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(remindAt).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return remindAt;
    }
  }
}

class Note {
  final int id;
  final String creator;
  final String content;
  final String createdAt;

  Note({
    required this.id,
    required this.creator,
    required this.content,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      creator: json['creator']?.toString() ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }
}
