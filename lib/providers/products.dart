import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';
import 'package:shop_app/providers/product.dart';

class Products with ChangeNotifier {
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

  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts({bool filterByUser = false}) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
    dynamic url = Uri.parse(
        'https://shop-app-6e7fb-default-rtdb.firebaseio.com/products.json?auth=$_authToken&$filterString');
    dynamic fUrl = Uri.parse(
        'https://shop-app-6e7fb-default-rtdb.firebaseio.com/userFavorites/$_userId.json?auth=$_authToken');
    try {
      final response = await http.get(url);

      if (response.body == 'null') {
        return;
      }

      final favoriteResponse = await http.get(fUrl);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final favoriteData = json.decode(favoriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach(
        (prodId, prodData) {
          loadedProducts.add(
            Product(
              id: prodId,
              title: prodData['title'] as String,
              description: prodData['description'] as String,
              price: prodData['price'] as double,
              imageUrl: prodData['imageUrl'] as String,
              isFavorite: (favoriteData == null
                  ? false
                  : favoriteData[prodId] ?? false) as bool,
            ),
          );
        },
      );
      _items = loadedProducts;
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addProduct(Product product) async {
    dynamic url = Uri.parse(
        'https://shop-app-6e7fb-default-rtdb.firebaseio.com/products.json?auth=$_authToken');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': _userId,
        }),
      );
      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(response.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      dynamic url = Uri.parse(
          'https://shop-app-6e7fb-default-rtdb.firebaseio.com/products/$id.json?auth=$_authToken');
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print('...');
    }
  }

  Future<void> deleteProduct(String id) async {
    dynamic url = Uri.parse(
        'https://shop-app-6e7fb-default-rtdb.firebaseio.com/products/$id.json?auth=$_authToken');
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product.');
    }
    existingProduct = null;
  }
}
