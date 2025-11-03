import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

/// Página para agregar una nueva venta
///
/// Features:
/// - Formulario con validación
/// - Date picker para seleccionar fecha
/// - Input de monto con formato de moneda
/// - Selector de categoría
/// - Guardar en Supabase
class AddSalePage extends ConsumerStatefulWidget {
  const AddSalePage({super.key});

  @override
  ConsumerState<AddSalePage> createState() => _AddSalePageState();
}

class _AddSalePageState extends ConsumerState<AddSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Electrónica',
    'Ropa',
    'Alimentos',
    'Hogar',
    'Deportes',
    'Otros',
  ];

  final _categoryIcons = {
    'Electrónica': Icons.phone_android,
    'Ropa': Icons.checkroom,
    'Alimentos': Icons.restaurant,
    'Hogar': Icons.home,
    'Deportes': Icons.sports_soccer,
    'Otros': Icons.shopping_bag,
  };

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una categoría'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final datasource = ref.read(supabaseDatasourceProvider);
      final userId = ref.read(currentUserIdProvider);

      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await datasource.createSale(
        userId: userId,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        quantity: int.parse(_quantityController.text),
        productCategory: _selectedCategory!,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${error.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            // Fecha
            _buildSectionTitle('Fecha de Venta'),
            const SizedBox(height: AppTheme.spacingS),
            _buildDateField(),
            const SizedBox(height: AppTheme.spacingL),

            // Monto
            _buildSectionTitle('Monto (\$)'),
            const SizedBox(height: AppTheme.spacingS),
            _buildAmountField(),
            const SizedBox(height: AppTheme.spacingL),

            // Cantidad
            _buildSectionTitle('Cantidad de Unidades'),
            const SizedBox(height: AppTheme.spacingS),
            _buildQuantityField(),
            const SizedBox(height: AppTheme.spacingL),

            // Categoría
            _buildSectionTitle('Categoría del Producto'),
            const SizedBox(height: AppTheme.spacingS),
            _buildCategorySelector(),
            const SizedBox(height: AppTheme.spacingXL),

            // Botón de guardar
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildDateField() {
    final dateFormat = DateFormat('dd MMMM yyyy', 'es');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: '0.00',
        prefixIcon: const Icon(Icons.attach_money, color: AppTheme.success),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el monto';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'El monto debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        hintText: '1',
        prefixIcon: const Icon(Icons.inventory, color: AppTheme.info),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa la cantidad';
        }
        final quantity = int.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'La cantidad debe ser mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: AppTheme.spacingS,
      runSpacing: AppTheme.spacingS,
      children: _categories.map((category) {
        final isSelected = _selectedCategory == category;

        return Material(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcons[category],
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitSale,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Guardar Venta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// Provider para obtener el ID del usuario actual
final currentUserIdProvider = Provider<String?>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  return currentUser?.id;
});
