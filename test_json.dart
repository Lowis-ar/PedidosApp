import 'dart:convert';
import 'lib/models/delivery_order_model.dart';

void main() {
  final jsonStr = '''{
    "id": 1,
    "status": "delivered",
    "latitude": "12.34",
    "longitude": "-56.78",
    "subtotal": "10.00",
    "delivery_fee": "2.00",
    "deliveryman_payout": "3.00",
    "discount_amount": "0.00",
    "total": "12.00",
    "user": {
      "id": 1,
      "name": "John Doe",
      "phone": "12345678"
    },
    "address": {
      "id": 1,
      "address": "123 Main St",
      "street": "Main",
      "references": "Near park",
      "latitude": "12.34",
      "longitude": "-56.78"
    },
    "branch": {
      "id": 1,
      "name": "Branch 1",
      "address": "456 Center",
      "phone": "87654321",
      "latitude": "12.35",
      "longitude": "-56.79"
    }
  }''';

  try {
    final map = jsonDecode(jsonStr);
    final order = DeliveryOrderModel.fromJson(map);
    print("Parsed: \${order.id} - \${order.orderStatus}");
  } catch (e, stack) {
    print("Error: \$e");
    print(stack);
  }
}
