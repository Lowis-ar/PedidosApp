import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/coupon_controller.dart';
import '../../controllers/zone_controller.dart';
import '../../models/order_model.dart';
import '../../models/payment_card_model.dart';
import '../../models/zone_model.dart';
import '../../utils/colors.dart';
import '../../utils/dimensions.dart';
import '../../widgets/big_text.dart';
import '../../widgets/shimmer_widgets.dart';
import '../../widgets/small_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../address/map_pin_picker_view.dart';
import '../../controllers/branch_controller.dart';
import 'package:geocoding/geocoding.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../routes/route_helper.dart';
import '../../utils/app_snackbar.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _noteController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _couponController = TextEditingController();
  
  // Address fields
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _addressType = 'Home';
  bool _isAddingNewAddress = false;
  bool _isAddingNewCard = false;

  int _currentStep = 0;
  bool _cardValid = false;
  String _cardType = '';
  String _paymentMethod = 'cash_on_delivery'; // 'cash_on_delivery' or 'card'
  bool _isProcessingPayment = false;

  double? _selectedLat;
  double? _selectedLng;
  double? _dynamicDeliveryFee;

  Future<void> _calculateDynamicFee() async {
    if (_selectedLat != null && _selectedLng != null) {
      int branchId = Get.find<BranchController>().branchId;
      final response = await Get.find<OrderController>().getShippingFee(_selectedLat!, _selectedLng!, branchId);
      
      if (response != null) {
        bool isSuccess = response['success'] ?? false;
        String message = response['message'] ?? '';
        
        if (isSuccess) {
          final data = response['data'] ?? {};
          bool isOutOfZone = data['is_out_of_zone'] ?? false;
          double? fee = data['fee'] != null ? double.tryParse(data['fee'].toString()) : null;
          
          if (isOutOfZone && fee != null) {
            bool? confirm = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('Fuera de Cobertura Principal'),
                content: Text('Estás fuera de nuestra zona base. Podemos realizar la entrega con cobro extra por distancia. El costo total de envío será de \$${fee.toStringAsFixed(2)}. ¿Deseas continuar?'),
                actions: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
                  ElevatedButton(onPressed: () => Get.back(result: true), child: const Text('Aceptar')),
                ],
              ),
            );
            if (confirm == true) {
              setState(() => _dynamicDeliveryFee = fee);
            } else {
              setState(() => _dynamicDeliveryFee = null);
            }
          } else if (fee != null) {
            setState(() => _dynamicDeliveryFee = fee);
          AppSnackbar.success('Tarifa calculada', 'Costo de envío: \$${fee.toStringAsFixed(2)}');
          } else {
            setState(() => _dynamicDeliveryFee = null);
          }
        } else {
          final errors = response['errors'] ?? {};
          bool isOutOfZone = errors['is_out_of_zone'] ?? false;
          if (isOutOfZone) {
            Get.dialog(
              AlertDialog(
                title: const Text('Sin Cobertura'),
                content: Text(message.isNotEmpty ? message : 'El restaurante no tiene cobertura para tu ubicación.'),
                actions: [
                  ElevatedButton(onPressed: () => Get.back(), child: const Text('Entendido')),
                ],
              ),
            );
          } else {
            AppSnackbar.warning('Error', message.isNotEmpty ? message : 'No se pudo calcular la tarifa');
          }
          setState(() => _dynamicDeliveryFee = null);
        }
      } else {
        setState(() => _dynamicDeliveryFee = null);
        AppSnackbar.error('Error', 'No se pudo conectar con el servidor');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Get.find<OrderController>().getAddressList().then((_) {
      if (Get.find<OrderController>().addressList.isEmpty) {
        setState(() => _isAddingNewAddress = true);
      }
    });
    Get.find<OrderController>().getPaymentCards().then((_) {
      if (Get.find<OrderController>().cardList.isEmpty) {
        setState(() => _isAddingNewCard = true);
      }
    });
    Get.find<ZoneController>().getZoneList();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear any previously applied coupon to avoid stale state if cart was modified
      Get.find<CouponController>().removeCoupon(showSnackbar: false);
      // Pre-load user coupons for the coupon selector
      Get.find<CouponController>().getUserCoupons();
    });

    // Pre-fill contact info from user profile
    final user = Get.find<AuthController>().user;
    _contactNameController.text = user?.name ?? '';
    _contactPhoneController.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _couponController.dispose();
    _addressController.dispose();
    _referenceController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  // Luhn algorithm for card validation
  bool _validateCardNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'\s|-'), '');
    if (cleaned.length != 16) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int n = int.parse(cleaned[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  String _detectCardType(String number) {
    String cleaned = number.replaceAll(RegExp(r'\s|-'), '');
    if (cleaned.startsWith('4')) return 'Visa';
    if (cleaned.startsWith('5') && cleaned.length >= 2) {
      int second = int.tryParse(cleaned[1]) ?? 0;
      if (second >= 1 && second <= 5) return 'Mastercard';
    }
    if (cleaned.startsWith('34') || cleaned.startsWith('37')) return 'Amex';
    if (cleaned.startsWith('6011') || cleaned.startsWith('65')) return 'Discover';
    return '';
  }

  void _onCardNumberChanged(String value) {
    String cleaned = value.replaceAll(RegExp(r'\s|-'), '');
    setState(() {
      _cardType = _detectCardType(cleaned);
      _cardValid = _validateCardNumber(cleaned);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      return AppLoadingOverlay(
        isLoading: orderController.isLoading || _isProcessingPayment,
        label: _isProcessingPayment ? 'Procesando pago...' : 'Procesando pedido...',
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: BigText(text: "Checkout", color: AppColors.mainBlackColor, size: Dimensions.font20),
            centerTitle: true,
          ),
          body: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
            type: StepperType.vertical,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _currentStep == 2 ? 'Confirmar Pedido' : 'Continuar',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.mainColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Atrás', style: TextStyle(color: AppColors.mainColor)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Address
              Step(
                title: const Text('Dirección de Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('¿Dónde te entregamos?'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildAddressStep(),
              ),
              // Step 2: Payment
              Step(
                title: const Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_paymentMethod == 'cash_on_delivery' ? 'Contra Entrega' : 'Tarjeta de Crédito/Débito'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildPaymentStep(),
              ),
              // Step 3: Confirm
              Step(
                title: const Text('Confirmar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Revisa tu pedido'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: _buildConfirmStep(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAddressStep() {
    return GetBuilder<OrderController>(builder: (orderController) {
      return GetBuilder<ZoneController>(builder: (zoneController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Selector de Zona (Removido - La zona ahora se calcula por mapa)
            const SizedBox(height: 20),

            // Existing addresses
            if (orderController.addressList.isNotEmpty) ...[
              SmallText(text: "Direcciones guardadas", color: Colors.black54),
              const SizedBox(height: 8),
              ...orderController.addressList.map((addr) {
                bool isSelected = orderController.selectedAddress?.id == addr.id;
                return GestureDetector(
                  onTap: () {
                    orderController.selectAddress(addr);
                    _addressController.text = addr.address ?? '';
                    if (addr.contactPersonName != null && addr.contactPersonName!.isNotEmpty) {
                      _contactNameController.text = addr.contactPersonName!;
                    }
                    if (addr.contactPersonNumber != null && addr.contactPersonNumber!.isNotEmpty) {
                      _contactPhoneController.text = addr.contactPersonNumber!;
                    }
                    if (addr.latitude != null && addr.longitude != null) {
                      _selectedLat = double.tryParse(addr.latitude!);
                      _selectedLng = double.tryParse(addr.longitude!);
                      _calculateDynamicFee();
                    }
                    if (addr.zoneId != null) {
                      Get.find<ZoneController>().setZoneId(addr.zoneId!);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.mainColor.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? AppColors.mainColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          addr.addressType == 'Home' ? Icons.home : Icons.work,
                          color: isSelected ? AppColors.mainColor : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(addr.addressType ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(addr.address ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: AppColors.mainColor),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(height: 24),
              if (!_isAddingNewAddress)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAddingNewAddress = true;
                        // Deseleccionar dirección previa y limpiar textfields
                        orderController.clearSelectedAddress();
                        _addressController.clear();
                        _referenceController.clear();
                        _selectedLat = null;
                        _selectedLng = null;
                        _dynamicDeliveryFee = null;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar nueva dirección'),
                  ),
                ),
            ],

            if (_isAddingNewAddress) ...[
              SmallText(text: "Agregar nueva dirección", color: Colors.black54),
              const SizedBox(height: 8),
              // Address type selector
              Row(
                children: ['Home', 'Work', 'Other'].map((type) {
                  bool sel = _addressType == type;
                  String label = type == 'Home' ? 'Casa' : (type == 'Work' ? 'Trabajo' : 'Otro');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: sel,
                      selectedColor: AppColors.mainColor.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _addressType = type),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildCheckoutField(_addressController, 'Dirección completa', Icons.location_on)),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.mainColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final LatLng? result = await Get.to(() => const MapPinPickerView(initialLat: 13.68935, initialLng: -89.18718)); // Default El Salvador or similar
                        if (result != null) {
                          setState(() {
                            _selectedLat = result.latitude;
                            _selectedLng = result.longitude;
                          });

                          try {
                            List<Placemark> placemarks = await placemarkFromCoordinates(result.latitude, result.longitude);
                            if (placemarks.isNotEmpty) {
                              String? locality = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? placemarks.first.administrativeArea;
                              if (locality != null) {
                                 final zoneCtrl = Get.find<ZoneController>();
                                 final matchedZone = zoneCtrl.zoneList.firstWhereOrNull((z) => 
                                    locality.toLowerCase().contains(z.name.toLowerCase()) || 
                                    z.name.toLowerCase().contains(locality.toLowerCase())
                                 );
                                 if (matchedZone != null) {
                                    zoneCtrl.setZoneId(matchedZone.id);
                                    AppSnackbar.info('Zona detectada', 'Se ha seleccionado la zona: ${matchedZone.name}');
                                 } else {
                                    // Comentado para evitar confusión, ya que el cálculo dinámico decidirá si hay o no cobertura.
                                    // Get.snackbar('Sin cobertura', 'Lo sentimos, no hay cobertura en $locality', backgroundColor: Colors.orange, colorText: Colors.white);
                                 }
                              }
                            }
                          } catch(e) {
                            debugPrint('Error reverse geocoding: $e');
                          }

                          _calculateDynamicFee();
                        }
                      },
                      icon: const Icon(Icons.map, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCheckoutField(_referenceController, 'Punto de referencia (opcional)', Icons.map_outlined),
              // Campos de contacto eliminados según requerimiento, se usarán los del perfil del usuario.
            ],
          ],
        );
      });
    });
  }

  Widget _buildPaymentStep() {
    return GetBuilder<OrderController>(builder: (orderController) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method selector
          const Text('Selecciona tu método de pago', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          // Cash on delivery option
          GestureDetector(
            onTap: () => setState(() => _paymentMethod = 'cash_on_delivery'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _paymentMethod == 'cash_on_delivery'
                    ? AppColors.mainColor.withValues(alpha: 0.08)
                    : Colors.white,
                border: Border.all(
                  color: _paymentMethod == 'cash_on_delivery'
                      ? AppColors.mainColor
                      : Colors.grey.shade300,
                  width: _paymentMethod == 'cash_on_delivery' ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _paymentMethod == 'cash_on_delivery'
                        ? AppColors.mainColor.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'cash_on_delivery'
                          ? AppColors.mainColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: _paymentMethod == 'cash_on_delivery'
                          ? AppColors.mainColor
                          : Colors.grey,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contra Entrega',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Paga en efectivo al recibir tu pedido',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_paymentMethod == 'cash_on_delivery')
                    Icon(Icons.check_circle, color: AppColors.mainColor, size: 24),
                ],
              ),
            ),
          ),
          // Card payment option
          GestureDetector(
            onTap: () => setState(() => _paymentMethod = 'card'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _paymentMethod == 'card'
                    ? AppColors.mainColor.withValues(alpha: 0.08)
                    : Colors.white,
                border: Border.all(
                  color: _paymentMethod == 'card'
                      ? AppColors.mainColor
                      : Colors.grey.shade300,
                  width: _paymentMethod == 'card' ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _paymentMethod == 'card'
                        ? AppColors.mainColor.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _paymentMethod == 'card'
                          ? AppColors.mainColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: _paymentMethod == 'card' ? AppColors.mainColor : Colors.grey,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tarjeta de Crédito / Débito',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Visa, Mastercard, Amex',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_paymentMethod == 'card')
                    Icon(Icons.check_circle, color: AppColors.mainColor, size: 24),
                ],
              ),
            ),
          ),
          // Card details
          if (_paymentMethod == 'card') ...[
            const Divider(height: 8),
            const SizedBox(height: 12),

            // If we have saved cards and we are NOT adding a new card, list them
            if (orderController.cardList.isNotEmpty && !_isAddingNewCard) ...[
              const Text("Tarjetas guardadas", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 8),
              ...orderController.cardList.map((card) {
                bool isSelected = orderController.selectedCard?.id == card.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mainColor.withValues(alpha: 0.08) : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.mainColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card,
                            color: isSelected ? AppColors.mainColor : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${card.cardType} •••• ${card.lastFour}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              bool? confirm = await Get.dialog<bool>(
                                AlertDialog(
                                  title: const Text('Eliminar Tarjeta'),
                                  content: const Text('¿Estás seguro de que deseas eliminar esta tarjeta guardada?'),
                                  actions: [
                                    TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancelar')),
                                    ElevatedButton(
                                      onPressed: () => Get.back(result: true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                      child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && card.id != null) {
                                orderController.deletePaymentCard(card.id!);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              orderController.selectCard(card);
                              _cvvController.clear();
                            },
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_off,
                              color: isSelected ? AppColors.mainColor : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Text('Ingresa el CVV: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              height: 40,
                              child: TextField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3)
                                ],
                                decoration: InputDecoration(
                                  hintText: 'CVV',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingNewCard = true;
                      orderController.clearSelectedCard();
                      _cardNumberController.clear();
                      _cardHolderController.clear();
                      _expiryController.clear();
                      _cvvController.clear();
                      _cardValid = false;
                      _cardType = '';
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar nueva tarjeta'),
                ),
              ),
            ] else ...[
              // Card visual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cardType == 'Visa'
                        ? [const Color(0xFF1A1F71), const Color(0xFF2D3494)]
                        : _cardType == 'Mastercard'
                            ? [const Color(0xFFEB001B), const Color(0xFFF79E1B)]
                            : [Colors.grey.shade800, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            _cardType.isEmpty ? 'TARJETA' : _cardType.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14, letterSpacing: 2)),
                        Icon(
                          _cardValid ? Icons.check_circle : Icons.credit_card,
                          color: _cardValid ? Colors.greenAccent : Colors.white54,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _cardNumberController.text.isEmpty
                          ? '•••• •••• •••• ••••'
                          : _formatCardDisplay(_cardNumberController.text),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          letterSpacing: 3,
                          fontFamily: 'Roboto'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _cardHolderController.text.isEmpty
                              ? 'NOMBRE DEL TITULAR'
                              : _cardHolderController.text.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12, letterSpacing: 1),
                        ),
                        Text(
                          _expiryController.text.isEmpty
                              ? 'MM/YY'
                              : _expiryController.text,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildCheckoutField(_cardNumberController, 'Número de tarjeta', Icons.credit_card,
                  keyboardType: TextInputType.number,
                  onChanged: _onCardNumberChanged,
                  suffixIcon: _cardNumberController.text.length == 16 
                      ? const Icon(Icons.check_circle, color: Colors.green) 
                      : null,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16)
                  ]),
              if (_cardNumberController.text.isNotEmpty && !_cardValid)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Text('Número de tarjeta inválido',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                ),
              const SizedBox(height: 10),
              _buildCheckoutField(
                  _cardHolderController, 'Nombre del titular', Icons.person_outline),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildCheckoutField(_expiryController, 'MM/YY', Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryFormatter()
                        ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCheckoutField(_cvvController, 'CVV', Icons.lock,
                        keyboardType: TextInputType.number,
                        obscure: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3)
                        ]),
                  ),
                ],
              ),
              if (orderController.cardList.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAddingNewCard = false;
                        if (orderController.cardList.isNotEmpty) {
                          orderController.selectCard(orderController.cardList.first);
                        }
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Ver tarjetas guardadas'),
                  ),
                ),
              ],
            ],
          ],
        ],
      );
    });
  }

  Widget _buildConfirmStep() {
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<ZoneController>(builder: (zoneController) {
        return GetBuilder<CouponController>(builder: (couponController) {
        var cartList = cartController.getItems;
        double subtotal = 0;
        for (var item in cartList) {
          subtotal += ((item.price ?? 0) * (item.quantity ?? 0)) + (item.extrasPrice ?? 0);
        }

        // Obtener el costo de envío de la zona seleccionada o dinámico
        double deliveryFee = _dynamicDeliveryFee ?? 0;
        final selectedZone = zoneController.zoneList.firstWhereOrNull((z) => z.id == zoneController.selectedZoneId);
        if (_dynamicDeliveryFee == null && selectedZone != null) {
          deliveryFee = double.tryParse(selectedZone.deliveryFee) ?? 0;
        }

        // Apply coupon discount
        double couponDiscount = couponController.discountAmount;
        // For free_delivery coupons, zero out delivery fee
        if (couponController.hasCouponApplied && couponController.appliedCoupon?.coupon?.type == 'free_delivery') {
          couponDiscount = deliveryFee;
        }
        double total = subtotal + deliveryFee - couponDiscount;
        if (total < 0) total = 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  ...cartList.map((item) {
                    // Extract variant
                    String? variantName;
                    double variantPrice = 0.0;
                    if (item.variantId != null && item.product?.variants != null) {
                      final variant = item.product!.variants!.firstWhereOrNull((v) => v.id == item.variantId);
                      if (variant != null) {
                        variantName = variant.name;
                        variantPrice = variant.priceModifier?.toDouble() ?? 0.0;
                      }
                    }
                    
                    // Extract extras
                    List<Widget> extraWidgets = [];
                    if (item.extras != null && item.extras!.isNotEmpty && item.product?.extras != null) {
                      final uniqueExtras = item.extras!.toSet();
                      for (var extraId in uniqueExtras) {
                        int count = item.extras!.where((e) => e == extraId).length;
                        final extra = item.product!.extras!.firstWhereOrNull((e) => e.id == extraId);
                        if (extra != null) {
                          double extraTotal = (extra.price?.toDouble() ?? 0.0) * count;
                          extraWidgets.add(
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("  +$count ${extra.name}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text("+\$${extraTotal.toStringAsFixed(2)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          );
                        }
                      }
                    }

                    double basePrice = item.product?.price?.toDouble() ?? (item.price ?? 0);
                    int qty = item.quantity ?? 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('${qty}x ${item.name}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
                              ),
                              Text('\$${(basePrice * qty).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          if (variantName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("  Variante: $variantName", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text(variantPrice >= 0 ? "+\$${(variantPrice * qty).toStringAsFixed(2)}" : "-\$${(variantPrice.abs() * qty).toStringAsFixed(2)}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          if (extraWidgets.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text("  Complementos:", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ),
                            ...extraWidgets,
                          ],
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 14)),
                      Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Envío', style: const TextStyle(fontSize: 14)),
                      Text('\$${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  // Coupon discount row
                  if (couponController.hasCouponApplied) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_offer, color: Colors.green.shade600, size: 16),
                            const SizedBox(width: 4),
                            Text('Cupón (${couponController.appliedCouponCode})',
                                style: TextStyle(fontSize: 14, color: Colors.green.shade700)),
                          ],
                        ),
                        Text('-\$${couponDiscount.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('\$${total.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.mainColor)),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // ── Coupon section ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: couponController.hasCouponApplied ? Colors.green.shade300 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: couponController.hasCouponApplied
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        color: couponController.hasCouponApplied ? Colors.green.shade600 : AppColors.mainColor, size: 20),
                    const SizedBox(width: 8),
                    Text('Cupón de Descuento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: couponController.hasCouponApplied ? Colors.green.shade700 : Colors.black87,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                if (couponController.hasCouponApplied) ...[
                  // Applied coupon badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(couponController.appliedCouponCode ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800)),
                              Text(couponController.appliedCoupon?.message ?? '',
                                  style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            couponController.removeCoupon();
                            _couponController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Coupon input
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Ingresa tu código',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.mainColor, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.mainColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: couponController.isValidating
                              ? null
                              : () {
                                  int branchId = Get.find<BranchController>().branchId;
                                  couponController.validateCoupon(
                                    _couponController.text,
                                    subtotal,
                                    branchId,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: couponController.isValidating
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Aplicar',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                  // My coupons button
                  if (couponController.userCoupons.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showUserCouponsSheet(couponController),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.mainColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, color: AppColors.mainColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Mis Cupones (${couponController.userCoupons.length})',
                                style: TextStyle(color: AppColors.mainColor, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Address summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.mainColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _addressController.text.isNotEmpty 
                      ? _addressController.text 
                      : Get.find<OrderController>().selectedAddress?.address ?? 'Sin dirección',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Payment summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  _paymentMethod == 'cash_on_delivery' ? Icons.payments_outlined : Icons.credit_card,
                  color: AppColors.mainColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _paymentMethod == 'cash_on_delivery'
                      ? 'Contra Entrega (Efectivo)'
                      : (Get.find<OrderController>().selectedCard != null
                          ? '${Get.find<OrderController>().selectedCard!.cardType} •••• ${Get.find<OrderController>().selectedCard!.lastFour}'
                          : (_cardType.isNotEmpty
                              ? '$_cardType •••• ${_cardNumberController.text.substring(_cardNumberController.text.length > 4 ? _cardNumberController.text.length - 4 : 0)}'
                              : 'Tarjeta de Crédito/Débito')),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Order note
          _buildCheckoutField(_noteController, 'Nota del pedido (opcional)', Icons.note_alt_outlined),
        ],
      );
    });
  });
  });
}

  void _showUserCouponsSheet(CouponController couponController) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: AppColors.mainColor),
                  const SizedBox(width: 10),
                  const Text('Mis Cupones Disponibles',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
            ),
            const Divider(height: 0),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: couponController.userCoupons.length,
                itemBuilder: (context, index) {
                  final coupon = couponController.userCoupons[index];
                  return GestureDetector(
                    onTap: () {
                      _couponController.text = coupon.code ?? '';
                      Get.back();
                      // Auto-validate
                      int branchId = Get.find<BranchController>().branchId;
                      final cartController = Get.find<CartController>();
                      double subtotal = 0;
                      for (var item in cartController.getItems) {
                        subtotal += ((item.price ?? 0) * (item.quantity ?? 0)) + (item.extrasPrice ?? 0);
                      }
                      couponController.validateCoupon(coupon.code ?? '', subtotal, branchId);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.mainColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              coupon.type == 'free_delivery'
                                  ? Icons.local_shipping_outlined
                                  : Icons.local_offer,
                              color: AppColors.mainColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(coupon.code ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                                const SizedBox(height: 2),
                                Text(coupon.typeLabel,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                if (coupon.minOrderAmount != null && coupon.minOrderAmount! > 0)
                                  Text('Mínimo: \$${coupon.minOrderAmount!.toStringAsFixed(2)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: AppColors.mainColor, size: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _onStepContinue() async {
    HapticFeedback.lightImpact();
    if (_currentStep == 0) {
      // Validate address
      if (_addressController.text.isEmpty) {
        final selected = Get.find<OrderController>().selectedAddress;
        if (selected == null) {
          AppSnackbar.warning('Dirección requerida', 'Selecciona o ingresa una dirección de entrega');
          return;
        }
      } else {
        // Validation removed for manual zone selection
        if (_selectedLat == null || _selectedLng == null) {
          AppSnackbar.warning('Ubicación requerida', 'Usa el botón de mapa para seleccionar la ubicación exacta de entrega');
          return;
        }
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validate payment
      if (_paymentMethod == 'card') {
        final orderController = Get.find<OrderController>();
        if (!_isAddingNewCard && orderController.selectedCard != null) {
          // Validating CVV for saved card
          if (_cvvController.text.length < 3) {
            AppSnackbar.warning('Datos incompletos', 'Ingresa el CVV de la tarjeta');
            return;
          }
        } else {
          // Validating new card fields
          if (!_cardValid) {
            AppSnackbar.warning('Tarjeta inválida', 'Ingresa un número de tarjeta válido');
            return;
          }
          if (_cardHolderController.text.isEmpty) {
            AppSnackbar.warning('Datos incompletos', 'Ingresa el nombre del titular');
            return;
          }
          if (_expiryController.text.length < 5) {
            AppSnackbar.warning('Datos incompletos', 'Ingresa la fecha de expiración');
            return;
          } else {
            // Validate MM/YY
            List<String> parts = _expiryController.text.split('/');
            if (parts.length == 2) {
              int? month = int.tryParse(parts[0]);
              int? year = int.tryParse(parts[1]);

              if (month == null || month < 1 || month > 12) {
                AppSnackbar.warning('Expiración inválida', 'El mes debe estar entre 01 y 12');
                return;
              }

              final now = DateTime.now();
              final currentYear = now.year % 100;
              final currentMonth = now.month;

              if (year == null || year < currentYear) {
                AppSnackbar.warning('Tarjeta expirada', 'La tarjeta ya venció (año inválido)');
                return;
              }

              if (year == currentYear && month < currentMonth) {
                AppSnackbar.warning('Tarjeta expirada', 'La tarjeta venció en el mes $month/$year');
                return;
              }
            } else {
              AppSnackbar.warning('Datos inválidos', 'El formato debe ser MM/YY');
              return;
            }
          }
          if (_cvvController.text.length < 3) {
            AppSnackbar.warning('Datos incompletos', 'Ingresa el CVV');
            return;
          }

          // Simulate sending to a secure payment gateway (Stripe/PayPal) and getting a token
          String rawNumber = _cardNumberController.text.replaceAll(RegExp(r'\s|-'), '');
          String last4 = rawNumber.length >= 4 ? rawNumber.substring(rawNumber.length - 4) : '';
          String dummyToken = 'tok_${DateTime.now().millisecondsSinceEpoch}';

          PaymentCardModel newCard = PaymentCardModel(
            lastFour: last4,
            cardType: _cardType,
            providerToken: dummyToken,
          );

          bool saveSuccess = await orderController.addPaymentCard(newCard);
          if (!saveSuccess) {
            return; // Stop if saving card fails
          }
          setState(() {
            _isAddingNewCard = false;
          });
        }
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    if (_isProcessingPayment) return;
    final orderController = Get.find<OrderController>();
    final cartController = Get.find<CartController>();

    int? finalAddressId;

    // LÓGICA REFORZADA: Si ya hay un ID, NO intentar crear dirección
    if (orderController.selectedAddress != null && orderController.selectedAddress!.id != null) {
      finalAddressId = orderController.selectedAddress!.id;
    } else if (_isAddingNewAddress && _addressController.text.isNotEmpty) {
      if (_selectedLat == null || _selectedLng == null) {
        AppSnackbar.warning('Mapa', 'Por favor selecciona la ubicación en el mapa');
        return;
      }
      
      // Crear nueva dirección SOLO si no hay una seleccionada con ID
      AddressModel newAddress = AddressModel(
        addressType: _addressType,
        address: _addressController.text,
        references: _referenceController.text.isNotEmpty ? _referenceController.text : null,
        contactPersonName: _contactNameController.text,
        contactPersonNumber: _contactPhoneController.text,
        latitude: _selectedLat?.toString() ?? '0',
        longitude: _selectedLng?.toString() ?? '0',
        zoneId: Get.find<ZoneController>().selectedZoneId,
      );
      
      bool addSuccess = await orderController.addAddress(newAddress);
      if (addSuccess && orderController.selectedAddress != null) {
        finalAddressId = orderController.selectedAddress!.id;
      } else {
        return; // Detener si falla la creación de dirección
      }
    }

    if (finalAddressId == null) {
      AppSnackbar.error('Error', 'Por favor selecciona o ingresa una dirección de entrega');
      return;
    }

    // PETICIÓN DIRECTA AL PEDIDO
    debugPrint("Enviando pedido con address_id: $finalAddressId");

    // Get coupon code if applied
    final couponCode = Get.find<CouponController>().appliedCouponCode;

    setState(() {
      _isProcessingPayment = true;
    });

    // Simulamos un retraso de procesamiento para una UX más realista en el evento
    await Future.delayed(const Duration(seconds: 2));

    bool success = await orderController.placeOrder(
      cartItems: cartController.getItems,
      addressId: finalAddressId,
      orderNote: _noteController.text,
      lat: _selectedLat,
      lng: _selectedLng,
      paymentMethod: _paymentMethod,
      couponCode: couponCode,
    );

    setState(() {
      _isProcessingPayment = false;
    });

    if (success) {
      await _showPaymentSuccessDialog();
      _showOtpConfirmation(orderController.lastOtp ?? '');
    }
  }

  Future<void> _showPaymentSuccessDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Pago Aprobado!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _paymentMethod == 'card' 
                      ? 'El cobro a tu tarjeta se realizó de manera segura.' 
                      : 'Tu pedido se registrará como pago contra entrega.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ver Código de Entrega',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOtpConfirmation(String otp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
                ),
                const SizedBox(height: 14),
                const Text('¡Pedido Exitoso!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Tu código de entrega es:',
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 14),
                // QR Code
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.mainColor.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainColor.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: QrImageView(
                      data: otp.isNotEmpty ? otp : '0000',
                      version: QrVersions.auto,
                      size: 180,
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text(
                            "No se pudo cargar el QR",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        );
                      },
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.mainColor,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.mainColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Código numérico
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.mainColor, width: 2),
                  ),
                  child: Text(otp,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                          letterSpacing: 8)),
                ),
                const SizedBox(height: 10),
                Text('Muéstrale el QR o el código al repartidor',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Get.offAllNamed(RouteHelper.getInitial(pageId: 1));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Aceptar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCardDisplay(String number) {
    String cleaned = number.replaceAll(RegExp(r'\s'), '');
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  Widget _buildCheckoutField(TextEditingController controller, String hint, IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        inputFormatters: inputFormatters,
        onChanged: (value) {
          if (onChanged != null) onChanged(value);
          setState(() {}); // Rebuild for card preview
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.mainColor, size: 20),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.mainColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);
    
    if (text.isNotEmpty) {
      String mStr = text.substring(0, text.length >= 2 ? 2 : text.length);
      int? month = int.tryParse(mStr);
      if (month != null) {
        if (text.length == 1 && month > 1) {
          text = "0$month";
        } else if (text.length >= 2 && (month < 1 || month > 12)) {
          return oldValue;
        }
      }
    }
    
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
