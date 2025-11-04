import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/user_model.dart';
import '../../../../presentation/providers/users_provider.dart';
import 'photo_picker_widget.dart';

/// Formulario para crear/editar usuarios con integración completa a Supabase
class UserFormWidget extends ConsumerStatefulWidget {
  final String? userId; // Si existe, modo edición
  final Function(String userName) onSuccess;

  const UserFormWidget({super.key, this.userId, required this.onSuccess});

  @override
  ConsumerState<UserFormWidget> createState() => _UserFormWidgetState();
}

class _UserFormWidgetState extends ConsumerState<UserFormWidget> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _documentController = TextEditingController();
  final _phoneController = TextEditingController();

  // State
  File? _selectedPhoto;
  String? _currentPhotoUrl; // URL de la foto actual del usuario
  String? _selectedSupervisorId;
  String _selectedRole = 'worker'; // worker, supervisor, manager
  bool _isActive = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // Validation
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isDocumentValid = false;
  bool _isPhoneValid = true; // Opcional

  @override
  void initState() {
    super.initState();
    _setupValidation();
    // Cargar datos si es modo edición
    if (widget.userId != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await ref.read(userByIdProvider(widget.userId!).future);

      if (mounted) {
        setState(() {
          _nameController.text = user.fullName;
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
          _selectedRole = user.role;
          _isActive = user.isActive;
          _selectedSupervisorId = user.supervisorId;
          _currentPhotoUrl = user.photoUrl; // Guardar foto actual

          // El documento no está en el modelo, lo dejamos vacío
          // En modo edición, la contraseña es opcional
          // Si el usuario no la cambia, mantenemos la existente
          _isPasswordValid = true; // Ya tiene contraseña en la BD

          // Validar todos los campos cargados
          _validateName();
          _validateEmail();
          _validateDocument();
          _validatePhone();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _documentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setupValidation() {
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _documentController.addListener(_validateDocument);
    _phoneController.addListener(_validatePhone);
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().length >= 3;
    });
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      _isEmailValid = Validators.email(email) == null;
    });
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();
    setState(() {
      // En modo edición, la contraseña es opcional (vacía = no cambiar)
      // En modo creación, es obligatoria (mínimo 8 caracteres)
      if (widget.userId != null) {
        _isPasswordValid = password.isEmpty || password.length >= 8;
      } else {
        _isPasswordValid = password.length >= 8;
      }
    });
  }

  void _validateDocument() {
    setState(() {
      // El documento es opcional ya que no existe en el modelo
      final doc = _documentController.text.trim();
      _isDocumentValid = doc.isEmpty || doc.length >= 5;
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    setState(() {
      _isPhoneValid = phone.isEmpty || Validators.phone(phone) == null;
    });
  }

  bool get _isFormValid =>
      _isNameValid &&
      _isEmailValid &&
      _isPasswordValid &&
      _isDocumentValid &&
      _isPhoneValid;

  Future<void> _handleSubmit() async {
    if (!_isFormValid || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserModel user;

      if (widget.userId == null) {
        // MODO CREACIÓN
        final createUser = ref.read(createUserProvider);

        user = await createUser(
          email: _emailController.text.trim(),
          fullName: _nameController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          photoFile: _selectedPhoto,
          supervisorId: _selectedSupervisorId,
          isActive: _isActive,
        );
      } else {
        // MODO EDICIÓN
        final updateUser = ref.read(updateUserProvider);

        user = await updateUser(
          userId: widget.userId!,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          newPhotoFile: _selectedPhoto,
          supervisorId: _selectedSupervisorId,
          isActive: _isActive,
        );

        // TODO: Si se cambió la contraseña, actualizar en Auth
        // Por ahora, las contraseñas solo se pueden establecer al crear
      }

      if (mounted) {
        widget.onSuccess(user.fullName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cargar supervisores
    final supervisorsAsync = ref.watch(supervisorsListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo picker
          Center(
            child: PhotoPickerWidget(
              currentPhotoUrl:
                  _currentPhotoUrl, // Mostrar foto actual en modo edición
              onPhotoSelected: (photo) {
                setState(() => _selectedPhoto = photo);
              },
            ),
          ),

          const SizedBox(height: AppTheme.spacingXL),

          // Nombre completo
          _buildTextField(
            controller: _nameController,
            label: 'Nombre Completo',
            hint: 'Ej: Carlos Rodríguez',
            icon: Icons.person,
            isValid: _isNameValid,
            errorText: _nameController.text.isNotEmpty && !_isNameValid
                ? 'Mínimo 3 caracteres'
                : null,
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'usuario@empresa.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            isValid: _isEmailValid,
            errorText: _emailController.text.isNotEmpty && !_isEmailValid
                ? 'Email inválido'
                : null,
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Contraseña
          _buildPasswordField(),

          const SizedBox(height: AppTheme.spacingM),

          // Documento (Opcional - no está en el modelo)
          _buildTextField(
            controller: _documentController,
            label: 'Documento de Identidad (Opcional)',
            hint: '12345678',
            icon: Icons.badge,
            keyboardType: TextInputType.number,
            isValid: _isDocumentValid,
            errorText: _documentController.text.isNotEmpty && !_isDocumentValid
                ? 'Mínimo 5 caracteres'
                : null,
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Teléfono (opcional)
          _buildTextField(
            controller: _phoneController,
            label: 'Teléfono (Opcional)',
            hint: '555-1234',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            isValid: _isPhoneValid,
            errorText: _phoneController.text.isNotEmpty && !_isPhoneValid
                ? 'Mínimo 7 dígitos'
                : null,
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Selector de Rol
          _buildRoleSelector(),

          const SizedBox(height: AppTheme.spacingM),

          // Supervisor dropdown (solo si es worker)
          if (_selectedRole == 'worker')
            supervisorsAsync.when(
              data: (supervisors) => _buildSupervisorDropdown(supervisors),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Error al cargar supervisores: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (_selectedRole == 'worker')
            const SizedBox(height: AppTheme.spacingM),

          // Switch activo/inactivo
          _buildActiveSwitch(),

          const SizedBox(height: AppTheme.spacingXL),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],

          // Submit button
          ElevatedButton(
            onPressed: _isFormValid && !_isLoading ? _handleSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.userId == null
                        ? 'Crear Usuario'
                        : 'Actualizar Usuario',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          // Botón de Cancelar
          const SizedBox(height: AppTheme.spacingM),
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondaryLight,
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isValid = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textSecondaryLight),
            suffixIcon: controller.text.isNotEmpty
                ? Icon(
                    isValid ? Icons.check_circle : Icons.cancel,
                    color: isValid ? Colors.green : Colors.red,
                  )
                : null,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contraseña',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          decoration: InputDecoration(
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            errorText: _passwordController.text.isNotEmpty && !_isPasswordValid
                ? 'Mínimo 6 caracteres'
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(
                color: AppTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.userId == null
              ? '🔒 La contraseña es requerida para que el usuario pueda iniciar sesión'
              : '🔓 Deja vacío si no quieres cambiar la contraseña actual',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rol del Usuario',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'worker',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Trabajador',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Puede registrar asistencia y ventas',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'supervisor',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.supervisor_account,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Supervisor',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Gestiona equipo y ve reportes',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'manager',
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.purple,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gerente',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Acceso total al sistema',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                  // Si cambia a supervisor o manager, limpiar supervisor
                  if (value != 'worker') {
                    _selectedSupervisorId = null;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupervisorDropdown(List<dynamic> supervisors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supervisor (Opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSupervisorId,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Seleccionar supervisor'),
              ),
              isExpanded: true,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Sin supervisor'),
                  ),
                ),
                ...supervisors.map((supervisor) {
                  return DropdownMenuItem<String>(
                    value: supervisor.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              supervisor.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              supervisor.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedSupervisorId = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        title: const Text(
          'Usuario Activo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _isActive
              ? 'Puede iniciar sesión y usar el sistema'
              : 'No puede acceder al sistema',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        value: _isActive,
        activeThumbColor: AppTheme.primaryBlue,
        onChanged: (value) {
          setState(() => _isActive = value);
        },
      ),
    );
  }
}
