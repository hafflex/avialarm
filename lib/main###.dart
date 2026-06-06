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
        scaffoldBackgroundColor: const Color(0xFF121214),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
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
        backgroundColor: const Color(0xFF1E1E22),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
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
          color: const Color(0xFF1E1E22),
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
                    const Text('Выберите время явки', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Готово', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
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
      backgroundColor: const Color(0xFF1E1E22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Map<String, int> activeMap = _isBusinessTrip ? _businessTimings : _regularTimings;
          String prefix = _isBusinessTrip ? 'bus_' : 'reg_';

          return Container(
            padding: const EdgeInsets.all(24.0),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚙️ ЛИЧНЫЕ НАСТРОЙКИ ВРЕМЕНИ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  title: const Text('Режим "Командировка"'),
                  subtitle: Text(_isBusinessTrip ? 'Включены увеличенные тайминги' : 'Включены стандартные тайминги'),
                  value: _isBusinessTrip,
                  activeColor: Colors.pinkAccent,
                  onChanged: (val) async {
                    setModalState(() => _isBusinessTrip = val);
                    setState(() => _isBusinessTrip = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isBusinessTrip', val);
                  },
                ),
                const Divider(),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSlider(setModalState, '☕️ Подъем и coffee time', activeMap, 'coffee', prefix),
                        const SizedBox(height: 16),
                        _buildSlider(setModalState, '💄 Время красоты', activeMap, 'makeup', prefix),
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
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
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
            Text('${map[key]} мин', style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold))
          ],
        ),
        Slider(
          value: map[key]!.toDouble(),
          min: 5, 
          max: 180,
          activeColor: Colors.pinkAccent,
          inactiveColor: Colors.grey[800],
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

    final Color mainColor = _isBusinessTrip ? Colors.orangeAccent : Colors.pinkAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌤 ЭКИПАЖНЫЙ ТАЙМЛАЙН', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettings),
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
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mainColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _isBusinessTrip ? '🚀 КОМАНДИРОВКА: ВРЕМЯ ЯВКИ' : '✈️ РАЗВОРОТ: ВРЕМЯ ЯВКИ', 
                      style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_reportTime.hour.toString().padLeft(2, '0')}:${_reportTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: mainColor, letterSpacing: 2),
                    ),
                    const SizedBox(height: 6),
                    Text('Нажми, чтобы изменить', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text('План твоих сборов:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildTimelineStep(wakeup, '⏰', 'Проснуться и потянуться', 'Запас на кофе, душ и любимый трек: ${active['coffee']} мин.', mainColor),
                  _buildTimelineStep(makeup, '💄', 'Время красоты', 'Макияж, идеальный пучок и форма: ${active['makeup']} мин.', mainColor),
                  _buildTimelineStep(road, '🚗', 'Выезд в аэропорт', 'Дорога в аэропорт: ${active['road']} мин.', mainColor),
                  _buildTimelineStep(arrival, '✈️', 'Прибытие в терминал', 'Запас перед брифингом: ${active['buffer']} мин.', mainColor),
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

  Widget _buildTimelineStep(String time, String emoji, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 55,
            child: Text(time, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(width: 12),
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
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
        // --- ИДЕЯ 2: ШАБЛОН ПО УМОЛЧАНИЮ ПРИ ПЕРВОМ ЗАПУСКЕ ---
        setState(() {
          _items = [
            {'title': '✈️ Свидетельство / ID-карта', 'checked': false},
            {'title': '🩺 ВЛЭК (Медицина)', 'checked': false},
            {'title': '🛂 Загранпаспорт', 'checked': false},
            {'title': '📱 Зарядка и внешний аккумулятор', 'checked': false},
            {'title': '💄 Косметичка / Набор гигиены', 'checked': false},
            {'title': '👔 Форма и сменная обувь', 'checked': false},
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

  // --- ИДЕЯ 1: МЕТОД ДЛЯ СБРОСА ВСЕХ ГАЛОЧЕК ---
  void _resetChecklist() {
    setState(() {
      for (var item in _items) {
        item['checked'] = false;
      }
    });
    _saveChecklist();
    
    // Покажем красивое уведомление внизу экрана
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Чек-лист сброшен! Чистого неба и хорошего рейса! 🌤'),
        backgroundColor: Colors.pinkAccent.withOpacity(0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 ЭКИПАЖНЫЙ ЧЕКЛИСТ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ДОБАВИЛИ КНОПКУ СБРОСА В ВЕРХНИЙ ПАНЕЛЬ
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.pinkAccent),
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
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: const Color(0xFF1E1E22),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.pinkAccent, size: 42), 
                    onPressed: _addItem
                  ),
                ],
              ),
            ),
            Expanded(
              child: _items.isEmpty
    ? Center(child: Text('Список пуст. Добавь вещи в полет! ✈️', style: TextStyle(color: Colors.grey[500])))
    : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          // --- ДОБАВЛЯЕМ СОРТИРОВКУ НАЛЕТУ ---
          // Создаем отсортированную копию списка: сначала невыполненные, потом выполненные
          final sortedItems = List<Map<String, dynamic>>.from(_items);
          sortedItems.sort((a, b) {
            final aChecked = a['checked'] ?? false;
            final bChecked = b['checked'] ?? false;
            if (aChecked == bChecked) return 0;
            return aChecked ? 1 : -1; // Если true (выполнено), сдвигаем вниз
          });

          // Теперь берем элемент из уже отсортированного списка
          final item = sortedItems[index];
          final isChecked = item['checked'] ?? false;
          
          // Находим оригинальный индекс элемента в основном списке _items,
          // чтобы правильно менять его статус или удалять
          final originalIndex = _items.indexOf(item);

          return Card(
            color: const Color(0xFF1E1E22),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Checkbox(
                value: isChecked,
                activeColor: Colors.pinkAccent,
                onChanged: (val) {
                  setState(() {
                    // Меняем статус по оригинальному индексу
                    _items[originalIndex]['checked'] = val;
                  });
                  _saveChecklist();
                },
              ),
              title: Text(
                item['title'], 
                style: TextStyle(
                  color: isChecked ? Colors.grey : Colors.white,
                  decoration: isChecked ? TextDecoration.lineThrough : null
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    // Удаляем по оригинальному индексу
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