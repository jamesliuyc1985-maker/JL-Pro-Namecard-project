import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import '../models/product.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<CrmProvider>(builder: (context, crm, _) {
      final allProducts = crm.products;
      final products = _selectedCategory == 'all'
          ? allProducts
          : allProducts.where((p) => p.category == _selectedCategory).toList();

      return SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(children: [
              Text('${products.length} 款产品', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              const Text('能道再生株式会社', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          Expanded(child: _buildProductList(products)),
        ]),
      );
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(children: [
        const Icon(Icons.science, color: AppTheme.primaryPurple, size: 24),
        const SizedBox(width: 10),
        const Text('产品目录', style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'key': 'all', 'label': '全部', 'icon': Icons.apps, 'color': AppTheme.primaryPurple},
      {'key': 'exosome', 'label': '外泌体', 'icon': Icons.bubble_chart, 'color': const Color(0xFF00B894)},
      {'key': 'nad', 'label': 'NAD+', 'icon': Icons.flash_on, 'color': const Color(0xFFE17055)},
      {'key': 'nmn', 'label': 'NMN', 'icon': Icons.medication, 'color': const Color(0xFF0984E3)},
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['key'];
          final color = cat['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(cat['icon'] as IconData, size: 14, color: isSelected ? Colors.white : color),
                const SizedBox(width: 4),
                Text(cat['label'] as String),
              ]),
              onSelected: (_) => setState(() => _selectedCategory = cat['key'] as String),
              selectedColor: color,
              backgroundColor: AppTheme.cardBgLight,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('暂无产品', style: TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) => _productCard(context, products[index]),
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    Color catColor;
    IconData catIcon;
    switch (product.category) {
      case 'exosome': catColor = const Color(0xFF00B894); catIcon = Icons.bubble_chart; break;
      case 'nad': catColor = const Color(0xFFE17055); catIcon = Icons.flash_on; break;
      case 'nmn': catColor = const Color(0xFF0984E3); catIcon = Icons.medication; break;
      default: catColor = AppTheme.primaryPurple; catIcon = Icons.science; break;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: catColor.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(catIcon, color: catColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 3),
            Text(product.specification, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(ProductCategory.label(product.category), style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text(product.code, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Formatters.currency(product.retailPrice), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text('零售/瓶', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 10)),
          ]),
        ]),
      ),
    );
  }
}
