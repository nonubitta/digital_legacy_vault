import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_settings_helper.dart';
import '../../core/utils/access_code_helper.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/category.dart';
import '../assets/asset_list_screen.dart';
import 'manage_category_screen.dart';
import '../auth/auth_screen.dart';
import '../settings/settings_screen.dart';

class _Navy {
  static const base = AppTheme.backgroundColor;
  static const surface = AppTheme.surfaceColor;
  static const border = AppTheme.navyBorder;
  static const chip = AppTheme.navyChip;
  static const text = AppTheme.textPrimary;
  static const textDim = AppTheme.textSecondary;
  static const positive = AppTheme.navyPositive;
  static const blue = AppTheme.primaryColor;
  static const amber = AppTheme.accentColor;
  static const emerald = AppTheme.secondaryColor;
  static const violet = Color(0xFFA78BFA);
  static const coral = Color(0xFFF2795A);
  // hero gradient ground — deep indigo fading toward the app background
  static const heroDeep = Color(0xFF1B1F3B);
  static const heroMid = Color(0xFF1E2036);
}

IconData _iconForName(String? name) {
  switch (name) {
    case 'account_balance':
      return Icons.account_balance_rounded;
    case 'savings':
      return Icons.savings_rounded;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'badge':
      return Icons.badge_outlined;
    case 'credit_card':
      return Icons.credit_card_rounded;
    default:
      return Icons.folder_rounded;
  }
}

Color _parseColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse('FF' + h, radix: 16);
  return v != null ? Color(v) : fallback;
}

