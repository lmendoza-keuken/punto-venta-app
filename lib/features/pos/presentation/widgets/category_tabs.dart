import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class CategoryTabs extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const _webScrollBehavior = WebScrollBehavior();

  @override
  Widget build(BuildContext context) {
    final displayedCategories = widget.categories.contains('Todo')
        ? widget.categories
        : ['Todo', ...widget.categories];

    return SizedBox(
      height: AppDimensions.categoryTabHeight + 10,
      child: ScrollConfiguration(
        behavior: _webScrollBehavior,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM),
              physics: const BouncingScrollPhysics(),
              itemCount: displayedCategories.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppDimensions.paddingXS),
              itemBuilder: (context, index) {
                final category = displayedCategories[index];
                final isSelected = category == widget.selectedCategory;

                return GestureDetector(
                  onTap: () {
                    final newCategory = isSelected ? 'Todo' : category;
                    widget.onCategorySelected(newCategory);
                  },
                  child: Container(
                    height: AppDimensions.categoryTabHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: AppDimensions.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.categoryActive
                          : AppColors.categoryInactive,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadiusL),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.categoryActive
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WebScrollBehavior extends MaterialScrollBehavior {
  const WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
