import 'package:lexor_desktop/models/attendance_response.dart';
import 'package:lexor_desktop/providers/base_provider.dart';

class AttendanceProvider extends BaseProvider<AttendanceResponse> {
  AttendanceProvider() : super('Attendances');

  @override
  AttendanceResponse fromJson(dynamic data) => AttendanceResponse.fromJson(data);
}
