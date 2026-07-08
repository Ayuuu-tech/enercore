// Domain models for the vendor side of the app.

class VendorStats {
  final int pendingOrders;
  final int outOfStock;
  final int totalProducts;
  final num monthlyRevenue;

  VendorStats({
    required this.pendingOrders,
    required this.outOfStock,
    required this.totalProducts,
    required this.monthlyRevenue,
  });

  factory VendorStats.fromJson(Map<String, dynamic> json) {
    return VendorStats(
      pendingOrders: (json['pendingOrders'] ?? 0) as int,
      outOfStock: (json['outOfStock'] ?? 0) as int,
      totalProducts: (json['totalProducts'] ?? 0) as int,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0) as num,
    );
  }
}

class VendorProductModel {
  final String id;
  final String title;
  final String brand;
  final String spec;
  final double rating;
  final int reviewsCount;
  final num price;
  final num? originalPrice;
  final bool isAssured;
  final String category;
  final int stock;
  final String vendorId;

  VendorProductModel({
    required this.id,
    required this.title,
    required this.brand,
    required this.spec,
    required this.rating,
    required this.reviewsCount,
    required this.price,
    required this.originalPrice,
    required this.isAssured,
    required this.category,
    required this.stock,
    required this.vendorId,
  });

  factory VendorProductModel.fromJson(Map<String, dynamic> json) {
    return VendorProductModel(
      id: json['id'] as String,
      title: json['title'] ?? '',
      brand: json['brand'] ?? '',
      spec: json['spec'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: (json['reviewsCount'] ?? 0) as int,
      price: json['price'] ?? 0,
      originalPrice: json['originalPrice'],
      isAssured: json['isAssured'] ?? false,
      category: json['category'] ?? '',
      stock: (json['stock'] ?? 0) as int,
      vendorId: json['vendorId'] ?? '',
    );
  }
}

class VendorOrderItemModel {
  final String id;
  final String productId;
  final int quantity;
  final num priceAtPurchase;

  VendorOrderItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory VendorOrderItemModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderItemModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      quantity: (json['quantity'] ?? 0) as int,
      priceAtPurchase: json['priceAtPurchase'] ?? 0,
    );
  }
}

class VendorOrderModel {
  final String id;
  final String orderNumber;
  final num totalAmount;
  final String status;
  final String userId;
  final DateTime createdAt;
  final List<VendorOrderItemModel> items;

  VendorOrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.userId,
    required this.createdAt,
    required this.items,
  });

  factory VendorOrderModel.fromJson(Map<String, dynamic> json) {
    return VendorOrderModel(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] ?? '',
      totalAmount: json['totalAmount'] ?? 0,
      status: json['status'] ?? 'PENDING',
      userId: json['userId'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      items: ((json['items'] ?? []) as List)
          .map((e) => VendorOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalUnits => items.fold(0, (sum, i) => sum + i.quantity);
}
