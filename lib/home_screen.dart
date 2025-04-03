import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import 'services/ai_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AIHandler _aiHandler = AIHandler();
  File? _image;
  late AnimationController _animationController;
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _isLoginMode = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // Add listeners to clear errors when user types
    _emailController.addListener(_clearEmailError);
    _passwordController.addListener(_clearPasswordError);
  }

  void _clearEmailError() {
    if (_emailError != null) {
      setState(() {
        _emailError = null;
      });
    }
  }

  void _clearPasswordError() {
    if (_passwordError != null) {
      setState(() {
        _passwordError = null;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleAuth() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _isLoading = true;
    });

    bool isValid = true;

    // Validate email
    if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      isValid = false;
    }

    // Validate password
    if (!_isValidPassword(_passwordController.text)) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters long';
      });
      isValid = false;
    }

    if (!isValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      bool success;
      if (_isLoginMode) {
        success = await _aiHandler.login(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        success = await _aiHandler.signUp(
          _emailController.text,
          _passwordController.text,
        );
        if (success) {
          success = await _aiHandler.login(
            _emailController.text,
            _passwordController.text,
          );
        }
      }

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _nameController.text);
        await prefs.setString('userEmail', _emailController.text);
        await prefs.setString('userPassword', _passwordController.text);
        if (_image != null) {
          await prefs.setString('userProfile', _image!.path);
        }
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLoginMode
                  ? 'Login failed. Please check your credentials.'
                  : 'Signup failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSocialLogin(Future<bool> Function() loginFunction) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await loginFunction();
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.secondary,
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      0.3 + 0.2 * _animationController.value,
                      0.7 - 0.2 * _animationController.value,
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "OSHOवाणी",
                          style: TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Ollama based LLM Fine-Tuned by LoRa",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white24,
                            backgroundImage:
                                _image != null ? FileImage(_image!) : null,
                            child: _image == null
                                ? const Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              if (!_isLoginMode)
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "Enter your name",
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Colors.white70),
                                    ),
                                  ),
                                ),
                              if (!_isLoginMode) const SizedBox(height: 10),
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Enter your email",
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: Colors.white70),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.redAccent),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              if (_emailError != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, left: 12),
                                  child: Text(
                                    _emailError!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Enter your password",
                                  labelStyle:
                                      const TextStyle(color: Colors.white70),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: Colors.white70),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.redAccent),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Colors.redAccent),
                                  ),
                                ),
                                obscureText: true,
                              ),
                              if (_passwordError != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4, left: 12),
                                    child: Text(
                                      _passwordError!,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                  ),
                                  onPressed: _isLoading ? null : _handleAuth,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          _isLoginMode ? "Login" : "Sign Up",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isLoginMode = !_isLoginMode;
                                        });
                                      },
                                child: Text(
                                  _isLoginMode
                                      ? "Don't have an account? Sign Up"
                                      : "Already have an account? Login",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Or continue with",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSocialLoginButton(
                                    context,
                                    icon: Icons.g_mobiledata,
                                    label: "Google",
                                    onPressed: () {
                                      _handleSocialLogin(
                                        _aiHandler.loginWithGoogle,
                                      );

                                      // launchUrl(Uri.parse(
                                      //     "https://8001-idx-ai-chatbot-1741200952471.cluster-a3grjzek65cxex762e4mwrzl46.cloudworkstations.dev/auth/login/google"));
                                    },
                                  ),
                                  _buildSocialLoginButton(
                                    context,
                                    icon: Icons.code,
                                    label: "Github",
                                    onPressed: () => _handleSocialLogin(
                                      _aiHandler.loginWithGithub,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSocialLoginButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
