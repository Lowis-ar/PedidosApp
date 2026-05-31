import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/zone_controller.dart';
import '../../models/order_model.dart';
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
  
  // Address fields
  final _addressController = TextEditingController();
  final _referenceController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  String _addressType = 'Home';
  bool _isAddingNewAddress = false;

  int _currentStep = 0;
  bool _cardValid = false;
  String _cardType = '';
  String _paymentMethod = 'cash_on_delivery'; // 'cash_on_delivery' or 'card'

  double? _selectedLat;
  double? _selectedLng;
  double? _dynamicDeliveryFee;

  Future<void> _calculateDynamicFee() async {
    if (_selectedLat != null && _selectedLng != null) {
      int branchId = Get.find<BranchController>().branchId;
      double? fee = await Get.find<OrderController>().getShippingFee(_selectedLat!, _selectedLng!, branchId);
      setState(() {
        _dynamicDeliveryFee = fee;
      });
      if (fee != null) {
        Get.snackbar('Tarifa calculada', 'Costo de envío dinámico: \$${fee.toStringAsFixed(2)}', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Error', 'No se pudo calcular la tarifa, se usará la tarifa base de la zona', backgroundColor: Colors.orange, colorText: Colors.white);
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
    Get.find<ZoneController>().getZoneList();
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
    _addressController.dispose();
    _referenceController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  // Luhn algorithm for card validation
  bool _validateCardNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'\s|-'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
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
        isLoading: orderController.isLoading,
        label: 'Procesando pedido...',
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
            // 1. Selector de Zona Dinámico
            const Text("Zona de Entrega", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: zoneController.isLoaded
                  ? DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: zoneController.selectedZoneId != -1 ? zoneController.selectedZoneId : null,
                        hint: const Text("Selecciona una zona"),
                        items: zoneController.zoneList.map((ZoneModel zone) {
                          return DropdownMenuItem<int>(
                            value: zone.id,
                            child: Text(zone.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            zoneController.setZoneId(val);
                            if (orderController.selectedAddress != null) {
                              orderController.selectedAddress!.zoneId = val;
                            }
                          }
                        },
                      ),
                    )
                  : const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
            ),
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
                        // Deseleccionar dirección previa
                        orderController.clearSelectedAddress();
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
                                    Get.snackbar('Zona detectada', 'Se ha seleccionado la zona: ${matchedZone.name}', backgroundColor: Colors.green, colorText: Colors.white);
                                 } else {
                                    Get.snackbar('Sin cobertura', 'Lo sentimos, no hay cobertura en $locality', backgroundColor: Colors.orange, colorText: Colors.white);
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
              const SizedBox(height: 10),
              _buildCheckoutField(_contactNameController, 'Nombre de contacto', Icons.person),
              const SizedBox(height: 10),
              _buildCheckoutField(_contactPhoneController, 'Teléfono de contacto', Icons.phone,
                  keyboardType: TextInputType.phone),
            ],
          ],
        );
      });
    });
  }

  Widget _buildPaymentStep() {
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
        // Card details (only visible when card is selected)
        if (_paymentMethod == 'card') ...[
          const Divider(height: 8),
          const SizedBox(height: 12),
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
        ],
      ],
    );
  }

  Widget _buildConfirmStep() {
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<ZoneController>(builder: (zoneController) {
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

        double total = subtotal + deliveryFee;

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
                      Text('Envío (${_dynamicDeliveryFee != null ? "Mapa" : (selectedZone?.name ?? "Zona")})', style: const TextStyle(fontSize: 14)),
                      Text('\$${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
                    ],
                  ),
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
                      : (_cardType.isNotEmpty
                          ? '$_cardType •••• ${_cardNumberController.text.substring(_cardNumberController.text.length > 4 ? _cardNumberController.text.length - 4 : 0)}'
                          : 'Tarjeta de Crédito/Débito'),
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
}

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Validate address
      if (_addressController.text.isEmpty) {
        final selected = Get.find<OrderController>().selectedAddress;
        if (selected == null) {
          Get.snackbar('Dirección requerida', 'Selecciona o ingresa una dirección de entrega',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        }
      } else {
        if (Get.find<ZoneController>().selectedZoneId == -1) {
          Get.snackbar('Zona requerida', 'Selecciona una zona que corresponda a tu dirección',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        }
        if (_selectedLat == null || _selectedLng == null) {
          Get.snackbar('Ubicación requerida', 'Usa el botón de mapa para seleccionar la ubicación exacta de entrega',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        }
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validate payment
      if (_paymentMethod == 'card') {
        if (!_cardValid) {
          Get.snackbar('Tarjeta inválida', 'Ingresa un número de tarjeta válido',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        }
        if (_cardHolderController.text.isEmpty) {
          Get.snackbar('Datos incompletos', 'Ingresa el nombre del titular',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        }
        if (_expiryController.text.length < 5) {
          Get.snackbar('Datos incompletos', 'Ingresa la fecha de expiración',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        } else {
          // Validate MM/YY
          List<String> parts = _expiryController.text.split('/');
          if (parts.length == 2) {
            int? month = int.tryParse(parts[0]);
            int? year = int.tryParse(parts[1]);

            if (month == null || month < 1 || month > 12) {
              Get.snackbar('Expiración inválida', 'El mes debe estar entre 01 y 12',
                backgroundColor: Colors.redAccent, colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
              return;
            }

            final now = DateTime.now();
            final currentYear = now.year % 100;
            final currentMonth = now.month;

            if (year == null || year < currentYear) {
              Get.snackbar('Tarjeta expirada', 'La tarjeta ya venció (año inválido)',
                backgroundColor: Colors.redAccent, colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
              return;
            }

            if (year == currentYear && month < currentMonth) {
              Get.snackbar('Tarjeta expirada', 'La tarjeta venció en el mes $month/$year',
                backgroundColor: Colors.redAccent, colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
              return;
            }
          } else {
            Get.snackbar('Datos inválidos', 'El formato debe ser MM/YY',
              backgroundColor: Colors.redAccent, colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
            return;
          }
        }
        if (_cvvController.text.length < 3) {
          Get.snackbar('Datos incompletos', 'Ingresa el CVV',
            backgroundColor: Colors.redAccent, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
          return;
        }
      }
      // cash_on_delivery: no card validation needed
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    final orderController = Get.find<OrderController>();
    final cartController = Get.find<CartController>();

    int? finalAddressId;

    // LÓGICA REFORZADA: Si ya hay un ID, NO intentar crear dirección
    if (orderController.selectedAddress != null && orderController.selectedAddress!.id != null) {
      finalAddressId = orderController.selectedAddress!.id;
    } else if (_isAddingNewAddress && _addressController.text.isNotEmpty) {
      if (_selectedLat == null || _selectedLng == null) {
        Get.snackbar('Mapa', 'Por favor selecciona la ubicación en el mapa', 
          backgroundColor: Colors.orange, colorText: Colors.white);
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
      Get.snackbar('Error', 'Por favor selecciona o ingresa una dirección de entrega', 
        backgroundColor: Colors.redAccent, colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      return;
    }

    // PETICIÓN DIRECTA AL PEDIDO
    debugPrint("Enviando pedido con address_id: $finalAddressId");

    bool success = await orderController.placeOrder(
      cartItems: cartController.getItems,
      addressId: finalAddressId,
      orderNote: _noteController.text,
      lat: _selectedLat,
      lng: _selectedLng,
      paymentMethod: _paymentMethod,
    );

    if (success) {
      _showOtpConfirmation(orderController.lastOtp ?? '');
    }
  }

  void _showOtpConfirmation(String otp) {
    Get.dialog(
      AlertDialog(
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
                child: QrImageView(
                  data: otp.isNotEmpty ? otp : '0000',
                  version: QrVersions.auto,
                  size: 180,
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
                Get.back(); // Close dialog
                Get.back(); // Back to cart/home
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
      ),
      barrierDismissible: false,
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
