// Updated AllOutfitsPage UI to match MyItemsPage style
import 'package:flutter/material.dart';
import 'outfit.dart';
import 'outfit_service.dart';
import 'OutfitDetailsPage.dart';
import 'OutfitPageDyn.dart';

class AllOutfitsPage extends StatefulWidget {
  final int? userId;
  const AllOutfitsPage({super.key, this.userId});

  @override
  State<AllOutfitsPage> createState() => _AllOutfitsPageState();
}

class _AllOutfitsPageState extends State<AllOutfitsPage> {
  Map<String, List<Outfit>> outfitsBySeason = {};
  bool isLoading = true;
  String error = '';
  String selectedTag = '';
  bool showHijabOnly = false;

  final List<String> tagOptions = [
    'All',
    'Casual',
    'Work',
    'Formal',
    'Comfy',
    'Chic',
    'Sport',
    'Classy',
  ];

  @override
  void initState() {
    super.initState();
    _loadOutfits();
  }

  Future<void> _loadOutfits() async {
    setState(() => isLoading = true);
    try {
      final allOutfits =
          widget.userId != null
              ? await fetchOutfitsByUser(widget.userId!)
              : await fetchAllOutfits();

      final filtered =
          allOutfits.where((outfit) {
              final matchesTag =
                  selectedTag.isEmpty ||
                  (outfit.tags != null &&
                      outfit.tags!.toLowerCase().contains(
                        selectedTag.toLowerCase(),
                      ));
              final matchesHijab = !showHijabOnly || outfit.isHijabFriendly;
              return matchesTag && matchesHijab;
            }).toList()
            ..sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        outfitsBySeason = groupOutfitsBySeason(filtered);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  int _tagCount(String tag) {
    if (tag == 'All') return outfitsBySeason.values.expand((o) => o).length;
    if (tag == 'Hijab')
      return outfitsBySeason.values
          .expand((o) => o)
          .where((o) => o.isHijabFriendly)
          .length;
    return outfitsBySeason.values
        .expand((o) => o)
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Outfits"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tag in tagOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          '$tag (${_tagCount(tag)})',
                          style: TextStyle(
                            color:
                                selectedTag == (tag == 'All' ? '' : tag)
                                    ? Colors.white
                                    : const Color(0xFF2F1B0C),
                          ),
                        ),

                        selected: selectedTag == (tag == 'All' ? '' : tag),
                        selectedColor: const Color(0xFFFF9800),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFFFE0B2)),
                        ),
                        onSelected: (isSelected) {
                          setState(() {
                            final newTag = tag == 'All' ? '' : tag;
                            selectedTag =
                                selectedTag == newTag
                                    ? ''
                                    : newTag; // toggle off
                          });
                          _loadOutfits();
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('Hijab Friendly'),
                      selected: showHijabOnly,
                      selectedColor: const Color(0xFFFF9800),
                      backgroundColor: Colors.white,
                      onSelected: (value) {
                        setState(() => showHijabOnly = value);
                        _loadOutfits();
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
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error.isNotEmpty
                    ? Center(
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : outfitsBySeason.isEmpty
                    ? const Center(
                      child: Text(
                        'No outfits available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadOutfits,
                      child: ListView(
                        padding: const EdgeInsets.all(16.0),
                        children:
                            outfitsBySeason.entries.map((entry) {
                              final season = entry.key;
                              final outfits = entry.value;
                              final previewOutfits = outfits.take(4).toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap:
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => OutfitCategoryPage(
                                                  categoryName: season,
                                                  outfits: outfits,
                                                ),
                                          ),
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              text: season,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2F1B0C),
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: '  ${outfits.length}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const Spacer(),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 140,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: previewOutfits.length + 1,
                                      itemBuilder: (context, index) {
                                        if (index < previewOutfits.length) {
                                          final outfit = previewOutfits[index];
                                          return GestureDetector(
                                            onTap: () async {
                                              final result =
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              OutfitDetailsPage(
                                                                outfit: outfit,
                                                              ),
                                                    ),
                                                  );
                                              if (result == 'refresh')
                                                _loadOutfits();
                                            },

                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6.0,
                                                  ),
                                              child: Container(
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color:
                                                        Colors.orange.shade100,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child:
                                                      outfit.photoPath != null
                                                          ? Image.network(
                                                            outfit.photoPath!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                ),
                                                          )
                                                          : const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                            ),
                                                          ),
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return GestureDetector(
                                            onTap:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            OutfitCategoryPage(
                                                              categoryName:
                                                                  season,
                                                              outfits: outfits,
                                                            ),
                                                  ),
                                                ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6.0,
                                                  ),
                                              child: Container(
                                                width: 100,
                                                height: 130,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.arrow_forward,
                                                    size: 30,
                                                    color: Colors.black54,
                                                  ),
                                                ),
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
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
