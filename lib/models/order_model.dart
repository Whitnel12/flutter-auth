import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  unpaid, // Belum dibayar
  paid, // Sudah dibayar, menunggu konfirmasi admin
  confirmed, // Dikonfirmasi admin, sedang diproses
  shipped, // Dikirim
  delivered, // Selesai/diterima
  cancelled // Dibatalkan
}

enum PaymentStatus {
  pending, // Pembayaran sedang diproses
  success, // Pembayaran berhasil
  failed, // Pembayaran gagal
  expired, // Pembayaran expired
  cancelled // Pembayaran dibatalkan
}

class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus? paymentStatus; // Status pembayaran terpisah
  final DateTime orderDate;
  final DateTime? paymentDate;
  final DateTime? confirmedDate;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final Map<String, dynamic>? paymentDetails;
  final String? paymentUrl;
  final String? shippingAddress;
  final String? customerName;
  final String? customerPhone;
  final String? adminNotes;

  OrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.paymentStatus,
    required this.orderDate,
    this.paymentDate,
    this.confirmedDate,
    this.shippedDate,
    this.deliveredDate,
    this.paymentDetails,
    this.paymentUrl,
    this.shippingAddress,
    this.customerName,
    this.customerPhone,
    this.adminNotes,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse payment status dari paymentDetails
    PaymentStatus? paymentStatus;
    if (data['paymentDetails'] != null) {
      final paymentDetails = data['paymentDetails'] as Map<String, dynamic>;
      final paymentStatusStr = paymentDetails['payment_status'] as String?;
      print('🔍 Parsing payment status for order ${doc.id}:');
      print('   - Raw paymentDetails: $paymentDetails');
      print('   - payment_status string: $paymentStatusStr');

      if (paymentStatusStr != null) {
        paymentStatus = _parsePaymentStatus(paymentStatusStr);
        print('   - Parsed payment status: $paymentStatus');
      } else {
        print('   - No payment_status found in paymentDetails');
        // Coba cari di field lain jika tidak ada di payment_status
        final transactionStatus =
            paymentDetails['transaction_status'] as String?;
        if (transactionStatus != null) {
          print('   - Found transaction_status: $transactionStatus');
          // Map transaction_status ke payment_status
          if (transactionStatus == 'settlement' ||
              transactionStatus == 'capture') {
            paymentStatus = PaymentStatus.success;
            print('   - Mapped transaction_status to PaymentStatus.success');
          } else if (transactionStatus == 'pending') {
            paymentStatus = PaymentStatus.pending;
            print('   - Mapped transaction_status to PaymentStatus.pending');
          } else if (transactionStatus == 'deny' ||
              transactionStatus == 'expire' ||
              transactionStatus == 'cancel') {
            paymentStatus = PaymentStatus.failed;
            print('   - Mapped transaction_status to PaymentStatus.failed');
          }
        }
      }
    } else {
      print('🔍 No paymentDetails found for order ${doc.id}');
    }

    return OrderModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: _parseStatus(data['status'] ?? 'unpaid'),
      paymentStatus: paymentStatus,
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] as Timestamp).toDate()
          : null,
      confirmedDate: data['confirmedDate'] != null
          ? (data['confirmedDate'] as Timestamp).toDate()
          : null,
      shippedDate: data['shippedDate'] != null
          ? (data['shippedDate'] as Timestamp).toDate()
          : null,
      deliveredDate: data['deliveredDate'] != null
          ? (data['deliveredDate'] as Timestamp).toDate()
          : null,
      paymentDetails: data['paymentDetails'],
      paymentUrl: data['paymentUrl'],
      shippingAddress: data['shippingAddress'],
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      adminNotes: data['adminNotes'],
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'unpaid':
        return OrderStatus.unpaid;
      case 'paid':
        return OrderStatus.paid;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unpaid;
    }
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    print('🔍 Parsing payment status string: "$status"');

    switch (status.toLowerCase()) {
      case 'pending':
        print('   -> PaymentStatus.pending');
        return PaymentStatus.pending;
      case 'success':
      case 'settlement':
      case 'capture':
        print('   -> PaymentStatus.success');
        return PaymentStatus.success;
      case 'failed':
      case 'deny':
      case 'expire':
      case 'cancel':
      case 'cancelled':
        print('   -> PaymentStatus.failed');
        return PaymentStatus.failed;
      case 'expired':
        print('   -> PaymentStatus.expired');
        return PaymentStatus.expired;
      case 'cancelled':
        print('   -> PaymentStatus.cancelled');
        return PaymentStatus.cancelled;
      default:
        print('   -> PaymentStatus.pending (default)');
        return PaymentStatus.pending;
    }
  }

  String get statusText {
    // Jika ada payment status, gunakan itu untuk menentukan text
    if (paymentStatus != null) {
      switch (paymentStatus!) {
        case PaymentStatus.pending:
          return 'Menunggu Pembayaran';
        case PaymentStatus.success:
          switch (status) {
            case OrderStatus.paid:
              return 'Menunggu Konfirmasi';
            case OrderStatus.confirmed:
              return 'Dikonfirmasi';
            case OrderStatus.shipped:
              return 'Dikirim';
            case OrderStatus.delivered:
              return 'Selesai';
            default:
              return 'Menunggu Konfirmasi';
          }
        case PaymentStatus.failed:
          return 'Pembayaran Gagal';
        case PaymentStatus.expired:
          return 'Pembayaran Expired';
        case PaymentStatus.cancelled:
          return 'Pembayaran Dibatalkan';
      }
    }

    // Fallback ke status pesanan
    switch (status) {
      case OrderStatus.unpaid:
        return 'Belum Bayar';
      case OrderStatus.paid:
        return 'Menunggu Konfirmasi';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.shipped:
        return 'Dikirim';
      case OrderStatus.delivered:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get statusColor {
    // Jika ada payment status, gunakan itu untuk menentukan color
    if (paymentStatus != null) {
      switch (paymentStatus!) {
        case PaymentStatus.pending:
          return Colors.orange;
        case PaymentStatus.success:
          switch (status) {
            case OrderStatus.paid:
              return Colors.orange;
            case OrderStatus.confirmed:
              return Colors.blue;
            case OrderStatus.shipped:
              return Colors.purple;
            case OrderStatus.delivered:
              return Colors.green;
            default:
              return Colors.orange;
          }
        case PaymentStatus.failed:
        case PaymentStatus.expired:
        case PaymentStatus.cancelled:
          return Colors.red;
      }
    }

    // Fallback ke status pesanan
    switch (status) {
      case OrderStatus.unpaid:
        return Colors.red;
      case OrderStatus.paid:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  // Helper method untuk menentukan apakah pesanan harus muncul di tab "Belum Bayar"
  bool get isUnpaid {
    print('🔍 Checking isUnpaid for order $id:');
    print('   - Status: $status');
    print('   - Payment Status: $paymentStatus');
    print('   - Payment Details: $paymentDetails');

    // Jika payment status adalah success, maka tidak boleh muncul di "Belum Bayar"
    if (paymentStatus == PaymentStatus.success) {
      print('   ❌ Payment status is success, returning false');
      return false;
    }

    // Jika status pesanan sudah bukan unpaid, maka tidak boleh muncul di "Belum Bayar"
    if (status != OrderStatus.unpaid) {
      print('   ❌ Order status is not unpaid, returning false');
      return false;
    }

    // Cek paymentDetails untuk memastikan tidak ada pembayaran yang berhasil
    if (paymentDetails != null) {
      final paymentDetailsMap = paymentDetails as Map<String, dynamic>;
      final paymentStatusStr = paymentDetailsMap['payment_status'] as String?;
      final transactionStatus =
          paymentDetailsMap['transaction_status'] as String?;

      print('   - payment_status from details: $paymentStatusStr');
      print('   - transaction_status from details: $transactionStatus');

      // Jika ada indikasi pembayaran berhasil di paymentDetails
      if (paymentStatusStr == 'success' ||
          transactionStatus == 'settlement' ||
          transactionStatus == 'capture') {
        print('   ❌ Payment details indicate success, returning false');
        return false;
      }
    }

    // Hanya muncul di "Belum Bayar" jika:
    // 1. Status pesanan adalah unpaid DAN
    // 2. Payment status adalah null (belum ada pembayaran) ATAU
    // 3. Payment status adalah failed/expired/cancelled
    final result = paymentStatus == null ||
        paymentStatus == PaymentStatus.failed ||
        paymentStatus == PaymentStatus.expired ||
        paymentStatus == PaymentStatus.cancelled;

    print('   ✅ Final result: $result');
    return result;
  }

  // Helper method untuk menentukan apakah pesanan harus muncul di tab "Menunggu"
  bool get isPending {
    print('🔍 Checking isPending for order $id:');
    print('   - Status: $status');
    print('   - Payment Status: $paymentStatus');
    print('   - Payment Details: $paymentDetails');

    // Jika payment status adalah success dan status pesanan adalah paid,
    // maka muncul di "Menunggu" (menunggu konfirmasi admin)
    if (paymentStatus == PaymentStatus.success && status == OrderStatus.paid) {
      print('   ✅ Payment success and order paid, returning true');
      return true;
    }

    // Cek paymentDetails untuk pembayaran berhasil
    if (paymentDetails != null) {
      final paymentDetailsMap = paymentDetails as Map<String, dynamic>;
      final paymentStatusStr = paymentDetailsMap['payment_status'] as String?;
      final transactionStatus =
          paymentDetailsMap['transaction_status'] as String?;

      // Jika ada indikasi pembayaran berhasil dan status pesanan adalah paid
      if ((paymentStatusStr == 'success' ||
              transactionStatus == 'settlement' ||
              transactionStatus == 'capture') &&
          status == OrderStatus.paid) {
        print(
            '   ✅ Payment details indicate success and order paid, returning true');
        return true;
      }
    }

    // Jika payment status adalah pending, maka muncul di "Menunggu"
    if (paymentStatus == PaymentStatus.pending) {
      print('   ✅ Payment pending, returning true');
      return true;
    }

    // Cek paymentDetails untuk pembayaran pending
    if (paymentDetails != null) {
      final paymentDetailsMap = paymentDetails as Map<String, dynamic>;
      final paymentStatusStr = paymentDetailsMap['payment_status'] as String?;
      final transactionStatus =
          paymentDetailsMap['transaction_status'] as String?;

      if (paymentStatusStr == 'pending' || transactionStatus == 'pending') {
        print('   ✅ Payment details indicate pending, returning true');
        return true;
      }
    }

    print('   ❌ No conditions met, returning false');
    return false;
  }

  // Helper method untuk menentukan apakah pesanan harus muncul di tab "Dikonfirmasi"
  bool get isConfirmed {
    print('🔍 Checking isConfirmed for order $id:');
    print('   - Status: $status');
    print('   - Payment Status: $paymentStatus');

    // Hanya muncul di "Dikonfirmasi" jika status pesanan adalah confirmed
    if (status == OrderStatus.confirmed) {
      print('   ✅ Order status is confirmed, returning true');
      return true;
    }

    // Jika status pesanan adalah shipped, juga muncul di "Dikonfirmasi"
    if (status == OrderStatus.shipped) {
      print('   ✅ Order status is shipped, returning true');
      return true;
    }

    print('   ❌ Order status is not confirmed or shipped, returning false');
    return false;
  }

  // Helper method untuk menentukan apakah pesanan harus muncul di tab "Selesai"
  bool get isCompleted {
    return status == OrderStatus.delivered;
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items,
      'totalAmount': totalAmount,
      'status': status.name,
      'orderDate': Timestamp.fromDate(orderDate),
      'paymentDate':
          paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
      'confirmedDate':
          confirmedDate != null ? Timestamp.fromDate(confirmedDate!) : null,
      'shippedDate':
          shippedDate != null ? Timestamp.fromDate(shippedDate!) : null,
      'deliveredDate':
          deliveredDate != null ? Timestamp.fromDate(deliveredDate!) : null,
      'paymentDetails': paymentDetails,
      'paymentUrl': paymentUrl,
      'shippingAddress': shippingAddress,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'adminNotes': adminNotes,
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    List<Map<String, dynamic>>? items,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? orderDate,
    DateTime? paymentDate,
    DateTime? confirmedDate,
    DateTime? shippedDate,
    DateTime? deliveredDate,
    Map<String, dynamic>? paymentDetails,
    String? paymentUrl,
    String? shippingAddress,
    String? customerName,
    String? customerPhone,
    String? adminNotes,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderDate: orderDate ?? this.orderDate,
      paymentDate: paymentDate ?? this.paymentDate,
      confirmedDate: confirmedDate ?? this.confirmedDate,
      shippedDate: shippedDate ?? this.shippedDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }
}
