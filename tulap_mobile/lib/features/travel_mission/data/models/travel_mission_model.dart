import 'dart:convert';
import '../../domain/entities/travel_mission_entity.dart';

class TravelMissionModel extends TravelMissionEntity {
  const TravelMissionModel({
    required super.id,
    required super.displayId,
    required super.userId,
    super.organizationId,
    required super.assignmentLetterNumber,
    required super.assignmentLetterDate,
    required super.title,
    required super.purpose,
    required super.origin,
    required super.destination,
    super.destinations,
    required super.departureDate,
    required super.returnDate,
    required super.transportMode,
    super.transportDetails,
    required super.status,
    required super.budgetEstimate,
    super.notes,
    required super.personnelSnapshot,
    super.syncStatus,
    required super.createdAt,
    super.updatedAt,
  });

  factory TravelMissionModel.fromEntity(TravelMissionEntity entity) {
    return TravelMissionModel(
      id: entity.id,
      displayId: entity.displayId,
      userId: entity.userId,
      organizationId: entity.organizationId,
      assignmentLetterNumber: entity.assignmentLetterNumber,
      assignmentLetterDate: entity.assignmentLetterDate,
      title: entity.title,
      purpose: entity.purpose,
      origin: entity.origin,
      destination: entity.destination,
      destinations: entity.destinations,
      departureDate: entity.departureDate,
      returnDate: entity.returnDate,
      transportMode: entity.transportMode,
      transportDetails: entity.transportDetails,
      status: entity.status,
      budgetEstimate: entity.budgetEstimate,
      notes: entity.notes,
      personnelSnapshot: entity.personnelSnapshot,
      syncStatus: entity.syncStatus,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory TravelMissionModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedDestinations = [];
    if (json['destinations'] != null) {
      if (json['destinations'] is List) {
        parsedDestinations = (json['destinations'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['destinations'] is String &&
          (json['destinations'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['destinations'] as String);
          if (decoded is List) {
            parsedDestinations = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }

    TravelBudgetEstimate budget = const TravelBudgetEstimate();
    if (json['budgetEstimate'] != null) {
      if (json['budgetEstimate'] is Map<String, dynamic>) {
        budget = TravelBudgetEstimate.fromJson(json['budgetEstimate']);
      } else if (json['budgetEstimate'] is String &&
          (json['budgetEstimate'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['budgetEstimate'] as String);
          budget = TravelBudgetEstimate.fromJson(decoded);
        } catch (_) {}
      }
    }

    TravelPersonnelSnapshot personnel = const TravelPersonnelSnapshot(
      fullName: 'Petugas Lapangan',
    );
    if (json['personnelSnapshot'] != null) {
      if (json['personnelSnapshot'] is Map<String, dynamic>) {
        personnel = TravelPersonnelSnapshot.fromJson(json['personnelSnapshot']);
      } else if (json['personnelSnapshot'] is String &&
          (json['personnelSnapshot'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(json['personnelSnapshot'] as String);
          personnel = TravelPersonnelSnapshot.fromJson(decoded);
        } catch (_) {}
      }
    }

    return TravelMissionModel(
      id: json['id'] as String,
      displayId: json['displayId'] as String? ?? 'PD-20260828-0000',
      userId: json['userId'] as String? ?? '',
      organizationId: json['organizationId'] as String?,
      assignmentLetterNumber: json['assignmentLetterNumber'] as String? ?? '',
      assignmentLetterDate: json['assignmentLetterDate'] != null
          ? DateTime.parse(json['assignmentLetterDate'] as String)
          : DateTime.now(),
      title: json['title'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      origin: json['origin'] as String? ?? 'Timika',
      destination: json['destination'] as String? ?? '',
      destinations: parsedDestinations,
      departureDate: json['departureDate'] != null
          ? DateTime.parse(json['departureDate'] as String)
          : DateTime.now(),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'] as String)
          : DateTime.now(),
      transportMode: TravelTransportMode.fromString(
        json['transportMode'] as String?,
      ),
      transportDetails: json['transportDetails'] as String?,
      status: TravelMissionStatus.fromString(json['status'] as String?),
      budgetEstimate: budget,
      notes: json['notes'] as String?,
      personnelSnapshot: personnel,
      syncStatus: json['syncStatus'] as String? ?? 'LOCAL_ONLY',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'displayId': displayId,
      'userId': userId,
      'organizationId': organizationId,
      'assignmentLetterNumber': assignmentLetterNumber,
      'assignmentLetterDate': assignmentLetterDate.toIso8601String(),
      'title': title,
      'purpose': purpose,
      'origin': origin,
      'destination': destination,
      'destinations': jsonEncode(destinations),
      'departureDate': departureDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'transportMode': transportMode.name,
      'transportDetails': transportDetails,
      'status': status.name,
      'budgetEstimate': jsonEncode(budgetEstimate.toJson()),
      'notes': notes,
      'personnelSnapshot': jsonEncode(personnelSnapshot.toJson()),
      'syncStatus': syncStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toApiPayload() {
    return {
      'id': id,
      'displayId': displayId,
      'assignmentLetterNumber': assignmentLetterNumber,
      'assignmentLetterDate': assignmentLetterDate.toIso8601String(),
      'title': title,
      'purpose': purpose,
      'origin': origin,
      'destination': destination,
      'destinations': destinations,
      'departureDate': departureDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'transportMode': transportMode.name.toUpperCase(),
      'transportDetails': transportDetails,
      'status': status.name.toUpperCase(),
      'budgetEstimate': budgetEstimate.toJson(),
      'notes': notes,
      'personnelSnapshot': personnelSnapshot.toJson(),
    };
  }
}
