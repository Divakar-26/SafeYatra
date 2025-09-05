import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final String email;   // 👈 add this

  const SetupScreen({
    super.key,
    required this.email,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}




class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _emergencyNumberController = TextEditingController();
  final TextEditingController _medicalConditionsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Teal accent used across AuthScreen
  Color get _accent => Colors.tealAccent.shade400;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _mobileNumberController.dispose();
    _aadharController.dispose();
    _passportController.dispose();
    _emergencyNumberController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: const BoxDecoration(
          // Match AuthScreen gradient
          gradient: LinearGradient(
            colors: [Color(0xFF0E1A24), Color(0xFF162534)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Soft background orbs
            Positioned(
              top: -size.width * 0.25,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.35,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.85,
                height: size.width * 0.85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_add_alt_1,
                              size: 60,
                              color: Colors.white.withOpacity(0.92),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Complete Your Profile',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Help us personalize your experience',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Stepper in dark theme with teal accent
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: _accent,
                              brightness: Brightness.dark,
                            ),
                            scaffoldBackgroundColor: Colors.transparent,
                            canvasColor: Colors.transparent,
                            dividerColor: Colors.white.withOpacity(0.18),
                            textTheme: Theme.of(context).textTheme.apply(
                                  bodyColor: Colors.white,
                                  displayColor: Colors.white,
                                ),
                          ),
                          child: Stepper(
                            currentStep: _currentStep,
                            onStepContinue: _continue,
                            onStepCancel: _cancel,
                            onStepTapped: (step) => setState(() => _currentStep = step),
                            controlsBuilder: (context, details) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Row(
                                  children: [
                                    if (_currentStep > 0)
                                      ElevatedButton(
                                        onPressed: details.onStepCancel,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white.withOpacity(0.08),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 14,
                                          ),
                                        ),
                                        child: const Text('Back'),
                                      ),
                                    if (_currentStep > 0) const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: details.onStepContinue,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _accent,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 14,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : Text(_currentStep == 3 ? 'Complete' : 'Next'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            steps: [
                              Step(
                                title: const Text(
                                  'Personal Info',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                content: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2A3A).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _nameController,
                                        label: 'Full Name',
                                        icon: Icons.person_outline,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDropdownField(
                                        controller: _genderController,
                                        label: 'Gender',
                                        icon: Icons.transgender,
                                        items: const ['Male', 'Female', 'Other'],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please select your gender';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _ageController,
                                        label: 'Age',
                                        icon: Icons.calendar_today_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your age';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Please enter a valid age';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Step(
                                title: const Text(
                                  'Contact Info',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                content: Container
                                  (
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2A3A).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _mobileNumberController,
                                        label: 'Mobile Number',
                                        icon: Icons.phone,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your mobile number';
                                          }
                                          if (value.length != 10) {
                                            return 'Mobile number must be 10 digits';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _emergencyNumberController,
                                        label: 'Emergency Contact',
                                        icon: Icons.emergency_outlined,
                                        keyboardType: TextInputType.phone,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter emergency contact';
                                          }
                                          if (value.length != 10) {
                                            return 'Emergency number must be 10 digits';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Step(
                                title: const Text(
                                  'Identification',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                content: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2A3A).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _aadharController,
                                        label: 'Aadhar Number',
                                        icon: Icons.credit_card_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(12),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your Aadhar number';
                                          }
                                          if (value.length != 12) {
                                            return 'Aadhar must be 12 digits';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _passportController,
                                        label: 'Passport Number (optional)',
                                        icon: Icons.airplane_ticket_outlined,
                                        validator: (value) {
                                          // Optional
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Step(
                                title: const Text(
                                  'Health Info',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                content: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C2A3A).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _medicalConditionsController,
                                        label: 'Medical Conditions (optional)',
                                        icon: Icons.medical_services_outlined,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _allergiesController,
                                        label: 'Allergies (optional)',
                                        icon: Icons.warning_outlined,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dark-styled inputs
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.72)),
        prefixIcon: Icon(icon, color: Colors.tealAccent.withOpacity(0.8)),
        filled: true,
        fillColor: const Color(0xFF223346),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      dropdownColor: const Color(0xFF223346),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.72)),
        prefixIcon: Icon(icon, color: Colors.tealAccent.withOpacity(0.8)),
        filled: true,
        fillColor: const Color(0xFF223346),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.22)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      items: items
          .map(
            (value) => DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: (value) {
        controller.text = value ?? '';
      },
      validator: validator,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
    );
  }

  void _continue() {
    if (_currentStep < 3) {
      bool isValid = true;
      switch (_currentStep) {
        case 0:
          if (_nameController.text.isEmpty ||
              _genderController.text.isEmpty ||
              _ageController.text.isEmpty ||
              int.tryParse(_ageController.text) == null) {
            isValid = false;
          }
          break;
        case 1:
          if (_mobileNumberController.text.isEmpty ||
              _mobileNumberController.text.length != 10 ||
              _emergencyNumberController.text.isEmpty ||
              _emergencyNumberController.text.length != 10) {
            isValid = false;
          }
          break;
        case 2:
          if (_aadharController.text.isEmpty ||
              _aadharController.text.length != 12) {
            isValid = false;
          }
          break;
      }

      if (isValid) {
        setState(() => _currentStep += 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill all required fields correctly'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      _submitSetup();
    }
  }

  void _cancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

    void _submitSetup() async {
    // validation logic stays same ...

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.setupUser(
      widget.email,   // ✅ use email now
      _nameController.text,
      _genderController.text,
      int.parse(_ageController.text),
      _mobileNumberController.text,
      _aadharController.text,
      _passportController.text,
      _emergencyNumberController.text,
      _medicalConditionsController.text,
      _allergiesController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            email: widget.email,
            name: widget.email, // fallback until profile fetch updates it
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

}
