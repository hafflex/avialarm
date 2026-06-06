import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AviAlarmApp());
}

class AviAlarmApp extends StatelessWidget {
  const AviAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AviAlarm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlueAccent,
          brightness: Brightness.dark,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// --- ГЛАВНАЯ НАВИГАЦИЯ ---
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AlarmScreen(),
    const ChecklistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF1B263B),
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.blueGrey[400],
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Timeline'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'Checklist'),
        ],
      ),
    );
  }
}

// --- ЭКРАН ALARM (ТАЙМЛАЙН) ---
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  TimeOfDay _reportTime = const TimeOfDay(hour: 13, minute: 35);
  bool _isBusinessTrip = false;
  bool _isUtcMode = false; 

  late Map<String, int> _regularTimings;
  late Map<String, int> _businessTimings;

  @override
  void initState() {
    super.initState();
    _regularTimings = {'coffee': 60, 'makeup': 40, 'road': 60, 'buffer': 20};
    _businessTimings = {'coffee': 60, 'makeup': 60, 'road': 90, 'buffer': 30};
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isBusinessTrip = prefs.getBool('isBusinessTrip') ?? false;
        _isUtcMode = prefs.getBool('isUtcMode') ?? false;
        
        _regularTimings['coffee'] = prefs.getInt('reg_coffee') ?? 60;
        _regularTimings['makeup'] = prefs.getInt('reg_makeup') ?? 40;
        _regularTimings['road'] = prefs.getInt('reg_road') ?? 60;
        _regularTimings['buffer'] = prefs.getInt('reg_buffer') ?? 20;

        _businessTimings['coffee'] = prefs.getInt('bus_coffee') ?? 60;
        _businessTimings['makeup'] = prefs.getInt('bus_makeup') ?? 60;
        _businessTimings['road'] = prefs.getInt('bus_road') ?? 90;
        _businessTimings['buffer'] = prefs.getInt('bus_buffer') ?? 30;

        final h = prefs.getInt('reportHour') ?? 13;
        final m = prefs.getInt('reportMinute') ?? 35;
        _reportTime = TimeOfDay(hour: h, minute: m);
      });
    } catch (e) {
      debugPrint("Ошибка загрузки настроек: $e");
    }
  }

  void _showIosTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ),
        child: Container(
          height: 300,
          color: const Color(0xFF1B263B),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.black26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text('Отмена', style: TextStyle(color: Colors.grey))
                    ),
                    Text(
                      _isUtcMode ? 'Время явки (UTC)' : 'Время явки (Местное)', 
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(2026, 1, 1, _reportTime.hour, _reportTime.minute),
                  onDateTimeChanged: (DateTime newDate) async {
                    setState(() => _reportTime = TimeOfDay(hour: newDate.hour, minute: newDate.minute));
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('reportHour', newDate.hour);
                    await prefs.setInt('reportMinute', newDate.minute);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B263B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Map<String, int> activeMap = _isBusinessTrip ? _businessTimings : _regularTimings;
          String prefix = _isBusinessTrip ? 'bus_' : 'reg_';

          return Container(
            padding: const EdgeInsets.all(24.0),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚙️ НАСТРОЙКИ ВРЕМЕНИ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
                const SizedBox(height: 20),
                
                // Переключатель UTC аккуратно встроен в список настроек
                SwitchListTile(
                  title: const Text('Отображать время в UTC'),
                  subtitle: const Text('Переводит весь расчет таймлайна в формат UTC'),
                  value: _isUtcMode,
                  activeColor: Colors.lightBlueAccent,
                  onChanged: (val) async {
                    setModalState(() => _isUtcMode = val);
                    setState(() => _isUtcMode = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isUtcMode', val);
                  },
                ),
                const Divider(color: Colors.white12, height: 1),

                SwitchListTile(
                  title: const Text('Режим "Командировка"'),
                  subtitle: Text(_isBusinessTrip ? 'Включены увеличенные тайминги' : 'Включены стандартные тайминги'),
                  value: _isBusinessTrip,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) async {
                    setModalState(() => _isBusinessTrip = val);
                    setState(() => _isBusinessTrip = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isBusinessTrip', val);
                  },
                ),
                const Divider(color: Colors.white12),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSlider(setModalState, '☕️ Перекус и сборы', activeMap, 'coffee', prefix),
                        const SizedBox(height: 16),
                        _buildSlider(setModalState, '💄 Макияж', activeMap, 'makeup', prefix),
                        const SizedBox(height: 16),
                        _buildSlider(setModalState, '🚗 Дорога в аэропорт', activeMap, 'road', prefix),
                        const SizedBox(height: 16),
                        _buildSlider(setModalState, '✈️ Запас в терминале', activeMap, 'buffer', prefix),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                      foregroundColor: const Color(0xFF0D1B2A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ГОТОВО', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlider(StateSetter setModalState, String label, Map<String, int> map, String key, String prefix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text('${map[key]} мин', style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold))
          ],
        ),
        Slider(
          value: map[key]!.toDouble(),
          min: 5, 
          max: 180,
          activeColor: Colors.lightBlueAccent,
          inactiveColor: Colors.white10,
          onChanged: (v) async {
            setModalState(() => map[key] = v.toInt());
            setState(() {});
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('$prefix$key', v.toInt());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> active = _isBusinessTrip ? _businessTimings : _regularTimings;
    
    final arrival = _subMinutes(_reportTime, active['buffer']!);
    final road = _subMinutes(_reportTime, active['buffer']! + active['road']!);
    final makeup = _subMinutes(_reportTime, active['buffer']! + active['road']! + active['makeup']!);
    final wakeup = _subMinutes(_reportTime, active['buffer']! + active['road']! + active['makeup']! + active['coffee']!);

    final Color mainColor = _isBusinessTrip ? Colors.cyanAccent : Colors.lightBlueAccent;

    // Считаем локальное время из системного смещения девайса для информера
    final localOffset = DateTime.now().timeZoneOffset.inMinutes;
    final reportLocalTimeStr = _addMinutes(_reportTime, localOffset);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌤 РАСЧЕТ ВРЕМЕНИ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.lightBlueAccent), onPressed: _showSettings),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showIosTimePicker,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mainColor.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _isBusinessTrip 
                        ? '🚀 КОМАНДИРОВКА: ВРЕМЯ ЯВКИ ${_isUtcMode ? "(UTC)" : "(LT)"}' 
                        : '✈️ РАЗВОРОТ: ВРЕМЯ ЯВКИ ${_isUtcMode ? "(UTC)" : "(LT)"}', 
                      style: TextStyle(color: Colors.blueGrey[200], fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_reportTime.hour.toString().padLeft(2, '0')}:${_reportTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: mainColor, letterSpacing: 2),
                    ),
                    
                    // Если включен UTC режим — ненавязчиво выводим местное время на карточке
                    if (_isUtcMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Местное время (LT): $reportLocalTimeStr',
                        style: const TextStyle(fontSize: 14, color: Colors.cyanAccent, fontWeight: FontWeight.w500),
                      ),
                    ],
                    
                    const SizedBox(height: 6),
                    Text('Нажми, чтобы изменить', style: TextStyle(fontSize: 12, color: Colors.blueGrey[400], fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _isUtcMode ? 'План сборов по времени UTC:' : 'План сборов по местному времени:', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildTimelineStep(wakeup, '⏰', 'Просыпаемся и улыбаемся', 'Запас на кофикс, душ и любимый трек: ${active['coffee']} мин.', mainColor, isFirst: true),
                  _buildTimelineStep(makeup, '💄', 'Красимся', 'Макияж, идеальный пучок и форма: ${active['makeup']} мин.', mainColor),
                  _buildTimelineStep(road, '🚗', 'Выезжаем в аэропорт', 'Дорога в аэропорт: ${active['road']} мин.', mainColor),
                  _buildTimelineStep(arrival, '✈️', 'Прибываем в терминал', 'Запас перед брифингом: ${active['buffer']} мин.', mainColor, isLast: true),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String _subMinutes(TimeOfDay time, int minutes) {
    int total = time.hour * 60 + time.minute;
    int newTotal = (total - minutes) % 1440;
    if (newTotal < 0) newTotal += 1440;
    int h = newTotal ~/ 60;
    int m = newTotal % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _addMinutes(TimeOfDay time, int minutes) {
    int total = time.hour * 60 + time.minute;
    int newTotal = (total + minutes) % 1440;
    if (newTotal < 0) newTotal += 1440;
    int h = newTotal ~/ 60;
    int m = newTotal % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Widget _buildTimelineStep(String time, String emoji, String title, String subtitle, Color color, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color, fontFamily: 'Courier')),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 16)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.white10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 28), 
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ЭКРАН CHECKLIST ---
class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<Map<String, dynamic>> _items = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('checklist');
      if (data != null) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(json.decode(data));
        });
      } else {
        setState(() {
          _items = [
            {'title': '✈️ Айдишка', 'checked': false},
            {'title': '🩺 ВЛЭК', 'checked': false},
            {'title': '🛂 Загранпаспорт', 'checked': false},
            {'title': '📱 Зарядка и павербанк', 'checked': false},
            {'title': '💄 Косметичка', 'checked': false},
            {'title': '👔 Форма', 'checked': false},
          ];
        });
        _saveChecklist();
      }
    } catch (e) {
      debugPrint("Ошибка чек-листа: $e");
    }
  }

  Future<void> _saveChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checklist', json.encode(_items));
  }

  void _addItem() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _items.add({'title': _controller.text.trim(), 'checked': false});
      _controller.clear();
    });
    _saveChecklist();
  }

  void _resetChecklist() {
    setState(() {
      for (var item in _items) {
        item['checked'] = false;
      }
    });
    _saveChecklist();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Чек-лист сброшен! Хорошего рейса! 🌤', style: TextStyle(color: Color(0xFF0D1B2A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlueAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 ЧЕКЛИСТ ЭКИПАЖА', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.lightBlueAccent),
              tooltip: 'Сбросить галочки',
              onPressed: _resetChecklist,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        hintText: 'Что нужно взять с собой?',
                        hintStyle: TextStyle(color: Colors.blueGrey[300]),
                        filled: true,
                        fillColor: const Color(0xFF1B263B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.lightBlueAccent, size: 42), 
                    onPressed: _addItem
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
                ? Center(child: Text('Список пуст. Добавь вещи в полет! ✈️', style: TextStyle(color: Colors.blueGrey[400])))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final sortedItems = List<Map<String, dynamic>>.from(_items);
                      sortedItems.sort((a, b) {
                        final aChecked = a['checked'] ?? false;
                        final bChecked = b['checked'] ?? false;
                        if (aChecked == bChecked) return 0;
                        return aChecked ? 1 : -1;
                      });

                      final item = sortedItems[index];
                      final isChecked = item['checked'] ?? false;
                      final originalIndex = _items.indexOf(item);

                      return Card(
                        color: const Color(0xFF1B263B),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Checkbox(
                            value: isChecked,
                            activeColor: Colors.lightBlueAccent,
                            onChanged: (val) {
                              setState(() {
                                _items[originalIndex]['checked'] = val;
                              });
                              _saveChecklist();
                            },
                          ),
                          title: Text(
                            item['title'], 
                            style: TextStyle(
                              color: isChecked ? Colors.blueGrey[400] : Colors.white,
                              decoration: isChecked ? TextDecoration.lineThrough : null
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(originalIndex);
                              });
                              _saveChecklist();
                            },
                          ),
                        ),
                      );
                    },
                  ),
            )
          ],
        ),
      ),
    );
  }
}