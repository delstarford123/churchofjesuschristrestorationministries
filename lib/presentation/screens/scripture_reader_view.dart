import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rlds_church_app/core/theme/theme_provider.dart';
import 'package:rlds_church_app/data/scripture_database_helper.dart';
import 'package:rlds_church_app/data/scripture_rag_service.dart';

class ScriptureReaderView extends StatefulWidget {
  final String? initialCorpus;
  final String? initialBook;
  final int? initialChapter;
  final int? initialVerse;

  const ScriptureReaderView({
    super.key,
    this.initialCorpus,
    this.initialBook,
    this.initialChapter,
    this.initialVerse,
  });

  @override
  State<ScriptureReaderView> createState() => _ScriptureReaderViewState();
}

class _ScriptureReaderViewState extends State<ScriptureReaderView> with SingleTickerProviderStateMixin {
  static const Color liturgicalBlue = Color(0xFF1E3A8A);
  static const Color stewardshipGold = Color(0xFFD97706);

  late TabController _tabController;
  final ScriptureDatabaseHelper _dbHelper = ScriptureDatabaseHelper.instance;
  final ScriptureRagService _ragService = ScriptureRagService();
  final ScrollController _scrollController = ScrollController();

  // Active Reading State
  String _selectedCorpus = 'inspired_version_bible'; // or 'book_of_mormon'
  String _selectedBook = 'Genesis';
  int _selectedChapter = 1;
  int? _highlightedVerse;

  List<String> _books = [];
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;

  // Reader Customization State
  double _fontSize = 15.5;
  bool _showVerseNumbers = true;
  bool _isSerifFont = false;

