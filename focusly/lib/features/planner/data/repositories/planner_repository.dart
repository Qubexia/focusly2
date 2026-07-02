import '../datasources/planner_remote_datasource.dart';
import '../models/planned_item_model.dart';

class PlannerRepository {
  final PlannerRemoteDataSource _remoteDataSource;

  PlannerRepository({PlannerRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? PlannerRemoteDataSource();

  Future<List<PlannedItemModel>> getItems({
    required PlannedItemType type,
    String? from,
    String? to,
    String? subjectId,
  }) {
    return _remoteDataSource.getItems(
      type: type,
      from: from,
      to: to,
      subjectId: subjectId,
    );
  }

  Future<PlannedItemModel> createItem({
    required PlannedItemType type,
    required String title,
    String? notes,
    required String plannedAt,
    String? subjectId,
    int? reminderMinutesBefore,
    bool reminderEnabled = true,
  }) {
    return _remoteDataSource.createItem(
      type: type,
      title: title,
      notes: notes,
      plannedAt: plannedAt,
      subjectId: subjectId,
      reminderMinutesBefore: reminderMinutesBefore,
      reminderEnabled: reminderEnabled,
    );
  }

  Future<PlannedItemModel> updateItem({
    required PlannedItemType type,
    required String id,
    String? title,
    String? notes,
    String? plannedAt,
    String? subjectId,
    bool? completed,
  }) {
    return _remoteDataSource.updateItem(
      type: type,
      id: id,
      title: title,
      notes: notes,
      plannedAt: plannedAt,
      subjectId: subjectId,
      completed: completed,
    );
  }

  Future<PlannedItemModel> completeItem({
    required PlannedItemType type,
    required String id,
  }) {
    return _remoteDataSource.completeItem(type: type, id: id);
  }

  Future<void> deleteItem({
    required PlannedItemType type,
    required String id,
  }) {
    return _remoteDataSource.deleteItem(type: type, id: id);
  }
}
