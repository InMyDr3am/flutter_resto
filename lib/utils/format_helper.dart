import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final format = NumberFormat.currency(
    locale: 'id_ID', 
    symbol: 'Rp. ', 
    decimalDigits: 0,
  );
  return format.format(amount);
}