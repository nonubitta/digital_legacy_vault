import 'package:flutter/material.dart';

import '../../core/utils/app_settings_helper.dart';
import '../../core/theme/app_theme.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/category.dart';

class ManageCategoryScreen extends StatefulWidget {
	const ManageCategoryScreen({super.key});

	@override
	State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> {
	static const Map<String, IconData> _iconOptions = {
		'folder': Icons.folder_outlined,
		'account_balance': Icons.account_balance_rounded,
		'savings': Icons.savings_rounded,
		'trending_up': Icons.trending_up_rounded,
		'home': Icons.home_rounded,
		'directions_car': Icons.directions_car_rounded,
		'badge': Icons.badge_outlined,
		'description': Icons.description_outlined,
		'credit_card': Icons.credit_card_rounded,
	};

	static const List<String> _colorOptions = [
		'#4C8DFF',
		'#E8A33D',
		'#34D399',
		'#A78BFA',
		'#F2795A',
		'#2D3E50',
		'#3B5998',
		'#00838F',
	];

	final _db = DatabaseHelper();
	final _appSettings = AppSettingsHelper();

	List<Category> _categories = [];
	Set<String> _disabledSystemCategories = {};
	bool _isLoading = true;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() => _isLoading = true);
		try {
			final results = await Future.wait<dynamic>([
				_db.getCategories(),
				_appSettings.getDisabledSystemCategoryNames(),
			]);
			final categories = results[0] as List<Category>;
			final disabled = results[1] as Set<String>;
			if (!mounted) return;
			setState(() {
				_categories = categories;
				_disabledSystemCategories = disabled;
				_isLoading = false;
			});
		} catch (_) {
			if (!mounted) return;
			setState(() => _isLoading = false);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Failed to load categories.')),
			);
		}
	}

	IconData _iconForName(String? name) => _iconOptions[name] ?? Icons.folder_outlined;

	bool _isSystemCategoryEnabled(Category category) {
		return !_disabledSystemCategories.contains(category.name);
	}

	Future<void> _toggleSystemCategory(Category category, bool enabled) async {
		final previous = Set<String>.from(_disabledSystemCategories);
		setState(() {
			if (enabled) {
				_disabledSystemCategories.remove(category.name);
			} else {
				_disabledSystemCategories.add(category.name);
			}
		});

		try {
			await _appSettings.saveSystemCategoryEnabled(category.name, enabled);
		} catch (_) {
			if (!mounted) return;
			setState(() => _disabledSystemCategories = previous);
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Unable to update category visibility.')),
			);
		}
	}

	Color _parseColor(String? hex) {
		if (hex == null || hex.isEmpty) return AppTheme.accentColor;
		final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
		final value = int.tryParse('FF$normalized', radix: 16);
		if (value == null) return AppTheme.accentColor;
		return Color(value);
	}

	Future<void> _showAddCategoryDialog() async {
		final nameController = TextEditingController();
		final descriptionController = TextEditingController();
		var selectedIcon = 'folder';
		var selectedColor = _colorOptions.first;

		final shouldAdd = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return StatefulBuilder(
					builder: (context, setDialogState) {
						return AlertDialog(
							title: const Text('Add Category'),
							content: SingleChildScrollView(
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										TextField(
											controller: nameController,
											textInputAction: TextInputAction.next,
											decoration: const InputDecoration(
												labelText: 'Category name',
												hintText: 'Example: Insurance policies',
											),
										),
										const SizedBox(height: 12),
										TextField(
											controller: descriptionController,
											minLines: 2,
											maxLines: 3,
											decoration: const InputDecoration(
												labelText: 'Description (optional)',
											),
										),
										const SizedBox(height: 16),
										const Text('Icon'),
										const SizedBox(height: 8),
										Wrap(
											spacing: 8,
											runSpacing: 8,
											children: _iconOptions.entries.map((entry) {
												final isSelected = selectedIcon == entry.key;
												return InkWell(
													onTap: () => setDialogState(() => selectedIcon = entry.key),
													borderRadius: BorderRadius.circular(12),
													child: Container(
														padding: const EdgeInsets.all(10),
														decoration: BoxDecoration(
															borderRadius: BorderRadius.circular(12),
															border: Border.all(
																color: isSelected
																		? Theme.of(context).colorScheme.primary
																		: Colors.grey.shade300,
																width: isSelected ? 2 : 1,
															),
														),
														child: Icon(entry.value, size: 20),
													),
												);
											}).toList(),
										),
										const SizedBox(height: 16),
										const Text('Color'),
										const SizedBox(height: 8),
										Wrap(
											spacing: 10,
											runSpacing: 10,
											children: _colorOptions.map((hex) {
												final isSelected = selectedColor == hex;
												return InkWell(
													onTap: () => setDialogState(() => selectedColor = hex),
													borderRadius: BorderRadius.circular(16),
													child: Container(
														width: 28,
														height: 28,
														decoration: BoxDecoration(
															color: _parseColor(hex),
															shape: BoxShape.circle,
															border: Border.all(
																color: isSelected
																		? Theme.of(context).colorScheme.primary
																		: Colors.transparent,
																width: 2,
															),
														),
													),
												);
											}).toList(),
										),
									],
								),
							),
							actions: [
								TextButton(
									onPressed: () => Navigator.of(dialogContext).pop(false),
									child: const Text('Cancel'),
								),
								FilledButton(
									onPressed: () => Navigator.of(dialogContext).pop(true),
									child: const Text('Add'),
								),
							],
						);
					},
				);
			},
		);

		if (shouldAdd != true) return;

		final name = nameController.text.trim();
		if (name.isEmpty) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Category name is required.')),
			);
			return;
		}

		final exists = _categories.any(
			(category) => category.name.toLowerCase() == name.toLowerCase(),
		);
		if (exists) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('"$name" already exists.')),
			);
			return;
		}

		final nextSortOrder =
				_categories.isEmpty ? 0 : _categories.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

		try {
			await _db.insertCategory(
				Category(
					name: name,
					icon: selectedIcon,
					color: selectedColor,
					description: descriptionController.text.trim().isEmpty
							? null
							: descriptionController.text.trim(),
					sortOrder: nextSortOrder,
				),
			);
			if (!mounted) return;
			await _load();
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('"$name" added.')),
			);
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Unable to add category.')),
			);
		}
	}

	Future<void> _showEditCategoryDialog(Category category) async {
		if (category.isSystem) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('System categories cannot be edited.')),
			);
			return;
		}

		final nameController = TextEditingController(text: category.name);
		final descriptionController =
				TextEditingController(text: category.description ?? '');
		var selectedIcon = category.icon ?? 'folder';
		if (!_iconOptions.containsKey(selectedIcon)) selectedIcon = 'folder';
		var selectedColor = category.color ?? _colorOptions.first;
		if (!_colorOptions.contains(selectedColor)) selectedColor = _colorOptions.first;

		final shouldSave = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return StatefulBuilder(
					builder: (context, setDialogState) {
						return AlertDialog(
							title: const Text('Edit Category'),
							content: SingleChildScrollView(
								child: Column(
									mainAxisSize: MainAxisSize.min,
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										TextField(
											controller: nameController,
											textInputAction: TextInputAction.next,
											decoration: const InputDecoration(
												labelText: 'Category name',
											),
										),
										const SizedBox(height: 12),
										TextField(
											controller: descriptionController,
											minLines: 2,
											maxLines: 3,
											decoration: const InputDecoration(
												labelText: 'Description (optional)',
											),
										),
										const SizedBox(height: 16),
										const Text('Icon'),
										const SizedBox(height: 8),
										Wrap(
											spacing: 8,
											runSpacing: 8,
											children: _iconOptions.entries.map((entry) {
												final isSelected = selectedIcon == entry.key;
												return InkWell(
													onTap: () => setDialogState(() => selectedIcon = entry.key),
													borderRadius: BorderRadius.circular(12),
													child: Container(
														padding: const EdgeInsets.all(10),
														decoration: BoxDecoration(
															borderRadius: BorderRadius.circular(12),
															border: Border.all(
																color: isSelected
																		? Theme.of(context).colorScheme.primary
																		: Colors.grey.shade300,
																width: isSelected ? 2 : 1,
															),
														),
														child: Icon(entry.value, size: 20),
													),
												);
											}).toList(),
										),
										const SizedBox(height: 16),
										const Text('Color'),
										const SizedBox(height: 8),
										Wrap(
											spacing: 10,
											runSpacing: 10,
											children: _colorOptions.map((hex) {
												final isSelected = selectedColor == hex;
												return InkWell(
													onTap: () => setDialogState(() => selectedColor = hex),
													borderRadius: BorderRadius.circular(16),
													child: Container(
														width: 28,
														height: 28,
														decoration: BoxDecoration(
															color: _parseColor(hex),
															shape: BoxShape.circle,
															border: Border.all(
																color: isSelected
																		? Theme.of(context).colorScheme.primary
																		: Colors.transparent,
																width: 2,
															),
														),
													),
												);
											}).toList(),
										),
									],
								),
							),
							actions: [
								TextButton(
									onPressed: () => Navigator.of(dialogContext).pop(false),
									child: const Text('Cancel'),
								),
								FilledButton(
									onPressed: () => Navigator.of(dialogContext).pop(true),
									child: const Text('Save'),
								),
							],
						);
					},
				);
			},
		);

		if (shouldSave != true) return;

		final name = nameController.text.trim();
		if (name.isEmpty) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Category name is required.')),
			);
			return;
		}

		final exists = _categories.any(
			(existing) =>
				existing.id != category.id &&
				existing.name.toLowerCase() == name.toLowerCase(),
		);
		if (exists) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('"$name" already exists.')),
			);
			return;
		}

		try {
			await _db.updateCategory(
				category.copyWith(
					name: name,
					icon: selectedIcon,
					color: selectedColor,
					description: descriptionController.text.trim().isEmpty
							? null
							: descriptionController.text.trim(),
				),
			);
			if (!mounted) return;
			await _load();
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('"$name" updated.')),
			);
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Unable to update category.')),
			);
		}
	}

	Future<void> _confirmDelete(Category category) async {
		if (category.isSystem) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('System categories cannot be deleted.')),
			);
			return;
		}

		final shouldDelete = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Delete Category'),
					content: Text(
						'Delete "${category.name}"?\n\nAll assets in this category will also be deleted.',
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Cancel'),
						),
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(true),
							style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
							child: const Text('Delete'),
						),
					],
				);
			},
		);

		if (shouldDelete != true) return;

		try {
			await _db.deleteCategory(category.id);
			if (!mounted) return;
			await _load();
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('"${category.name}" deleted.')),
			);
		} catch (error) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text(error.toString())),
			);
		}
	}

	Future<void> _persistCategoryOrder() async {
		for (var i = 0; i < _categories.length; i++) {
			final category = _categories[i];
			if (category.sortOrder == i) continue;
			await _db.updateCategory(category.copyWith(sortOrder: i));
		}
	}

	Future<void> _onReorder(int oldIndex, int newIndex) async {
		if (newIndex > oldIndex) newIndex -= 1;

		final reordered = List<Category>.from(_categories);
		final moved = reordered.removeAt(oldIndex);
		reordered.insert(newIndex, moved);

		setState(() => _categories = reordered);

		try {
			await _persistCategoryOrder();
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Unable to save category order.')),
			);
			await _load();
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppTheme.backgroundColor,
			appBar: AppBar(
				title: const Text('Manage Categories'),
				actions: [
					IconButton(
						tooltip: 'Add Category',
						onPressed: _showAddCategoryDialog,
						icon: const Icon(Icons.add),
					),
				],
			),
			body: _isLoading
					? const Center(child: CircularProgressIndicator())
					: _categories.isEmpty
							? Center(
									child: Padding(
										padding: const EdgeInsets.all(24),
										child: Column(
											mainAxisSize: MainAxisSize.min,
											children: [
												Icon(
													Icons.category_outlined,
													size: 64,
													color: Colors.grey.shade500,
												),
												const SizedBox(height: 12),
												const Text('No categories yet'),
												const SizedBox(height: 8),
												Text(
													'Tap + to create your first category.',
													textAlign: TextAlign.center,
													style: TextStyle(color: Colors.grey.shade700),
												),
											],
										),
									),
								)
							: Column(
									children: [
										Padding(
											padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
											child: Row(
												children: [
													Icon(Icons.drag_indicator, size: 16, color: Colors.grey.shade600),
													const SizedBox(width: 6),
													Text(
														'Drag to reorder categories',
														style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
													),
												],
											),
										),
										Expanded(
											child: ReorderableListView.builder(
												padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
												buildDefaultDragHandles: false,
												itemCount: _categories.length,
												onReorder: _onReorder,
												itemBuilder: (_, index) {
													final category = _categories[index];
													return Padding(
														key: ValueKey(category.id),
														padding: const EdgeInsets.only(bottom: 10),
														child: Card(
															child: ListTile(
																contentPadding: const EdgeInsets.symmetric(
																						horizontal: 8,
																						vertical: 8,
																					),
																leading: Row(
																	mainAxisSize: MainAxisSize.min,
																	children: [
																		ReorderableDragStartListener(
																			index: index,
																			child: Icon(
																				Icons.drag_handle,
																				size: 16,
																				color: Colors.grey.shade600,
																			),
																		),
																		const SizedBox(width: 10),
																		CircleAvatar(
																			backgroundColor: _parseColor(category.color),
																			child: Icon(
																				_iconForName(category.icon),
																				color: Colors.white,
																			),
																		),
																	],
																),
																title: Text(category.name),
								
																trailing: category.isSystem
																				? Switch.adaptive(
																						value: _isSystemCategoryEnabled(category),
																						onChanged: (enabled) =>
																								_toggleSystemCategory(category, enabled),
																					)
																		: Row(
																			mainAxisSize: MainAxisSize.min,
																			children: [
																				IconButton(
																					tooltip: 'Edit',
																					onPressed: () => _showEditCategoryDialog(category),
																					icon: const Icon(Icons.edit_outlined),
																				),
																				IconButton(
																					tooltip: 'Delete',
																					onPressed: () => _confirmDelete(category),
																					icon: const Icon(Icons.delete_outline),
																					color: AppTheme.errorColor,
																				),
																			],
																		),
															),
														),
													);
												},
											),
										),
									],
								),
			// Add button moved to AppBar; FAB removed.
		);
	}
}
