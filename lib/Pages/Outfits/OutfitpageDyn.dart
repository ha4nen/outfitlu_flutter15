import 'package:flutter/material.dart';
import 'outfit.dart';
import 'package:flutter_application_1/Pages/Outfits/OutfitDetailsPage.dart';

class OutfitCategoryPage extends StatefulWidget {
  final String categoryName;
  final List<Outfit> outfits;

  const OutfitCategoryPage({
    super.key,
    required this.categoryName,
    required this.outfits,
  });

  @override
  State<OutfitCategoryPage> createState() => _OutfitCategoryPageState();
}

class _OutfitCategoryPageState extends State<OutfitCategoryPage> {
  String selectedTag = '';
  bool showHijabOnly = false;
  String sortBy = 'Newest';

  final List<String> tagOptions = [
    'All',
    'Casual',
    'Hijab',
    'Work',
    'Formal',
    'Comfy',
    'Chic',
    'Sport',
    'Classy',
  ];

  List<Outfit> get filteredOutfits {
    List<Outfit> result =
        widget.outfits.where((outfit) {
          final matchesTag =
              selectedTag.isEmpty ||
              (outfit.tags != null &&
                  outfit.tags!.toLowerCase().contains(
                    selectedTag.toLowerCase(),
                  ));
          final matchesHijab = !showHijabOnly || outfit.isHijabFriendly;
          return matchesTag && matchesHijab;
        }).toList();

    result.sort(
      (a, b) =>
          sortBy == 'Newest' ? b.id.compareTo(a.id) : a.id.compareTo(b.id),
    );

    return result;
  }

  int _tagCount(String tag) {
    if (tag == 'All') return widget.outfits.length;
    if (tag == 'Hijab') {
      return widget.outfits.where((o) => o.isHijabFriendly).length;
    }
    return widget.outfits
        .where(
          (o) =>
              o.tags != null &&
              o.tags!.toLowerCase().contains(tag.toLowerCase()),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outfitsToShow = filteredOutfits;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryName} Outfits'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tag in tagOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          tag == 'Hijab'
                              ? 'Hijab Friendly (${_tagCount(tag)})'
                              : '$tag (${_tagCount(tag)})',
                          style: TextStyle(
                            color:
                                selectedTag == (tag == 'All' ? '' : tag)
                                    ? Colors.white
                                    : const Color(0xFF2F1B0C),
                          ),
                        ),
                        selected:
                            tag == 'Hijab'
                                ? showHijabOnly
                                : selectedTag == (tag == 'All' ? '' : tag),
                        selectedColor: const Color(0xFFFF9800),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFFFE0B2)),
                        ),
                        onSelected: (_) {
                          setState(() {
                            if (tag == 'Hijab') {
                              showHijabOnly = !showHijabOnly;
                            } else {
                              final newTag = tag == 'All' ? '' : tag;
                              selectedTag = selectedTag == newTag ? '' : newTag;
                            }
                          });
                        },
                      ),
                    ),
                  // Sorting options
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Newest'),
                      selected: sortBy == 'Newest',
                      selectedColor: const Color(0xFFFF9800),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFFFE0B2)),
                      ),
                      onSelected: (_) {
                        setState(() => sortBy = 'Newest');
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Oldest'),
                      selected: sortBy == 'Oldest',
                      selectedColor: const Color(0xFFFF9800),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFFFE0B2)),
                      ),
                      onSelected: (_) {
                        setState(() => sortBy = 'Oldest');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                outfitsToShow.isEmpty
                    ? Center(
                      child: Text(
                        'No outfits available for this filter.',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: outfitsToShow.length,
                      itemBuilder: (context, index) {
                        final outfit = outfitsToShow[index];
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => OutfitDetailsPage(outfit: outfit),
                              ),
                            );
                            if (result == 'refresh') setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 2.0, // Thicker border
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                outfit.photoPath ?? '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder:
                                    (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
