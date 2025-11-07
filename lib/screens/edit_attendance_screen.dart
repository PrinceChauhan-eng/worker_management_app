import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/login_status.dart';
import '../providers/login_status_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EditAttendanceScreen extends StatefulWidget {
  final LoginStatus loginStatus;
  final String workerName;

  const EditAttendanceScreen({
    super.key,
    required this.loginStatus,
    required this.workerName,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _loginTimeController;
  late TextEditingController _logoutTimeController;
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.loginStatus.date);
    _loginTimeController =
        TextEditingController(text: widget.loginStatus.loginTime ?? '');
    _logoutTimeController =
        TextEditingController(text: widget.loginStatus.logoutTime ?? '');
    _isLoggedIn = widget.loginStatus.isLoggedIn;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _loginTimeController.dispose();
    _logoutTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.parse(widget.loginStatus.date);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectLoginTime(BuildContext context) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    if ((widget.loginStatus.loginTime ?? '').isNotEmpty) {
      try {
        final parts = widget.loginStatus.loginTime!.split(':');
        initialTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

    final picked =
        await showTimePicker(context: context, initialTime: initialTime);

    if (picked != null) {
      setState(() {
        _loginTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      });
    }
  }

  Future<void> _selectLogoutTime(BuildContext context) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 17, minute: 0);
    if ((widget.loginStatus.logoutTime ?? '').isNotEmpty) {
      try {
        final parts = widget.loginStatus.logoutTime!.split(':');
        initialTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

    final picked =
        await showTimePicker(context: context, initialTime: initialTime);

    if (picked != null) {
      setState(() {
        _logoutTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_formKey.currentState!.validate()) {
      try {
        final loginStatusProvider =
            Provider.of<LoginStatusProvider>(context, listen: false);

        final updatedLoginStatus = LoginStatus(
          id: widget.loginStatus.id,
          workerId: widget.loginStatus.workerId,
          date: _dateController.text,
          loginTime:
              _loginTimeController.text.isNotEmpty ? _loginTimeController.text : null,
          logoutTime:
              _logoutTimeController.text.isNotEmpty ? _logoutTimeController.text : null,
          isLoggedIn: _isLoggedIn,
        );

        await loginStatusProvider.updateLoginStatus(updatedLoginStatus);

        Fluttertoast.showToast(
          msg: 'Attendance updated successfully!',
          backgroundColor: Colors.green,
        );

        Navigator.pop(context, true);
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Failed to update attendance: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Edit Attendance',
        onLeadingPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Attendance for ${widget.workerName}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Modify attendance details',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 30),

                // DATE
                _buildContainer(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _dateController,
                        labelText: 'Date',
                        hintText: 'Select date',
                        prefixIcon: Icons.calendar_today,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Please select a date' : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // LOGIN TIME
                _buildContainer(
                  child: GestureDetector(
                    onTap: () => _selectLoginTime(context),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _loginTimeController,
                        labelText: 'Login Time',
                        hintText: 'Select login time',
                        prefixIcon: Icons.login,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // LOGOUT TIME
                _buildContainer(
                  child: GestureDetector(
                    onTap: () => _selectLogoutTime(context),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _logoutTimeController,
                        labelText: 'Logout Time',
                        hintText: 'Select logout time',
                        prefixIcon: Icons.logout,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // SWITCH
                _buildContainer(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currently Logged In',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: _isLoggedIn,
                        onChanged: (v) => setState(() => _isLoggedIn = v),
                        activeThumbColor: const Color(0xFF4CAF50),
                        activeTrackColor:
                            const Color(0xFF4CAF50).withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                CustomButton(
                  text: 'Save Changes',
                  onPressed: _saveAttendance,
                  color: const Color(0xFF1E88E5),
                  textColor: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper Widget for cards
  Widget _buildContainer({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