final _accentFallbacks = AppTheme.categoryAccentFallbacks;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DatabaseHelper();
  final _appSettings = AppSettingsHelper();
  List<Category> _categories = [];
  Map<String, int> _categoryCounts = {};
  Map<String, double> _categoryUsdTotals = {};
  Map<String, String> _categorySubtitlePreviews = {};
  String _vaultName = AppSettingsHelper.defaultVaultName;
  bool _showHomeAmounts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final results = await Future.wait<dynamic>([
      _dbHelper.getCategories(),
      _dbHelper.getCategoryCounts(),
      _dbHelper.getCategoryUsdTotals(),
      _appSettings.getVaultName(),
      _appSettings.getShowHomeAmounts(),
      _appSettings.getDisabledSystemCategoryNames(),
    ]);

    final loadedCategories = results[0] as List<Category>;
    final disabledSystemCategories = results[5] as Set<String>;
    final visibleCategories = loadedCategories
        .where(
          (category) =>
              !category.isSystem ||
              !disabledSystemCategories.contains(category.name),
        )
        .toList();
    final systemCategoryPreviews = await Future.wait<MapEntry<String, String>>(
      visibleCategories.where((category) => category.isSystem).map((
        category,
      ) async {
        final assets = await _dbHelper.getAssetsByCategory(category.id);
        final preview = _systemCategoryPreview(
          assets.map((asset) => asset.name).toList(),
        );
        return MapEntry(category.name, preview);
      }),
    );
    setState(() {
      _categories = visibleCategories;
      _categoryCounts = results[1] as Map<String, int>;
      _categoryUsdTotals = results[2] as Map<String, double>;
      _categorySubtitlePreviews = {
        for (final entry in systemCategoryPreviews) entry.key: entry.value,
      };
      _vaultName = results[3] as String;
      _showHomeAmounts = results[4] as bool;
      _isLoading = false;
    });
  }

  int get _totalAssets => _categories
      .where((c) => c.name != 'Debt')
      .fold(0, (sum, category) => sum + _countFor(category.name));
  double get _totalUsd => _categories
      .where((c) => c.name != 'Debt')
      .fold(0.0, (sum, category) => sum + _usdFor(category.name));
  double get _totalDebtUsd => _usdFor('Debt');

  int get _assetCategoriesCount =>
      _categories.where((c) => c.name != 'Debt').length;
  int _countFor(String n) => _categoryCounts[n] ?? 0;
  double _usdFor(String n) => _categoryUsdTotals[n] ?? 0;

  Color _colorFor(Category cat, int i) =>
      _parseColor(cat.color, _accentFallbacks[i % _accentFallbacks.length]);

  String _formatUsd(double v) {
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(2)}';
  }

  String _formatUsdFull(double v) {
    final rounded = v.round();
    final digits = rounded.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '${rounded < 0 ? "-" : ""}\$$buf';
  }

  String _homeAmountDisplay() {
    return _showHomeAmounts ? _formatUsdFull(_totalUsd - _totalDebtUsd) : '*****';
  }

  String _assetsAmountDisplay() {
    return _showHomeAmounts ? _formatUsdFull(_totalUsd) : '*****';
  }

  String _debtAmountDisplay() {
    return _showHomeAmounts ? _formatUsdFull(_totalDebtUsd) : '*****';
  }

  String _categoryAmountDisplay(double value) {
    return _showHomeAmounts ? _formatUsd(value) : '*****';
  }

  String _systemCategoryPreview(List<String> names) {
    final nonEmpty = names.where((name) => name.trim().isNotEmpty).toList();
    if (nonEmpty.isEmpty) return 'No items added';
    if (nonEmpty.length == 1) return nonEmpty.first;
    if (nonEmpty.length == 2) return nonEmpty.join(', ');
    return '${nonEmpty.take(2).join(', ')}, ...';
  }

  void _toggleAmounts() {
    setState(() => _showHomeAmounts = !_showHomeAmounts);
  }

  void _openCategory(Category cat) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AssetListScreen(category: cat)));
    _reload();
  }

  void _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    _reload();
  }

  void _openManageCategories() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManageCategoryScreen()));
    _reload();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _Navy.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.inter(color: _Navy.text)),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: _Navy.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: _Navy.textDim)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Navy.base,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(
              child: _buildCurvedPanel(
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(64),
                        child: Center(
                          child: CircularProgressIndicator(color: _Navy.blue),
                        ),
                      )
                    : _buildCardGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Curved gradient hero — title row, net worth + eye toggle, distribution
  // line, and the Total Assets / Debt split.
  Widget _buildHero() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(44),
        bottomRight: Radius.circular(44),
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_Navy.heroDeep, _Navy.heroMid, _Navy.base],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color.lerp(_Navy.blue, _Navy.heroDeep, 0.3)!.withOpacity(0.4),
                    Color.lerp(_Navy.blue, _Navy.heroDeep, 0.3)!.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _vaultName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _heroIconButton(Icons.settings_rounded, _openSettings),
                    const SizedBox(width: 8),
                    _heroIconButton(Icons.logout_rounded, _logout),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'NET WORTH',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _toggleAmounts,
                      child: Icon(
                        _showHomeAmounts
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 15,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isLoading ? '\u2013' : _homeAmountDisplay(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSplitBar(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Assets',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoading ? '\u2013' : _assetsAmountDisplay(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Debt',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading ? '\u2013' : _debtAmountDisplay(),
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // Thin distribution line: assets (white) vs debt (dim remainder).
  Widget _buildSplitBar() {
    final assets = _totalUsd;
    final debt = _totalDebtUsd;
    final total = assets + debt;
    final assetsFraction = total > 0 ? (assets / total).clamp(0.0, 1.0) : 1.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            Expanded(
              flex: (assetsFraction * 1000).round().clamp(1, 1000),
              child: Container(color: Colors.white),
            ),
            Expanded(
              flex: (1000 - (assetsFraction * 1000).round()).clamp(1, 1000),
              child: Container(color: Colors.white.withOpacity(0.18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Row(
        children: [
          Text(
            'Categories',
            style: GoogleFonts.inter(
              color: _Navy.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openManageCategories,
            child: Text(
              'Manage',
              style: GoogleFonts.inter(
                color: _Navy.blue,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Rounded-top panel overlapping the hero's bottom edge — this overlap +
  // radius + shadow is what reads as the curve separating hero from content.
  Widget _buildCurvedPanel(Widget content) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        decoration: BoxDecoration(
          color: _Navy.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            _buildSectionHeader(),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid() {
    if (_categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No categories yet',
            style: GoogleFonts.inter(color: _Navy.textDim),
          ),
        ),
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < _categories.length; i++) {
      rows.add(_buildCategoryRow(_categories[i], i));
      if (i + 1 < _categories.length) {
        rows.add(Container(height: 1, color: _Navy.border, margin: const EdgeInsets.only(left: 24)));
      }
    }
    return Column(children: rows);
  }

  Widget _buildCategoryRow(Category cat, int index) {
    final count = _countFor(cat.name);
    final usdLabel = _categoryAmountDisplay(_usdFor(cat.name));
    final color = _colorFor(cat, index);
    final icon = _iconForName(cat.icon);
    final subtitle = cat.isSystem
        ? (_categorySubtitlePreviews[cat.name] ?? 'No items added')
        : (cat.description ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCategory(cat),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _iconBadge(icon, color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: GoogleFonts.inter(
                        color: _Navy.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle.isEmpty ? '$count ${count == 1 ? "item" : "items"}' : subtitle,
                      style: GoogleFonts.inter(color: _Navy.textDim, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                usdLabel,
                style: GoogleFonts.inter(
                  color: _Navy.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _Navy.base,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 17),
    );
  }
}
