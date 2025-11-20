import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/user_model.dart';
import '../../../../presentation/providers/users_provider.dart';
import 'photo_picker_widget.dart';

/// Formulario para crear/editar usuarios con integración completa a Supabase
class UserFormWidget extends ConsumerStatefulWidget {
  final String? userId; // Si existe, modo edición
  final String? currentUserRole; // Rol del usuario actual (para permisos)
  final Function(String userName) onSuccess;

  const UserFormWidget({
    super.key,
    this.userId,
    this.currentUserRole,
    required this.onSuccess,
  });

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
  String? _nameErrorText;

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

      if (!mounted) return;

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
    } catch (e) {
      if (!mounted) return;

      // Usar addPostFrameCallback para mostrar SnackBar de forma segura
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cargar usuario: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
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
    final result = Validators.name(_nameController.text.trim());
    setState(() {
      _isNameValid = result == null;
      _nameErrorText = result;
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

        // Obtener nueva contraseña si se escribió algo
        final newPassword = _passwordController.text.trim();

        user = await updateUser(
          userId: widget.userId!,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          newPassword: newPassword.isEmpty
              ? null
              : newPassword, // Solo actualizar si no está vacía
          newPhotoFile: _selectedPhoto,
          supervisorId: _selectedSupervisorId,
          isActive: _isActive,
        );
      }

      if (mounted) {
        widget.onSuccess(user.fullName);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      // Usar addPostFrameCallback para mostrar SnackBar de forma segura
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
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
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[a-zA-ZÁÉÍÓÚáéíóúÑñÜü'\s-]"),
              ),
              LengthLimitingTextInputFormatter(60),
            ],
            isValid: _isNameValid,
            errorText: _nameErrorText,
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              LengthLimitingTextInputFormatter(20),
            ],
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    int? maxLength,
    bool isValid = false,
    String? errorText,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _sectionLabelStyle()),
        const SizedBox(height: AppTheme.spacingXS),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          buildCounter: maxLength != null
              ? (
                  context, {
                  required int currentLength,
                  required bool isFocused,
                  int? maxLength,
                }) => null
              : null,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: _mutedTextColor(0.7)),
            suffixIcon: controller.text.isNotEmpty
                ? Icon(
                    isValid ? Icons.check_circle : Icons.cancel,
                    color: isValid ? AppTheme.success : Colors.red,
                  )
                : null,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: _fieldBorderColor()),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: _fieldBorderColor()),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: _fieldBackgroundColor(),
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
              : '🔓 Escribe una nueva contraseña para cambiarla, o déjalo vacío para mantener la actual',
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
    final theme = Theme.of(context);
    final dropdownColor = theme.cardColor;
    final List<DropdownMenuItem<String>> availableRoles = [];

    availableRoles.add(
      _roleMenuItem(
        value: 'worker',
        icon: Icons.person,
        iconColor: theme.colorScheme.primary,
        title: 'Trabajador',
        subtitle: 'Puede registrar asistencia y ventas',
      ),
    );

    if (widget.currentUserRole == 'manager') {
      availableRoles.add(
        _roleMenuItem(
          value: 'supervisor',
          icon: Icons.supervisor_account,
          iconColor: Colors.orange,
          title: 'Supervisor',
          subtitle: 'Gestiona equipo y ve reportes',
        ),
      );

      availableRoles.add(
        _roleMenuItem(
          value: 'manager',
          icon: Icons.admin_panel_settings,
          iconColor: Colors.purple,
          title: 'Manager',
          subtitle: 'Control total del sistema',
        ),
      );
    } else if (_selectedRole == 'supervisor' || _selectedRole == 'manager') {
      availableRoles.add(
        _roleMenuItem(
          value: _selectedRole,
          icon: _selectedRole == 'supervisor'
              ? Icons.supervisor_account
              : Icons.admin_panel_settings,
          iconColor: theme.disabledColor,
          title: _selectedRole == 'supervisor' ? 'Supervisor' : 'Manager',
          subtitle: 'Solo managers pueden editar este rol',
          enabled: false,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rol del Usuario', style: _sectionLabelStyle()),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          decoration: BoxDecoration(
            color: _fieldBackgroundColor(),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: _fieldBorderColor()),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              dropdownColor: dropdownColor,
              itemHeight: null,
              selectedItemBuilder: (context) {
                return availableRoles.map((item) {
                  final roleValue = item.value ?? _selectedRole;
                  return _RoleSelectedTile(
                    icon: _roleIcon(roleValue),
                    iconColor: _roleIconColor(roleValue),
                    title: _roleTitle(roleValue),
                  );
                }).toList();
              },
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
              items: availableRoles,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedRole = value;
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supervisor (Opcional)', style: _sectionLabelStyle()),
        const SizedBox(height: AppTheme.spacingXS),
        Container(
          decoration: BoxDecoration(
            color: _fieldBackgroundColor(),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: _fieldBorderColor()),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSupervisorId,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Seleccionar supervisor'),
              ),
              isExpanded: true,
              dropdownColor: theme.cardColor,
              itemHeight: null,
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Sin supervisor'),
                  ),
                ),
                ...supervisors.map((supervisor) {
                  return DropdownMenuItem<String?>(
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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _fieldBackgroundColor(),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: _fieldBorderColor()),
      ),
      child: SwitchListTile(
        title: Text(
          'Usuario Activo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _isActive
              ? 'Puede iniciar sesi?n y usar el sistema'
              : 'No puede acceder al sistema',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _mutedTextColor(0.7),
          ),
        ),
        value: _isActive,
        activeThumbColor: theme.colorScheme.primary,
        onChanged: (value) {
          setState(() => _isActive = value);
        },
      ),
    );
  }

  Color _fieldBackgroundColor() {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final alpha = theme.brightness == Brightness.dark ? 0.35 : 0.95;
    return base.withValues(alpha: alpha);
  }

  Color _fieldBorderColor() {
    final theme = Theme.of(context);
    return theme.colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.4 : 0.2,
    );
  }

  TextStyle _sectionLabelStyle() {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 14);
  }

  Color _mutedTextColor([double opacity = 0.6]) {
    final theme = Theme.of(context);
    final base =
        theme.textTheme.bodyMedium?.color ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black87);
    return base.withValues(alpha: opacity);
  }

  DropdownMenuItem<String> _roleMenuItem({
    required String value,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: enabled ? null : _mutedTextColor(),
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: _mutedTextColor(0.7),
      fontSize: 11,
    );

    return DropdownMenuItem<String>(
      value: value,
      enabled: enabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? iconColor : _mutedTextColor(0.5),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: textStyle),
                  Text(
                    subtitle,
                    style: subtitleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'manager':
        return Icons.admin_panel_settings;
      case 'supervisor':
        return Icons.supervisor_account;
      default:
        return Icons.person;
    }
  }

  Color _roleIconColor(String role) {
    final theme = Theme.of(context);
    switch (role) {
      case 'manager':
        return Colors.purple;
      case 'supervisor':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _roleTitle(String role) {
    switch (role) {
      case 'manager':
        return 'Manager';
      case 'supervisor':
        return 'Supervisor';
      default:
        return 'Trabajador';
    }
  }
}

class _RoleSelectedTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _RoleSelectedTile({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
