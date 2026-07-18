/// room_model.dart
/// Model untuk ruangan/workspace bersama (Sharing feature)
library;

class RoomModel {
  final String id;
  final String ownerId;
  final String roomCode;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final List<RoomMember> members;

  const RoomModel({
    required this.id,
    required this.ownerId,
    required this.roomCode,
    required this.name,
    this.isActive = true,
    required this.createdAt,
    this.members = const [],
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      roomCode: json['room_code'] as String? ?? '',
      name: json['name'] as String? ?? 'Dompet Bersama',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      members: (json['room_members'] as List?)
              ?.map((m) => RoomMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'room_code': roomCode,
    'name': name,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

class RoomMember {
  final int? id;
  final String roomId;
  final String userId;
  final String role;
  final String? email;
  final DateTime joinedAt;

  const RoomMember({
    this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    this.email,
    required this.joinedAt,
  });

  bool get isOwner => role == 'owner';

  factory RoomMember.fromJson(Map<String, dynamic> json) {
    return RoomMember(
      id: json['id'] as int?,
      roomId: json['room_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      email: json['profiles'] != null
          ? (json['profiles'] as Map<String, dynamic>)['email'] as String?
          : null,
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
