import 'package:flutter/material.dart';
import 'outfit.dart';
import 'outfit_service.dart';
import 'OutfitDetailsPage.dart';
import 'OutfitPageDyn.dart';

class AllOutfitsPage extends StatefulWidget {
  const AllOutfitsPage({super.key});

  @override
  State<AllOutfitsPage> createState() => _AllOutfitsPageState();
}

class _AllOutfitsPageState extends State<AllOutfitsPage> {
  Map<String, List<Outfit>> outfitsBySeason = {};
  bool isLoading = true;
  String error = '';
  String selectedTag = '';
  bool showHijabOnly = false;

  final List<String> tagOptions = ['Casual', 'Work', 'Sport', 'Comfy', 'Classic'];

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    try {
      final allOutfits = await fetchAllOutfits();

      final filtered = allOutfits.where((outfit) {
        final matchesTag = selectedTag.isEmpty || (outfit.tags?.toLowerCase().contains(selectedTag.toLowerCase()) ?? false);
        final matchesHijab = !showHijabOnly || outfit.isHijabFriendly;
        return matchesTag && matchesHijab;
      }).toList();

      final grouped = groupOutfitsBySeason(filtered);

      setState(() {
        outfitsBySeason = grouped;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Outfits'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'Hijab') {
                setState(() {
                  showHijabOnly = !showHijabOnly;
                });
                _loadOutfits();
              } else if (value == 'Reset') {
                setState(() {
                  selectedTag = '';
                  showHijabOnly = false;
                });
                _loadOutfits();
              } else {
                setState(() {
                  selectedTag = value;
                });
                _loadOutfits();
              }
            },
            itemBuilder: (context) => [
              ...tagOptions.map((tag) => PopupMenuItem(
                    value: tag,
                    child: Text(tag, style: const TextStyle(color: Colors.black)),
                  )),
              PopupMenuItem(
                value: 'Hijab',
                child: Text('Hijab Friendly Only', style: const TextStyle(color: Colors.black)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Reset',
                child: Text('Remove Filters', style: TextStyle(color: Colors.black)),
              ),
            ],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOutfits,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedTag.isNotEmpty || showHijabOnly)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                if (selectedTag.isNotEmpty)
                                  Chip(
                                    label: Text('Tag: $selectedTag'),
                                    onDeleted: () {
                                      setState(() => selectedTag = '');
                                      _loadOutfits();
                                    },
                                  ),
                                if (showHijabOnly)
                                  Chip(
                                    label: const Text('Hijab Friendly'),
                                    onDeleted: () {
                                      setState(() => showHijabOnly = false);
                                      _loadOutfits();
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ...outfitsBySeason.entries.map((entry) {
                          final season = entry.key;
                          final outfits = entry.value;
                         final sorted = List<Outfit>.from(outfits)..sort((a, b) => b.id.compareTo(a.id));
                          final previewOutfits = sorted.take(4).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                             GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OutfitCategoryPage(
                                          categoryName: season,
                                          outfits: outfits,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    season,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),
                              previewOutfits.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                                      child: Text(
                                        'No outfits for this season',
                                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 130,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: outfits.length > 5 ? previewOutfits.length + 1 : previewOutfits.length,
                                        itemBuilder: (context, index) {
                                          if (index < previewOutfits.length) {
                                            final outfit = previewOutfits[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => OutfitDetailsPage(outfit: outfit),
                                                  ),
                                                );
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                  child: Container(
                                                    width: 100,
                                                    color: theme.colorScheme.surface,
                                                    child: outfit.photoPath != null
                                                        ? Image.network(
                                                            outfit.photoPath!,
                                                            fit: BoxFit.cover,
                                                            width: 100,
                                                            height: 130,
                                                            loadingBuilder: (context, child, progress) {
                                                              if (progress == null) return child;
                                                              return const Center(child: CircularProgressIndicator());
                                                            },
                                                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                                                          )
                                                        : const Center(child: Icon(Icons.image_not_supported)),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => OutfitCategoryPage(
                                                      categoryName: season,
                                                      outfits: outfits,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 100,
                                                height: 130,
                                                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.arrow_forward, size: 30, color: Colors.black54),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
      ),
    );
  }
}