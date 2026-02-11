import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String symbol = '¥'}) {
    if (amount >= 100000000) {
      return '$symbol${(amount / 100000000).toStringAsFixed(1)}亿';
    } else if (amount >= 10000) {
      return '$symbol${(amount / 10000).toStringAsFixed(0)}万';
    }
    return '$symbol${NumberFormat('#,###').format(amount.toInt())}';
  }

  static String dateShort(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}周前';
    return DateFormat('MM/dd').format(date);
  }

  static String dateFull(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}周前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月前';
    return '${(diff.inDays / 365).floor()}年前';
  }
}
