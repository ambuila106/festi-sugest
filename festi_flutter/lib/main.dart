import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _bgColor = Color(0xFF000516);
const _accentColor = Color(0xFFC3AFFF);
const _baseRtdbUrl = 'https://festi-suggest-default-rtdb.firebaseio.com';
const _weekDaysEs = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _monthsEs = <String>[
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
const _topFeedTabs = <FeedType>[
  FeedType.losts,
  FeedType.rentals,
  FeedType.jobs,
  FeedType.services,
];
const _allFeedTypes = <FeedType>[
  FeedType.homes,
  FeedType.losts,
  FeedType.rentals,
  FeedType.jobs,
  FeedType.services,
];
const _classificationPriority = <FeedType>[
  FeedType.losts,
  FeedType.rentals,
  FeedType.jobs,
  FeedType.services,
];
const _classificationRules = <FeedType, Map<String, int>>{
  FeedType.losts: {
    'se me perdio': 6,
    'se perdio': 6,
    'perdi': 4,
    'perdimos': 4,
    'perdieron': 4,
    'perdido': 3,
    'perdida': 3,
    'perdio': 3,
    'extravie': 4,
    'extravio': 4,
    'extraviamos': 4,
    'extraviado': 3,
    'olvide': 3,
    'olvido': 3,
    'olvidamos': 3,
    'deje botado': 4,
    'deje tirado': 4,
    'se me quedo': 4,
    'encontre': 3,
    'encontro': 3,
    'encontraron': 3,
    'encontrado': 3,
    'se encontraron': 3,
    'recompensa': 2,
    'devolver': 2,
    'devolucion': 2,
  },
  FeedType.rentals: {
    'se arrienda': 6,
    'arriendan': 5,
    'arriendo': 5,
    'arrienda': 5,
    'arrendar': 4,
    'arrendando': 4,
    'habitacion': 4,
    'habitaciones': 4,
    'pieza': 3,
    'cuarto': 3,
    'apartamento': 5,
    'apartaestudio': 5,
    'aparta estudio': 5,
    'apto': 3,
    'roomie': 5,
    'roommate': 5,
    'roomate': 5,
    'rumi': 5,
    'compartir apartamento': 6,
    'compartir casa': 5,
  },
  FeedType.jobs: {
    'busco trabajo': 6,
    'busco empleo': 6,
    'vacante': 5,
    'hoja de vida': 5,
    'se requiere': 5,
    'se necesita': 4,
    'trabajar': 3,
    'empleo': 3,
    'mesera': 4,
    'mesero': 4,
    'cajera': 4,
    'cajero': 4,
    'cocinero': 4,
    'cocinera': 4,
    'auxiliar': 3,
    'docente': 3,
    'vendedor': 3,
    'vendedora': 3,
    'asesor': 3,
    'asesora': 3,
    'recepcionista': 3,
    'ninera': 4,
    'parrillero': 3,
    'impulsadora': 3,
    'entrenador': 3,
    'fines de semana': 2,
    'medio tiempo': 2,
    'turno': 2,
    'disponibilidad': 2,
  },
  FeedType.services: {
    'se vende': 6,
    'vendo': 5,
    'vendiendo': 5,
    'ofrezco': 4,
    'domicilio': 4,
    'domicilios': 4,
    'clases': 4,
    'tutoria': 4,
    'tutorias': 4,
    'asesoria': 3,
    'asesorias': 3,
    'licencia': 3,
    'licencias': 3,
    'microsoft office': 5,
    'streaming': 3,
    'reparo': 3,
    'arreglo': 3,
    'manicure': 3,
    'maquillaje': 3,
    'fotografia': 3,
    'diseno': 3,
    'crochet': 3,
    'catalogo': 3,
    'productos': 2,
    'producto': 2,
    'curso': 2,
    'servicio tecnico': 4,
    'citas pasaporte': 4,
  },
};

String _normalizeText(String value) {
  final plain = value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');
  return plain
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int _scoreByRules(String normalizedText, Map<String, int> rules) {
  var score = 0;
  for (final entry in rules.entries) {
    if (normalizedText.contains(entry.key)) {
      score += entry.value;
    }
  }
  return score;
}

String _formatDateEs(DateTime date) {
  final weekDay = _weekDaysEs[date.weekday - 1];
  final month = _monthsEs[date.month - 1];
  return '$weekDay, ${date.day} de $month de ${date.year}';
}

void main() {
  runApp(const FestiApp());
}

class FestiApp extends StatelessWidget {
  const FestiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Festi Suggest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accentColor,
          brightness: Brightness.dark,
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          MarketplaceScreen(),
          PublicationsScreen(),
          SubscribeScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: _bgColor,
        currentIndex: _tab,
        selectedItemColor: _accentColor,
        unselectedItemColor: Colors.white70,
        onTap: (next) => setState(() => _tab = next),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Festi'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Suscribirse'),
        ],
      ),
    );
  }
}

