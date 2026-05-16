import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const _bgColor = Color(0xFF000516);
const _accentColor = Color(0xFFC3AFFF);
const _baseRtdbUrl = 'https://festi-suggest-default-rtdb.firebaseio.com';

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
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Suscribirse'),
        ],
      ),
    );
  }
}

enum FeedType { homes, jobs, services, losts }

extension FeedTypeValues on FeedType {
  String get node => switch (this) {
        FeedType.homes => 'homes',
        FeedType.jobs => 'jobs',
        FeedType.services => 'services',
        FeedType.losts => 'losts',
      };

  String get title => switch (this) {
        FeedType.homes => 'HOME',
        FeedType.jobs => 'JOBS',
        FeedType.services => 'TOOLS',
        FeedType.losts => 'LOST',
      };

  String get badge => switch (this) {
        FeedType.homes => 'Solicitudes',
        FeedType.jobs => 'Empleos',
        FeedType.services => 'Servicios',
        FeedType.losts => 'Perdidos',
      };
}

class ListingItem {
  const ListingItem({required this.description, this.number = ''});

  final String description;
  final String number;

  factory ListingItem.fromJson(Map<String, dynamic> json) {
    return ListingItem(
      description: (json['description'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'number': number,
      };
}

class _RealtimeApi {
  Uri _uri(String node) => Uri.parse('$_baseRtdbUrl/$node.json');

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

  Future<void> registerView() async {
    final current = await getTextList('views');
    final now = DateTime.now().toIso8601String();
    final next = [...current.reversed, 'view-$now'];
    await http.put(
      _uri('views'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(next),
    );
  }
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _api = _RealtimeApi();
  FeedType _type = FeedType.homes;
  List<ListingItem> _items = const [];
  bool _loading = true;
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_viewTracked) {
      _viewTracked = true;
      await _api.registerView();
    }
    setState(() => _loading = true);
    final data = await _api.getListings(_type);
    if (!mounted) return;
    setState(() {
      _items = data;
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

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgColor,
      builder: (context) {
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
              Text('Agregar en ${_type.title}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    await _api.addListing(
                      _type,
                      ListingItem(
                        description: cleanDescription,
                        number: number.trim(),
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _type.title,
              style: const TextStyle(
                fontSize: 36,
                letterSpacing: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FeedType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type.badge),
                      selected: _type == type,
                      onSelected: (_) async {
                        setState(() => _type = type);
                        await _load();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_type.badge}: ${_items.length}'),
                TextButton(
                  onPressed: _showAddModal,
                  child: const Text('Agregar'),
                ),
              ],
            ),
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
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
                    onTap: () => _openWhatsapp(item.number),
                    title: Text(item.description),
                    subtitle: item.number.trim().isEmpty
                        ? null
                        : Text('Whatsapp: ${item.number}',
                            style: const TextStyle(color: Color(0xFF25D366))),
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
          const Text('Inicio',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Que quieres decir?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _publish, child: const Text('Publicar')),
          const Divider(height: 24),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            ..._publications.map((text) => Card(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: const Text('anonimo'),
                    subtitle: Text(text),
                  ),
                )),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correo enviado con exito')),
    );
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
              style: TextStyle(fontSize: 46, letterSpacing: 10, fontWeight: FontWeight.w600),
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
