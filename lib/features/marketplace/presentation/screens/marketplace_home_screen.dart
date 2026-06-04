import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  int _selectedFilter = 0;
  final int _selectedNav = -1; // Sub-marketplace navigation

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _breadcrumbs(),
                      const SizedBox(height: 14),
                      _searchBar(),
                      const SizedBox(height: 16),
                      _categoriesRow(),
                      const SizedBox(height: 18),
                      _resultsInfoRow(),
                      const SizedBox(height: 14),
                      _productCard(
                        image: 'assets/images/panel_warehouse.jpg', // Placeholder logic is beautiful, we can draw a premium decorative banner card
                        brand: 'LUMOS ENERGY',
                        title: '550W Monocrystalline PV Module',
                        spec: '22.5% Efficiency | Half-cut Cell Tech',
                        rating: '4.8',
                        reviewsCount: '156',
                        price: '₹18,450',
                        originalPrice: '₹21,000',
                        isAssured: true,
                        dummyIndex: 0,
                      ),
                      const SizedBox(height: 16),
                      _productCard(
                        image: 'assets/images/panel_sky.jpg',
                        brand: 'ECOPOWER',
                        title: '440W Bifacial Dual Glass Panel',
                        spec: 'High Output | 30-year Warranty',
                        rating: '4.9',
                        reviewsCount: '82',
                        price: '₹15,200',
                        originalPrice: null,
                        isAssured: true,
                        dummyIndex: 1,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/logo.png',
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text(
            'Enercore',
            style: TextStyle(
              color: _teal,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&fit=crop&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  Widget _breadcrumbs() {
    return Row(
      children: const [
        Text('Home', style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w600)),
        Text('  ›  ', style: TextStyle(color: _slateLight, fontSize: 11.5)),
        Text('Marketplace', style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w600)),
        Text('  ›  ', style: TextStyle(color: _slateLight, fontSize: 11.5)),
        Text('Solar Panels', style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _searchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Row(
        children: const [
          Icon(Icons.search_rounded, color: _slateLight, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search solar equipment...',
                hintStyle: TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Categories Row ─────────────────────────────────────────────────────────
  Widget _categoriesRow() {
    final cats = ['All', 'Solar Panels', 'Inverters', 'Cables'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: cats.asMap().entries.map((e) {
          final active = _selectedFilter == e.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _teal : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? _teal : _cardBorder, width: 1),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: active ? Colors.white : _slateLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Results Info Row ───────────────────────────────────────────────────────
  Widget _resultsInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '124 products',
          style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        Row(
          children: const [
            Text(
              'Relevance',
              style: TextStyle(color: _slateDark, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, color: _slateDark, size: 14),
            SizedBox(width: 14),
            Icon(Icons.filter_list_rounded, color: _teal, size: 14),
            SizedBox(width: 4),
            Text(
              'Filter',
              style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  // ── Product Card Component ─────────────────────────────────────────────────
  Widget _productCard({
    required String image,
    required String brand,
    required String title,
    required String spec,
    required String rating,
    required String reviewsCount,
    required String price,
    required String? originalPrice,
    required bool isAssured,
    required int dummyIndex,
  }) {
    return GestureDetector(
      onTap: () => context.push('/product-detail'),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      image: DecorationImage(
                        image: NetworkImage(
                          dummyIndex == 0
                              ? 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&fit=crop&q=80'
                              : 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=400&fit=crop&q=80',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border_rounded, color: _slateLight, size: 16),
                  ),
                ),
              ],
            ),
            // Specs and text
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      brand,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(color: _slateDark, fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec,
                    style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(color: _slateDark, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewsCount)',
                        style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(color: _slateDark, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          originalPrice,
                          style: const TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w500, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                  if (isAssured) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded, color: _teal, size: 10),
                          SizedBox(width: 4),
                          Text(
                            'Platform assured',
                            style: TextStyle(color: _teal, fontSize: 9, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _teal, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: _teal,
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_cart_outlined, size: 14),
                      label: const Text('Add to Cart', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.solar_power_rounded, 'Plants'),
      (Icons.sensors_rounded, 'Telemetry'),
      (Icons.receipt_long_rounded, 'Billing'),
      (Icons.confirmation_number_outlined, 'Tickets'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    final routes = ['/client-dashboard', '/solar-grid', '/telemetry', '/billing', '/tickets', '/profile'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedNav == i;
          return GestureDetector(
            onTap: () {
              context.push(routes[i]);
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    color: active ? _teal : _slateLight.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: active ? _teal : _slateLight.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
