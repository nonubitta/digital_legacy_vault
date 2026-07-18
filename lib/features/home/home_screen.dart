import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_settings_helper.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/category.dart';
import '../assets/asset_list_screen.dart';
import 'manage_category_screen.dart';
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

  int get _totalAssets =>
      _categories
          .where((c) => c.name != 'Debt')
          .fold(0, (sum, category) => sum + _countFor(category.name));
  double get _totalUsd =>
      _categories
          .where((c) => c.name != 'Debt')
          .fold(0.0, (sum, category) => sum + _usdFor(category.name));

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
    return _showHomeAmounts ? _formatUsdFull(_totalUsd) : '*****';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Navy.base,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildGreeting()),
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildSectionHeader()),
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(64),
                      child: Center(
                        child: CircularProgressIndicator(color: _Navy.blue),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverToBoxAdapter(child: _buildCardGrid()),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Navy.chip,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: _Navy.text,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _vaultName,
              style: GoogleFonts.inter(
                color: _Navy.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _openSettings,
            style: IconButton.styleFrom(
              backgroundColor: _Navy.chip,
              shape: const CircleBorder(),
            ),
            icon: const Icon(
              Icons.settings_rounded,
              color: _Navy.text,
              size: 18,
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.inter(color: _Navy.textDim, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Your holdings',
            style: GoogleFonts.inter(
              color: _Navy.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C2A5E), Color(0xFF131C40)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF263466)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TOTAL ASSETS TRACKED',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isLoading ? '\u2013' : _homeAmountDisplay(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _Navy.positive.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_assetCategoriesCount categories \u00b7 $_totalAssets items',
                  style: GoogleFonts.inter(
                    color: _Navy.positive,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSplitBar(),
          ],
        ),
      ),
    );
  }

    Widget _buildSplitBar() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    final nonDebt = _categories.where((c) => c.name != 'Debt').toList();
    final values = nonDebt.map((c) => _usdFor(c.name)).toList();
      final total = values.fold(0.0, (a, b) => a + b);
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 5,
          child: Row(
            children: [
              for (var i = 0; i < nonDebt.length; i++)
                Expanded(
                  flex: total > 0
                      ? (values[i] * 1000 / total).round().clamp(1, 100000)
                      : 1,
                  child: Container(color: _colorFor(nonDebt.elementAt(i), i)),
                ),
            ],
          ),
        ),
      );
    }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
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
    for (var i = 0; i < _categories.length; i += 2) {
      final isLast = i + 1 >= _categories.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCard(_categories[i], i, wide: isLast)),
            if (!isLast) ...[
              const SizedBox(width: 10),
              Expanded(child: _buildCard(_categories[i + 1], i + 1)),
            ],
          ],
        ),
      );
      if (i + 2 < _categories.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildCard(Category cat, int index, {bool wide = false}) {
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: _Navy.surface,
            border: Border.all(color: _Navy.border),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 3, color: color),
              Padding(
                padding: const EdgeInsets.all(10),
                child: wide
                    ? Row(
                        children: [
                          _iconBadge(icon, color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: GoogleFonts.inter(
                                    color: _Navy.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.inter(
                                    color: _Navy.textDim,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                usdLabel,
                                style: GoogleFonts.inter(
                                  color: _Navy.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '$count ${count == 1 ? "item" : "items"}',
                                style: GoogleFonts.inter(
                                  color: _Navy.textDim,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _iconBadge(icon, color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: GoogleFonts.inter(
                                    color: _Navy.text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: GoogleFonts.inter(
                              color: _Navy.textDim,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            usdLabel,
                            style: GoogleFonts.inter(
                              color: _Navy.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 0),
                          Text(
                            '$count ${count == 1 ? "item" : "items"}',
                            style: GoogleFonts.inter(
                              color: _Navy.textDim,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
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
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 13),
    );
  }
}


