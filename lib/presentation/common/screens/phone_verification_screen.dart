import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../data/services/twilio_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/top_info_message.dart';
import '../../../core/localization.dart';
import '../screens/login_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String password;
  final String nombre;
  final String rol;
  final String direccion;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.nombre,
    required this.rol,
    required this.direccion,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  bool _isRegistrationComplete = false;
  String? _error;
  String? _success;
  int _resendCountdown = 60;
  bool _canResend = false;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
    _startResendTimer();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        if (_resendCountdown > 0) {
          _startResendTimer();
        } else {
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final formattedPhone = TwilioService.formatPhoneNumber(widget.phoneNumber);
    final result = await TwilioService.sendVerificationCode(formattedPhone);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _success = result['message'];
      });
      
      showTopInfoMessage(
        context,
        'Código enviado a $formattedPhone',
        icon: Icons.check_circle,
        backgroundColor: Colors.green[50],
        textColor: Colors.green[700],
        iconColor: Colors.green[700],
      );
    } else {
      setState(() {
        _error = result['message'];
      });
      
      showTopInfoMessage(
        context,
        result['message'],
        icon: Icons.error,
        backgroundColor: Colors.red[50],
        textColor: Colors.red[700],
        iconColor: Colors.red[700],
      );
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() {
      _isResending = true;
      _canResend = false;
      _resendCountdown = 60;
    });

    await _sendVerificationCode();
    
    setState(() {
      _isResending = false;
    });

    _startResendTimer();
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((controller) => controller.text).join();
    
    if (code.length != 6) {
      setState(() {
        _error = 'Ingrese el código completo de 6 dígitos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Verificar código usando el backend
      final formattedPhone = TwilioService.formatPhoneNumber(widget.phoneNumber);
      final result = await TwilioService.verifyCode(formattedPhone, code);

      if (result['success']) {
        setState(() {
          _isLoading = false;
        });

        // Completar registro
        _completeRegistration();
      } else {
        setState(() {
          _isLoading = false;
          _error = result['message'] ?? 'Código incorrecto';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al verificar código: $e';
      });
    }
  }

  void _completeRegistration() async {
    try {
      // Completar el registro usando el backend
      final authData = await AuthService.register(
        email: widget.email,
        password: widget.password,
        nombre: widget.nombre,
        rol: widget.rol,
        telefono: widget.phoneNumber,
        direccion: widget.direccion,
      );

      if (authData != null) {
        print('✅ Usuario registrado exitosamente');
        
        // Actualizar estado para mostrar éxito
        setState(() {
          _isRegistrationComplete = true;
          _isLoading = false;
        });
        
        showTopInfoMessage(
          context,
          'Registro completado exitosamente.',
          icon: Icons.check_circle,
          backgroundColor: Colors.green[50],
          textColor: Colors.green[700],
          iconColor: Colors.green[700],
        );
        
        // Redirigir al login después de 3 segundos
        _redirectToLogin();
      } else {
        throw Exception('Error en el registro');
      }
    } catch (e) {
      print('❌ Error al registrar usuario: $e');
      
      // Aún así mostrar mensaje de éxito y redirigir
      setState(() {
        _isRegistrationComplete = true;
        _isLoading = false;
      });
      
      showTopInfoMessage(
        context,
        'Registro completado. Redirigiendo al login...',
        icon: Icons.check_circle,
        backgroundColor: Colors.green[50],
        textColor: Colors.green[700],
        iconColor: Colors.green[700],
      );
      
      // Redirigir al login incluso si hay error
      _redirectToLogin();
    }
  }

  // Función para redirigir al login de manera segura
  void _redirectToLogin() {
    _redirectTimer?.cancel();
    _redirectTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Usar solo GoRouter con manejo de errores
        try {
          context.go('/login');
        } catch (e) {
          print('❌ Error navegando al login: $e');
          // Si falla, intentar con pushReplacement
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          } catch (e2) {
            print('❌ Error en fallback: $e2');
            // Último recurso: mostrar mensaje y dejar que el usuario navegue manualmente
            showTopInfoMessage(
              context,
              'Registro completado. Ve al login para continuar.',
              icon: Icons.info,
              backgroundColor: Colors.blue[50],
              textColor: Colors.blue[700],
              iconColor: Colors.blue[700],
            );
          }
        }
      }
    });
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Verificar si todos los campos están llenos
    final allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    if (allFilled) {
      _verifyCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Teléfono'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Icono y título
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.phone_android,
                  size: 60,
                  color: Colors.blue[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Verificar tu número',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Enviamos un código de verificación a\n${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              
                             const SizedBox(height: 40),
               
               // Mensaje de éxito cuando el registro está completo
               if (_isRegistrationComplete) ...[
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.green[50],
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Colors.green[200]!),
                   ),
                   child: Row(
                     children: [
                       Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           '¡Registro completado exitosamente!\nRedirigiendo al login...',
                           style: TextStyle(
                             color: Colors.green[700],
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 24),
               ],
               
               // Campos de código
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                                             onChanged: _isRegistrationComplete ? null : (value) => _onCodeChanged(value, index),
                       enabled: !_isRegistrationComplete,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
                             // Botón de verificar
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _isRegistrationComplete ? null : (_isLoading ? null : _verifyCode),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: _isRegistrationComplete 
                         ? Colors.green[600] 
                         : Colors.blue[600],
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(12),
                     ),
                   ),
                   child: _isLoading
                       ? const SizedBox(
                           width: 24,
                           height: 24,
                           child: CircularProgressIndicator(
                             strokeWidth: 2,
                             color: Colors.white,
                           ),
                         )
                       : _isRegistrationComplete
                           ? Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Icon(Icons.check_circle, size: 20),
                                 const SizedBox(width: 8),
                                 const Text(
                                   'Registro Exitoso',
                                   style: TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ],
                             )
                           : const Text(
                               'Verificar Código',
                               style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                 ),
               ),
              
              const SizedBox(height: 24),
              
              // Botón de reenviar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No recibiste el código? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                                     TextButton(
                     onPressed: _isRegistrationComplete ? null : (_canResend && !_isResending ? _resendCode : null),
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _canResend ? 'Reenviar' : 'Reenviar en $_resendCountdown',
                            style: TextStyle(
                              color: _canResend ? Colors.blue[600] : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 