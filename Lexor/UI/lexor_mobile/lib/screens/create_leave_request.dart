import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lexor_mobile/helpers/snackbar_helper.dart';
import 'package:lexor_mobile/models/leave_response.dart';
import 'package:lexor_mobile/models/leave_update_request.dart';
import 'package:lexor_mobile/providers/leave_provider.dart';
import 'package:lexor_mobile/providers/leave_type_provider.dart';
import 'package:provider/provider.dart';
import 'package:lexor_mobile/theme/app_colors.dart';

class CreateLeaveRequest extends StatefulWidget {
  final LeaveResponse? leave;
  const CreateLeaveRequest({super.key, this.leave});

  @override
  State<CreateLeaveRequest> createState() => _CreateLeaveRequestState();
}

class _CreateLeaveRequestState extends State<CreateLeaveRequest> {
  int? _selectedLeaveTypeId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.leave != null) {
      _selectedLeaveTypeId = widget.leave!.leaveType.id;
      _dateFrom = widget.leave!.dateFrom;
      _dateTo = widget.leave!.dateTo;
      _reasonController.text = widget.leave!.reason;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveTypeProvider>(context, listen: false).fetchLeaveTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveTypeProvider = Provider.of<LeaveTypeProvider>(
      context,
      listen: true,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildForm(leaveTypeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Nazad',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),
              Text(
                widget.leave == null ? 'Novi zahtjev' : 'Uredi zahtjev',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.notifications, color: Colors.white, size: 26),
              SizedBox(width: 16),
              Icon(Icons.person, color: Colors.white, size: 26),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm(LeaveTypeProvider leaveTypeProvider) {
    const labelStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    const fieldDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tip zahtjeva', style: labelStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            validator: (_) =>
                _selectedLeaveTypeId == null ? 'Odaberite tip zahtjeva' : null,
            initialValue: _selectedLeaveTypeId,
            hint: const Text('Odaberite tip zahtjeva'),
            decoration: fieldDecoration,
            items: leaveTypeProvider.leaveTypes
                .map(
                  (lt) => DropdownMenuItem(value: lt.id, child: Text(lt.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedLeaveTypeId = value),
          ),
          const SizedBox(height: 16),
          const Text('Datum od', style: labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            validator: (_) {
              if (_dateFrom == null) return 'Odaberite datum';
              if (_dateFrom!.isBefore(
                DateTime.now().subtract(const Duration(days: 1)),
              )) {
                return 'Datum mora biti danas ili u budućnosti';
              }
              return null;
            },
            readOnly: true,
            onTap: () => _pickDate(true),
            controller: TextEditingController(
              text: _dateFrom == null
                  ? ''
                  : DateFormat('dd.MM.yyyy').format(_dateFrom!),
            ),
            decoration: fieldDecoration.copyWith(
              hintText: 'Odaberite datum',
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Datum do', style: labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            validator: (_) {
              if (_dateTo == null) return "Odaberite datum";
              if (_dateFrom != null && _dateTo!.isBefore(_dateFrom!)) {
                return "Datum završetka mora biti nakon datuma početka";
              }
              return null;
            },
            readOnly: true,
            onTap: () => _pickDate(false),
            controller: TextEditingController(
              text: _dateTo == null
                  ? ''
                  : DateFormat('dd.MM.yyyy').format(_dateTo!),
            ),
            decoration: fieldDecoration.copyWith(
              hintText: 'Odaberite datum',
              suffixIcon: const Icon(
                Icons.calendar_month_outlined,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Razlog', style: labelStyle),
          const SizedBox(height: 8),
          TextFormField(
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Razlog je obavezan';
              }
              if (value.length > 1000) {
                return 'Razlog ne može imati više od 1000 karaktera';
              }
              return null;
            },
            controller: _reasonController,
            maxLines: 5,
            decoration: fieldDecoration.copyWith(
              hintText: 'Unesite razlog zahtjeva...',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.leave == null ? 'Pošalji zahtjev' : 'Sačuvaj promjene',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (widget.leave == null) {
                  try {
                    await Provider.of<LeaveProvider>(
                      context,
                      listen: false,
                    ).createLeave(
                      leaveTypeId: _selectedLeaveTypeId!,
                      dateFrom: _dateFrom!,
                      dateTo: _dateTo!,
                      reason: _reasonController.text,
                    );
                    SnackbarHelper.showSuccess(
                      context,
                      "Uspješno ste kreirali odsustvo!",
                    );
                    Navigator.pop(context, 'reload');
                  } catch (e) {
                    final message = e.toString().replaceFirst(
                      'Exception: ',
                      '',
                    );
                    SnackbarHelper.showError(context, message);
                  }
                } else {
                  try {
                    final LeaveUpdateRequest leaveUpdateRequest =
                        LeaveUpdateRequest(
                          leaveTypeId: _selectedLeaveTypeId,
                          dateFrom: _dateFrom,
                          dateTo: _dateTo,
                          reason: _reasonController.text,
                        );
                    var result = await Provider.of<LeaveProvider>(
                      context,
                      listen: false,
                    ).updateLeave(leaveUpdateRequest, widget.leave!.id);

                    SnackbarHelper.showSuccess(
                      context,
                      "Uspješno ste ažurirali odsustvo!",
                    );
                    Navigator.pop(context, 'reload');
                  } catch (e) {
                    final message = e.toString().replaceFirst(
                      "Exception: ",
                      "",
                    );
                    SnackbarHelper.showError(context, message);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