enum FeedType { homes, jobs, services, losts, rentals }

extension FeedTypeValues on FeedType {
  String get node => switch (this) {
    FeedType.homes => 'homes',
    FeedType.jobs => 'jobs',
    FeedType.services => 'services',
    FeedType.losts => 'losts',
    FeedType.rentals => 'rentals',
  };

  String get title => switch (this) {
    FeedType.homes => 'HOME',
    FeedType.jobs => 'TRABAJOS',
    FeedType.services => 'SERVICIOS',
    FeedType.losts => 'PERDIDOS',
    FeedType.rentals => 'ARRIENDOS',
  };

  String get badge => switch (this) {
    FeedType.homes => 'Solicitudes',
    FeedType.jobs => 'Trabajos',
    FeedType.services => 'Servicios',
    FeedType.losts => 'Perdidos',
    FeedType.rentals => 'Arriendos',
  };
}

class ListingItem {
  const ListingItem({
    required this.description,
    this.number = '',
    this.date = '',
    this.createdAt = '',
  });

  final String description;
  final String number;
  final String date;
  final String createdAt;

  String get displayDate {
    final cleanDate = date.trim();
    if (cleanDate.isNotEmpty) return cleanDate;

    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedCreatedAt != null) {
      return _formatDateEs(parsedCreatedAt.toLocal());
    }
    return 'Fecha no disponible';
  }

  factory ListingItem.fromJson(Map<String, dynamic> json) {
    return ListingItem(
      description: (json['description'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'description': description,
      'number': number,
    };
    if (date.trim().isNotEmpty) {
      payload['date'] = date.trim();
    }
    if (createdAt.trim().isNotEmpty) {
      payload['createdAt'] = createdAt.trim();
    }
    return payload;
  }
}

class _RealtimeApi {
  Uri _uri(String node) => Uri.parse('$_baseRtdbUrl/$node.json');

  String _dailyKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<int> _readDailyCount(String dayKey) async {
    final response = await http.get(_uri('viewsByDay/$dayKey'));
    if (response.statusCode >= 400 || response.body == 'null') {
      return 0;
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map) return 0;
    return int.tryParse((payload['count'] ?? 0).toString()) ?? 0;
  }

  Future<List<ListingItem>> getListings(FeedType type) async {
    final response = await http.get(_uri(type.node));
    if (response.statusCode >= 400 || response.body == 'null') {
      return [];
    }

    final dynamic payload = jsonDecode(response.body);
    if (payload is! List) return [];

    final items = payload
        .whereType<Map>()
        .map((entry) => ListingItem.fromJson(Map<String, dynamic>.from(entry)))
        .where((entry) => entry.description.trim().isNotEmpty)
        .toList();

    return items.reversed.toList();
  }

  Future<void> addListing(FeedType type, ListingItem listing) async {
    final current = await getListings(type);
    final next = [...current.reversed, listing];
    await http.put(
      _uri(type.node),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<String>> getTextList(String node) async {
    final response = await http.get(_uri(node));
    if (response.statusCode >= 400 || response.body == 'null') {
      return [];
    }
    final payload = jsonDecode(response.body);
    if (payload is! List) return [];
    return payload.whereType<String>().toList().reversed.toList();
  }

  Future<void> addText(String node, String value) async {
    final current = await getTextList(node);
    final next = [...current.reversed, value];
    await http.put(
      _uri(node),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(next),
    );
  }

  Future<int> registerDailyView() async {
    final now = DateTime.now();
    final dayKey = _dailyKey(now);
    final currentCount = await _readDailyCount(dayKey);
    final nextCount = currentCount + 1;

    await http.put(
      _uri('viewsByDay/$dayKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': dayKey,
        'count': nextCount,
        'updatedAt': now.toIso8601String(),
      }),
    );
    return nextCount;
  }

  Future<int> getTodayViewCount() async {
    final dayKey = _dailyKey(DateTime.now());
    return _readDailyCount(dayKey);
  }
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _api = _RealtimeApi();
  FeedType? _selectedTopTab;
  List<ListingItem> _items = const [];
  bool _loading = true;
  bool _viewTracked = false;
  int _todayViews = 0;

  FeedType get _activeType => _selectedTopTab ?? FeedType.homes;
  bool get _isAllSelected => _selectedTopTab == null;
  String get _feedCounterLabel => _isAllSelected ? 'Todos' : _activeType.badge;

  @override
  void initState() {
    super.initState();
    _load();
  }

  FeedType _classifyFeed(String description) {
    final normalized = _normalizeText(description);
    var bestType = FeedType.homes;
    var bestScore = 0;

    for (final type in _classificationPriority) {
      final rules = _classificationRules[type];
      if (rules == null) continue;
      final score = _scoreByRules(normalized, rules);
      if (score > bestScore) {
        bestScore = score;
        bestType = type;
      }
    }

    return bestScore == 0 ? FeedType.homes : bestType;
  }

  Future<void> _load() async {
    int? todayViewsAfterRegister;
    if (!_viewTracked) {
      _viewTracked = true;
      todayViewsAfterRegister = await _api.registerDailyView();
    }
    setState(() => _loading = true);
    final data = _isAllSelected
        ? (await Future.wait(
            _allFeedTypes.map(_api.getListings),
          )).expand((group) => group).toList()
        : await _api.getListings(_activeType);
    final viewsFuture = todayViewsAfterRegister != null
        ? Future<int>.value(todayViewsAfterRegister)
        : _api.getTodayViewCount();
    final todayViews = await viewsFuture;
    if (!mounted) return;
    setState(() {
      _items = data;
      _todayViews = todayViews;
      _loading = false;
    });
  }

  Future<void> _openWhatsapp(String number) async {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/57$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showAddModal() async {
    var description = '';
    var number = '';
    FeedType? selectedManualType;

    final savedOnType = await showModalBottomSheet<FeedType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isAllSelected
                        ? 'Agregar en Todos'
                        : 'Agregar en ${_activeType.badge}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isAllSelected) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Elige tipo (opcional). Si no eliges, se clasifica automatico.',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(_topFeedTabs.length, (index) {
                        final type = _topFeedTabs[index];
                        final isSelected = selectedManualType == type;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == _topFeedTabs.length - 1 ? 0 : 6,
                            ),
                            child: OutlinedButton(
                              onPressed: () {
                                setModalState(() {
                                  selectedManualType = isSelected ? null : type;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 10,
                                ),
                                side: BorderSide(
                                  color: isSelected
                                      ? _accentColor
                                      : Colors.white54,
                                ),
                                backgroundColor: isSelected
                                    ? _accentColor
                                    : Colors.transparent,
                                foregroundColor: isSelected
                                    ? _bgColor
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  type.badge,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (value) => description = value,
                    decoration: const InputDecoration(
                      labelText: 'Descripcion',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) => number = value,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numero de whatsapp',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final cleanDescription = description.trim();
                        if (cleanDescription.isEmpty) return;
                        final targetType = _isAllSelected
                            ? (selectedManualType ??
                                  _classifyFeed(cleanDescription))
                            : _activeType;
                        final now = DateTime.now();
                        await _api.addListing(
                          targetType,
                          ListingItem(
                            description: cleanDescription,
                            number: number.trim(),
                            date: _formatDateEs(now),
                            createdAt: now.toIso8601String(),
                          ),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context, targetType);
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (savedOnType != null) {
      final usedAutomaticClassification =
          _isAllSelected && selectedManualType == null;
      if (usedAutomaticClassification &&
          savedOnType != FeedType.homes &&
          mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Se clasifico automaticamente en ${savedOnType.badge}.',
            ),
          ),
        );
      }
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isMedium = screenWidth > 600 && screenWidth <= 1264;
    final horizontalPadding = isMobile
        ? 16.0
        : isMedium
        ? 24.0
        : 36.0;
    final titleFontSize = isMobile
        ? 36.0
        : isMedium
        ? 42.0
        : 48.0;
    final chipFontSize = isMobile
        ? 12.0
        : isMedium
        ? 13.0
        : 14.0;
    final viewsFontSize = isMobile
        ? 14.0
        : isMedium
        ? 15.0
        : 16.0;
    final viewsIconSize = isMobile
        ? 18.0
        : isMedium
        ? 19.0
        : 20.0;
    final tabGap = isMobile
        ? 6.0
        : isMedium
        ? 8.0
        : 10.0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _activeType.title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: viewsIconSize,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _todayViews.toString(),
                        style: TextStyle(
                          fontSize: viewsFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_topFeedTabs.length, (index) {
                final type = _topFeedTabs[index];
                final isSelected = _selectedTopTab == type;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == _topFeedTabs.length - 1 ? 0 : tabGap,
                    ),
                    child: OutlinedButton(
                      onPressed: () async {
                        setState(() {
                          _selectedTopTab = isSelected ? null : type;
                        });
                        await _load();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 10,
                        ),
                        side: BorderSide(
                          color: isSelected ? _accentColor : Colors.white54,
                        ),
                        backgroundColor: isSelected
                            ? _accentColor
                            : Colors.transparent,
                        foregroundColor: isSelected ? _bgColor : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          type.badge,
                          style: TextStyle(
                            fontSize: chipFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_feedCounterLabel: ${_items.length}'),
                TextButton(
                  onPressed: _showAddModal,
                  child: const Text('Agregar'),
                ),
              ],
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('Sin publicaciones aun')),
              )
            else
              ..._items.map((item) {
                return Card(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    onTap: item.number.trim().isEmpty
                        ? null
                        : () => _openWhatsapp(item.number),
                    title: Text(
                      item.displayDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(item.description),
                        if (item.number.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 10),
                          Text(
                            'Whatsapp: ${item.number}',
                            style: const TextStyle(color: Color(0xFF25D366)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class PublicationsScreen extends StatefulWidget {
  const PublicationsScreen({super.key});

  @override
  State<PublicationsScreen> createState() => _PublicationsScreenState();
}

class _PublicationsScreenState extends State<PublicationsScreen> {
  final _api = _RealtimeApi();
  final _controller = TextEditingController();
  bool _loading = true;
  List<String> _publications = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.getTextList('publications');
    if (!mounted) return;
    setState(() {
      _publications = data;
      _loading = false;
    });
  }

  Future<void> _publish() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _api.addText('publications', text);
    _controller.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Inicio',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Quieres decir algo en anonimo?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _publish, child: const Text('Publicar')),
          const Divider(height: 24),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._publications.map(
              (text) => Card(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.white54),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: const Text('anonimo'),
                  subtitle: Text(text),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  final _api = _RealtimeApi();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) return;

    setState(() => _saving = true);
    await _api.addText('emails', email);
    _controller.clear();
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Correo enviado con exito')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'FESTI',
              style: TextStyle(
                fontSize: 46,
                letterSpacing: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Encuentra empleo, roommates, apartamento y recupera tus objetos perdidos.',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Envia tu correo institucional para que seas de los primeros en usarla',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Correo institucional',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: Text(_saving ? 'Enviando...' : 'Enviar'),
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
}
