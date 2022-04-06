import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:http/http.dart' as http;

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime datetime;
  OrderItem(@required this.id, @required this.amount, @required this.products,
      @required this.datetime);
}

class Orders with ChangeNotifier {
  String? _authToken;
  String? _userId;
  set authToken(String value) {
    _authToken = value;
  }

  String get authToken {
    return _authToken.toString();
  }

  set userId(String value) {
    _userId = value;
  }

  String get userId {
    return userId.toString();
  }

  List<OrderItem> _orders = [];
  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    dynamic url = Uri.parse(
        'https://shop-app-6e7fb-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken');
    final response = await http.get(url);
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(
        OrderItem(
          orderId,
          orderData['amount'],
          (orderData['products'] as List<dynamic>)
              .map(
                (item) => CartItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
          DateTime.parse(
            orderData['dateTime'],
          ),
        ),
      );
    });
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartproducts, double total) async {
    dynamic url = Uri.parse(
        'https://shop-app-6e7fb-default-rtdb.firebaseio.com/orders/$_userId.json?auth=$_authToken');
    final timeStamp = DateTime.now();
    final response = await http.post(
      url,
      body: json.encode(
        {
          'amount': total,
          'dateTime': timeStamp.toIso8601String(),
          'products': cartproducts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        },
      ),
    );
    _orders.insert(
      0,
      OrderItem(
        json.decode(response.body)['name'],
        total,
        cartproducts,
        timeStamp,
      ),
    );
    notifyListeners();
  }
}
