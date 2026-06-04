import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  final int _selectedNav = -1; // Sub-marketplace navigation
  int _selectedThumb = 0;

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
                      const SizedBox(height: 12),
                      _productImageSection(),
                      const SizedBox(height: 16),
                      _productInfoCard(),
                      const SizedBox(height: 16),
                      _checkoutPanel(),
                      const SizedBox(height: 16),
                      _descriptionCard(),
                      const SizedBox(height: 16),
                      _specsCard(),
                      const SizedBox(height: 16),
                      _reviewsCard(),
                      const SizedBox(height: 16),
                      _sellerCard(),
                      const SizedBox(height: 18),
                      _recommendationsCard(),
                      const SizedBox(height: 24),
                      _footer(),
                      const SizedBox(height: 12),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: const [
          Text('Marketplace', style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600)),
          Text('  ›  ', style: TextStyle(color: _slateLight, fontSize: 11)),
          Text('Solar Panels', style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600)),
          Text('  ›  ', style: TextStyle(color: _slateLight, fontSize: 11)),
          Text('550W Mono PV', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Product Images Section ─────────────────────────────────────────────────
  Widget _productImageSection() {
    final thumbs = [
      'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&fit=crop&q=80',
      'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=100&fit=crop&q=80',
      'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=100&fit=crop&q=80',
      'https://images.unsplash.com/photo-1548613053-220a297d2645?w=100&fit=crop&q=80',
    ];

    return _card_(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(thumbs[_selectedThumb]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: thumbs.asMap().entries.map((e) {
              final active = _selectedThumb == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedThumb = e.key),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: active ? _teal : _cardBorder, width: active ? 2 : 1),
                    image: DecorationImage(
                      image: NetworkImage(e.value),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Product Info Card ──────────────────────────────────────────────────────
  Widget _productInfoCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '550W Monocrystalline PV Module',
            style: TextStyle(color: _slateDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Lumos Energy',
                style: TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Verified Seller',
                  style: TextStyle(color: _teal, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(5, (index) => const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 14)),
              const SizedBox(width: 6),
              const Text(
                '4.8 (156 Reviews)',
                style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: const [
                  Text(
                    '₹18,450',
                    style: TextStyle(color: _slateDark, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '/ module',
                    style: TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                ),
                child: const Text(
                  'In Stock',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 9.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),
          // Short specs grid
          _shortSpecRow('Peak power', '550W'),
          _shortSpecRow('Efficiency', '22.5%'),
          _shortSpecRow('Dimensions', '2278 x 1134 x 35 mm'),
          _shortSpecRow('Weight', '28.6 kg'),
          _shortSpecRow('Warranty', '25 years'),
        ],
      ),
    );
  }

  Widget _shortSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Quantity & Add to Cart Panel ───────────────────────────────────────────
  Widget _checkoutPanel() {
    return _card_(
      child: Column(
        children: [
          Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cardBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: _slateDark, size: 16),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: _slateDark, size: 16),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add to Cart Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: const Text('ADD TO CART', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Buy Now button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _teal, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: _teal,
              ),
              onPressed: () {},
              child: const Text('Buy Now', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.local_shipping_outlined, color: _slateLight, size: 14),
              SizedBox(width: 6),
              Text(
                'Standard delivery: 3-5 days.',
                style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Product Description ────────────────────────────────────────────────────
  Widget _descriptionCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Product Description',
            style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            "This 550W monocrystalline module incorporates state-of-the-art half-cut cell technology to yield highly premium, optimal energy conversion rates even in low light and partially shaded conditions. Equipped with durable tempered glass panels and robust anti-corrosive frames designed to withstand harsh weather patterns.",
            style: TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Technical Specs (Accordion) ────────────────────────────────────────────
  Widget _specsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Technical Specifications',
            style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 18),
        ],
      ),
    );
  }

  // ── Customer Reviews ───────────────────────────────────────────────────────
  Widget _reviewsCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Customer Reviews',
                style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                'Write a Review',
                style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _reviewItem('Suresh P.', 'Excellent efficiency. Easy to install and durable under harsh weather.', '2 days ago'),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          _reviewItem('Ramesh K.', 'Very swift delivery. Packaging was excellent, no cracks/scratches.', '1 week ago'),
        ],
      ),
    );
  }

  Widget _reviewItem(String name, String content, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            Text(
              time,
              style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 12)),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.4),
        ),
      ],
    );
  }

  // ── Seller Card ────────────────────────────────────────────────────────────
  Widget _sellerCard() {
    return _card_(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1560179707-f14e90ef3623?w=80&fit=crop&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Lumos Energy',
                      style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '4.9 Seller Rating',
                      style: TextStyle(color: Color(0xFFF5A623), fontSize: 10.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sellerStat('Response', 'Avg. 2h'),
              _sellerStat('Total Sales', '25k+'),
              _sellerStat('Location', 'Gujarat, India'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _teal, width: 1.2),
                  ),
                  child: const Center(
                    child: Text('Chat Seller', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _teal, width: 1.2),
                  ),
                  child: const Center(
                    child: Text('Visit Store', style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sellerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  // ── recommendations Card ───────────────────────────────────────────────────
  Widget _recommendationsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You May Also Like',
          style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _recomCard('440W Bifacial Panel', '₹15,200', 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=200&fit=crop&q=80'),
              const SizedBox(width: 12),
              _recomCard('Solar Cable (100m)', '₹9,800', 'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=200&fit=crop&q=80'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recomCard(String title, String price, String img) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(img),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Column(
      children: [
        const Text(
          '© 2025 SolarMarket Operations. All rights reserved.',
          style: TextStyle(
            color: _slateLight,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: ['Terms of Service', '  ·  ', 'Privacy Policy', '  ·  ', 'Support']
              .map((t) => Text(
                    t,
                    style: TextStyle(
                      color: ['·'].any(t.contains) ? _slateLight.withValues(alpha: 0.4) : _slateLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
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

  // ── Card helper ────────────────────────────────────────────────────────────
  Widget _card_({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}
