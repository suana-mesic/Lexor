import 'package:lexor_desktop/models/leave_response.dart';
import 'package:lexor_desktop/providers/base_provider.dart';

class LeaveProvider extends BaseProvider<LeaveResponse> {
  LeaveProvider() : super('Leaves');

  @override
  LeaveResponse fromJson(dynamic data) => LeaveResponse.fromJson(data);
}