  // Search State
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  // AI RAG Query State
  final _aiQueryController = TextEditingController(text: 'What does the Inspired Version teach about Zion?');
  Map<String, dynamic>? _aiResponse;
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialCorpus != null) _selectedCorpus = widget.initialCorpus!;
    if (widget.initialBook != null) _selectedBook = widget.initialBook!;
    if (widget.initialChapter != null) _selectedChapter = widget.initialChapter!;
    if (widget.initialVerse != null) _highlightedVerse = widget.initialVerse!;
    _loadScriptures();
  }

  Future<void> _loadScriptures() async {
    setState(() => _isLoading = true);
    final books = await _dbHelper.getBooks(_selectedCorpus);
    if (books.isNotEmpty) {
      if (!books.contains(_selectedBook)) {
        _selectedBook = books.first;
      }
      final chapters = await _dbHelper.getChapters(_selectedCorpus, _selectedBook);
      if (chapters.isNotEmpty) {
        if (!chapters.contains(_selectedChapter)) {
          _selectedChapter = chapters.first;
        }
        final verses = await _dbHelper.getVerses(_selectedCorpus, _selectedBook, _selectedChapter);
        if (mounted) {
          setState(() {
            _books = books;
            _chapters = chapters;
            _verses = verses;
            _isLoading = false;
          });
          if (_highlightedVerse != null) {
            _scrollToVerse(_highlightedVerse!);
          }
        }
        return;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _scrollToVerse(int verseNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _verses.isNotEmpty) {
        final targetIndex = _verses.indexWhere((v) => (v['verse_number'] as int? ?? 1) == verseNumber);
        if (targetIndex >= 0) {
          final offset = (targetIndex * 110.0).clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _onCorpusChanged(String newCorpus) {
    if (_selectedCorpus == newCorpus) return;
    setState(() {
      _selectedCorpus = newCorpus;
      _selectedBook = newCorpus == 'inspired_version_bible' ? 'Genesis' : '1 Nephi';
      _selectedChapter = 1;
      _highlightedVerse = null;
    });
    _loadScriptures();
  }

  void _nextChapter() {
    final currentIndex = _chapters.indexOf(_selectedChapter);
    if (currentIndex >= 0 && currentIndex < _chapters.length - 1) {
      setState(() {
        _selectedChapter = _chapters[currentIndex + 1];
        _highlightedVerse = null;
      });
      _loadScriptures();
    } else {
      // Advance to next book's Chapter 1
      final bookIndex = _books.indexOf(_selectedBook);
      if (bookIndex >= 0 && bookIndex < _books.length - 1) {
        setState(() {
          _selectedBook = _books[bookIndex + 1];
          _selectedChapter = 1;
          _highlightedVerse = null;
        });
        _loadScriptures();
      }
    }
  }

  void _prevChapter() {
    final currentIndex = _chapters.indexOf(_selectedChapter);
    if (currentIndex > 0) {
      setState(() {
        _selectedChapter = _chapters[currentIndex - 1];
        _highlightedVerse = null;
      });
      _loadScriptures();
    } else {
      // Step back to previous book's last chapter
      final bookIndex = _books.indexOf(_selectedBook);
      if (bookIndex > 0) {
        final prevBook = _books[bookIndex - 1];
        _dbHelper.getChapters(_selectedCorpus, prevBook).then((prevChapters) {
          if (mounted) {
            setState(() {
              _selectedBook = prevBook;
              _selectedChapter = prevChapters.isNotEmpty ? prevChapters.last : 1;
              _highlightedVerse = null;
            });
            _loadScriptures();
          }
        });
      }
    }
  }

  Future<void> _executeSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    final results = await _dbHelper.searchScriptures(
      tableName: _selectedCorpus,
      query: query.trim(),
    );
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _askOfflineAi() async {
    final query = _aiQueryController.text.trim();
    if (query.isEmpty) return;
    setState(() => _isGeneratingAI = true);
    final result = await _ragService.generateOfflineSpiritualInsight(query);
    if (mounted) {
      setState(() {
        _aiResponse = result;
        _isGeneratingAI = false;
      });
    }
  }

  // --- INTERACTIVE BOOK, CHAPTER & VERSE NAVIGATOR MODAL ---
  void _showBookChapterVersePicker() {
    int activeSubTab = 0; // 0 = Books, 1 = Chapters, 2 = Verses
    String tempBook = _selectedBook;
    int tempChapter = _selectedChapter;
    List<int> tempChaptersList = List.from(_chapters);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Corpus Switcher Header
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Inspired Version (JST)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          selected: _selectedCorpus == 'inspired_version_bible',
                          selectedColor: liturgicalBlue,
                          labelStyle: TextStyle(
                            color: _selectedCorpus == 'inspired_version_bible' ? Colors.white : liturgicalBlue,
                          ),
                          onSelected: (_) async {
                            _selectedCorpus = 'inspired_version_bible';
                            final bks = await _dbHelper.getBooks(_selectedCorpus);
                            final chs = await _dbHelper.getChapters(_selectedCorpus, bks.first);
                            setModalState(() {
                              tempBook = bks.first;
                              tempChapter = 1;
                              tempChaptersList = chs;
                              activeSubTab = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Book of Mormon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          selected: _selectedCorpus == 'book_of_mormon',
                          selectedColor: liturgicalBlue,
                          labelStyle: TextStyle(
                            color: _selectedCorpus == 'book_of_mormon' ? Colors.white : liturgicalBlue,
                          ),
                          onSelected: (_) async {
                            _selectedCorpus = 'book_of_mormon';
                            final bks = await _dbHelper.getBooks(_selectedCorpus);
                            final chs = await _dbHelper.getChapters(_selectedCorpus, bks.first);
                            setModalState(() {
                              tempBook = bks.first;
                              tempChapter = 1;
                              tempChaptersList = chs;
                              activeSubTab = 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Step Indicators (Books -> Chapters -> Verses)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => activeSubTab = 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeSubTab == 0 ? liturgicalBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  tempBook,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: activeSubTab == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => activeSubTab = 1),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeSubTab == 1 ? liturgicalBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Chapter $tempChapter',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: activeSubTab == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => activeSubTab = 2),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: activeSubTab == 2 ? liturgicalBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Verses',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: activeSubTab == 2 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SUB-TAB 0: BOOKS LIST
                  if (activeSubTab == 0)
                    Expanded(
                      child: FutureBuilder<List<String>>(
                        future: _dbHelper.getBooks(_selectedCorpus),
                        builder: (ctx, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final bookList = snapshot.data!;
                          return GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.0,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: bookList.length,
                            itemBuilder: (c, idx) {
                              final b = bookList[idx];
                              final isSelected = b == tempBook;
                              return InkWell(
                                onTap: () async {
                                  final chs = await _dbHelper.getChapters(_selectedCorpus, b);
                                  setModalState(() {
                                    tempBook = b;
                                    tempChaptersList = chs;
                                    tempChapter = 1;
                                    activeSubTab = 1; // Advance to chapters
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? liturgicalBlue : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? liturgicalBlue : Colors.grey.withAlpha(50),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.bookmark_outline_rounded, size: 16, color: isSelected ? stewardshipGold : liturgicalBlue),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          b,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                  // SUB-TAB 1: CHAPTERS QUICK NUMBERED GRID
                  if (activeSubTab == 1)
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: tempChaptersList.length,
                        itemBuilder: (c, idx) {
                          final chNum = tempChaptersList[idx];
                          final isSelected = chNum == tempChapter;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                tempChapter = chNum;
                                activeSubTab = 2; // Advance to verses
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? liturgicalBlue : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? stewardshipGold : Colors.grey.withAlpha(50)),
                              ),
                              child: Center(
                                child: Text(
                                  '$chNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // SUB-TAB 2: VERSES QUICK NUMBERED GRID
                  if (activeSubTab == 2)
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _dbHelper.getVerses(_selectedCorpus, tempBook, tempChapter),
                        builder: (ctx, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final vList = snapshot.data!;
                          final verseCount = vList.isNotEmpty ? vList.length : 12;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: liturgicalBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.pop(modalCtx);
                                  setState(() {
                                    _selectedBook = tempBook;
                                    _selectedChapter = tempChapter;
                                    _highlightedVerse = null;
                                  });
                                  _loadScriptures();
                                },
                                icon: const Icon(Icons.book_rounded, size: 18),
                                label: Text('Read Entire Chapter $tempChapter from Verse 1'),
                              ),
                              const SizedBox(height: 10),
                              const Text('Or tap a specific verse to jump:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: verseCount,
                                  itemBuilder: (c, idx) {
                                    final vNum = idx + 1;
                                    return InkWell(
                                      onTap: () {
                                        Navigator.pop(modalCtx);
                                        setState(() {
                                          _selectedBook = tempBook;
                                          _selectedChapter = tempChapter;
                                          _highlightedVerse = vNum;
                                        });
                                        _loadScriptures();
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: stewardshipGold.withAlpha(90)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$vNum',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- READER CUSTOMIZATION SETTINGS MODAL ---
  void _showReaderSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reader Display Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.format_size_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text('Font Size: ${_fontSize.toStringAsFixed(1)} pt', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _fontSize > 13.0
                            ? () {
                                setState(() => _fontSize -= 1.0);
                                setModalState(() {});
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _fontSize < 24.0
                            ? () {
                                setState(() => _fontSize += 1.0);
                                setModalState(() {});
                              }
                            : null,
                      ),
                    ],
                  ),
                  Slider(
                    value: _fontSize,
                    min: 13.0,
                    max: 24.0,
                    divisions: 11,
                    activeColor: liturgicalBlue,
                    onChanged: (val) {
                      setState(() => _fontSize = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Show Verse Numbers'),
                    subtitle: const Text('Display numbered indices for verse references'),
                    value: _showVerseNumbers,
                    activeThumbColor: liturgicalBlue,
                    onChanged: (val) {
                      setState(() => _showVerseNumbers = val);
                      setModalState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Serif Biblical Font'),
                    subtitle: const Text('Read in classic scriptural serif typeface'),
                    value: _isSerifFont,
                    activeThumbColor: liturgicalBlue,
                    onChanged: (val) {
                      setState(() => _isSerifFont = val);
                      setModalState(() {});
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(AppStateNotifier.instance.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                    title: const Text('Toggle Dark / Light Mode'),
                    onTap: () {
                      AppStateNotifier.instance.toggleTheme();
                      setModalState(() {});
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showVerseDetailsModal(Map<String, dynamic> verse) {
    final ref = verse['reference'] as String;
    final text = verse['verse_text'] as String;
    final commentary = _dbHelper.getRestorationCommentary(ref);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ref,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: liturgicalBlue),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stewardshipGold.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    commentary['doctrinal_pillar'] as String,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stewardshipGold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withAlpha(40)),
              ),
              child: Text(
                '“$text”',
                style: TextStyle(
                  fontSize: _fontSize,
                  fontStyle: FontStyle.italic,
                  fontFamily: _isSerifFont ? 'serif' : null,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Historical Restoration Commentary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              commentary['historical_note'] as String,
              style: const TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.35),
            ),
            const SizedBox(height: 14),
            const Text(
              'Cross-References:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: liturgicalBlue),
            ),
            Wrap(
              spacing: 8,
              children: (commentary['cross_references'] as List<String>).map((cr) {
                return Chip(
                  label: Text(cr, style: const TextStyle(fontSize: 11, color: liturgicalBlue)),
                  backgroundColor: liturgicalBlue.withAlpha(15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: liturgicalBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$ref - "$text"'));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verse copied to clipboard'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Verse'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _aiQueryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: liturgicalBlue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restoration Scriptures (Offline)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '$_selectedBook $_selectedChapter • ${_selectedCorpus == 'inspired_version_bible' ? 'Inspired Version (JST)' : 'Book of Mormon'}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reader Typography Settings',
            icon: const Icon(Icons.format_size_rounded, color: Colors.white),
            onPressed: _showReaderSettingsModal,
          ),
          IconButton(
            tooltip: 'Select Book & Chapter',
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            onPressed: _showBookChapterVersePicker,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: stewardshipGold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Reader'),
            Tab(icon: Icon(Icons.search_rounded), text: 'Offline Search'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Scriptural AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReaderTab(),
          _buildSearchTab(),
          _buildAiRagTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: SCRIPTURE READER VIEW
  // =========================================================================
  Widget _buildReaderTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Interactive Navigator Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(40))),
          ),
          child: Row(
            children: [
              // Interactive Navigation Pill
              Expanded(
                child: InkWell(
                  onTap: _showBookChapterVersePicker,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: liturgicalBlue.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: liturgicalBlue.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: liturgicalBlue, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$_selectedBook Chapter $_selectedChapter',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: liturgicalBlue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: liturgicalBlue),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quick Corpus Switcher Pill
              InkWell(
                onTap: () {
                  _onCorpusChanged(
                    _selectedCorpus == 'inspired_version_bible' ? 'book_of_mormon' : 'inspired_version_bible',
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: stewardshipGold.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: stewardshipGold.withAlpha(50)),
                  ),
                  child: Text(
                    _selectedCorpus == 'inspired_version_bible' ? 'IV Bible' : 'BoM',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: stewardshipGold),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Verses List with Canonical Book Header
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(stewardshipGold)))
              : _verses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text('No verses found in this chapter.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _verses.length + 1, // +1 for the Book Header
                      itemBuilder: (ctx, i) {
                        // 0: Canonical Book & Chapter Header Card
                        if (i == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: liturgicalBlue.withAlpha(30)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedBook.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: liturgicalBlue, letterSpacing: 0.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stewardshipGold,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'CHAPTER $_selectedChapter',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedCorpus == 'book_of_mormon'
                                      ? 'Restoration Edition • Another Witness of Jesus Christ'
                                      : 'Joseph Smith Translation • Inspired Prophetic Revision',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        final v = _verses[i - 1];
                        final verseNum = v['verse_number'] as int? ?? i;
                        final isHighlighted = _highlightedVerse == verseNum;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isHighlighted ? stewardshipGold : Colors.transparent,
                              width: isHighlighted ? 1.8 : 0,
                            ),
                          ),
                          color: isHighlighted
                              ? (isDark ? const Color(0xFF2E2413) : const Color(0xFFFEF3C7))
                              : Theme.of(context).cardColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showVerseDetailsModal(v),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_showVerseNumbers) ...[
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isHighlighted ? stewardshipGold : liturgicalBlue.withAlpha(15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$verseNum',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isHighlighted ? Colors.white : liturgicalBlue,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['verse_text'] as String? ?? '',
                                          style: TextStyle(
                                            fontSize: _fontSize,
                                            height: 1.5,
                                            fontFamily: _isSerifFont ? 'serif' : null,
                                            color: isDark ? Colors.white : const Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              v['reference'] as String? ?? '$_selectedBook $_selectedChapter:$verseNum',
                                              style: const TextStyle(fontSize: 11, color: stewardshipGold, fontWeight: FontWeight.bold),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.touch_app_outlined, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            const Text('Commentary & Cross-Ref', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // STICKY BOTTOM NAVIGATION BAR (Previous Chapter & Next Chapter)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  foregroundColor: isDark ? Colors.white : liturgicalBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _prevChapter,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              InkWell(
                onTap: _showBookChapterVersePicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        '$_selectedBook $_selectedChapter',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: liturgicalBlue),
                      ),
                      Text(
                        '${_verses.length} verses',
                        style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: liturgicalBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _nextChapter,
                label: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: OFFLINE FULL-TEXT SEARCH TAB
  // =========================================================================
  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search keywords e.g. Zion, Stewardship, Faith...',
              prefixIcon: const Icon(Icons.search_rounded, color: liturgicalBlue),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: liturgicalBlue),
                onPressed: () => _executeSearch(_searchController.text),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onSubmitted: _executeSearch,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['Zion', 'Stewardship', 'Faith', 'Moses', 'Kingdom', 'Nephi', 'Tithe', 'Covenant'].map((kw) {
              return ActionChip(
                label: Text(kw, style: const TextStyle(fontSize: 11, color: liturgicalBlue)),
                backgroundColor: liturgicalBlue.withAlpha(12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  _searchController.text = kw;
                  _executeSearch(kw);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Enter a keyword to search Inspired Version & Book of Mormon offline.'
                              : 'No matches found in offline SQLite database.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, idx) {
                          final item = _searchResults[idx];
                          final ref = item['reference'] as String? ?? '';
                          final text = item['verse_text'] as String? ?? '';
                          final bName = item['book_name'] as String? ?? _selectedBook;
                          final chNum = item['chapter_number'] as int? ?? 1;
                          final vNum = item['verse_number'] as int? ?? 1;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(ref, style: const TextStyle(fontWeight: FontWeight.bold, color: liturgicalBlue)),
                              subtitle: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: liturgicalBlue.withAlpha(20),
                                  foregroundColor: liturgicalBlue,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onPressed: () {
                                  // Switch to Reader tab, load that chapter, and scroll to that verse!
                                  setState(() {
                                    _selectedBook = bName;
                                    _selectedChapter = chNum;
                                    _highlightedVerse = vNum;
                                  });
                                  _tabController.animateTo(0);
                                  _loadScriptures();
                                },
                                child: const Text('Read', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              onTap: () => _showVerseDetailsModal(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: OFFLINE SCRIPTURAL AI (RAG INJECTOR)
  // =========================================================================
  Widget _buildAiRagTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: stewardshipGold, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Scriptural RAG Engine',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Powered exclusively by the Inspired Version & Book of Mormon via local SQLite vector context.',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _aiQueryController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Ask a scriptural or theological question',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: liturgicalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isGeneratingAI ? null : _askOfflineAi,
            icon: const Icon(Icons.psychology_rounded),
            label: const Text('Generate Spiritual Insight (Offline RAG)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (_isGeneratingAI) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(stewardshipGold))),
          ],
          if (_aiResponse != null && !_isGeneratingAI) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_quote_rounded, color: stewardshipGold, size: 24),
                        SizedBox(width: 6),
                        Text(
                          'RLDS Doctrinal Synthesis',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _aiResponse!['insight'] as String,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Injected Local Scripture Context:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: liturgicalBlue),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _aiResponse!['injected_context'] as String,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target: ${_aiResponse!['model_target']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const Text('100% Offline • SQLite B-Tree', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
