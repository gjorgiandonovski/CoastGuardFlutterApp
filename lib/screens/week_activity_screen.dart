// ignore_for_file: avoid_print

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/csv_storage.dart';

class WeekActivityScreen extends StatefulWidget {
  const WeekActivityScreen({super.key});

  @override
  State<WeekActivityScreen> createState() => _WeekActivityScreenState();
}

class _WeekActivityScreenState extends State<WeekActivityScreen> {
  static const _usernameKey = 'week_activity_username';
  static const _notificationsKey = 'week_activity_notifications';
  static const _refreshKey = 'week_activity_refresh_seconds';

  final TextEditingController _usernameController = TextEditingController();
  final CsvStorage _csvStorage = CsvStorage();

  final List<String> _logs = <String>[];
  final List<String> _csvRows = <String>[];

  bool _notificationsEnabled = true;
  int _refreshSeconds = 15;
  bool _highlightLifecycle = false;
  String _storageLabel = 'Loading storage location...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _writeLog('WeekActivityScreen.initState');
    _loadPreferences();
    _loadStorageLabel();
    _loadCsvRows();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _writeLog(String message) {
    print(message);
    developer.log(message, name: 'WeekActivity');

    if (!mounted) {
      return;
    }

    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String()}  $message');
      if (_logs.length > 12) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _usernameController.text =
          preferences.getString(_usernameKey) ?? 'Mobile student';
      _notificationsEnabled = preferences.getBool(_notificationsKey) ?? true;
      _refreshSeconds = preferences.getInt(_refreshKey) ?? 15;
    });

    _writeLog('Configuration loaded from SharedPreferences');
  }

  Future<void> _savePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_usernameKey, _usernameController.text.trim());
    await preferences.setBool(_notificationsKey, _notificationsEnabled);
    await preferences.setInt(_refreshKey, _refreshSeconds);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuration saved')));
    _writeLog('Configuration saved to SharedPreferences');
  }

  Future<void> _loadStorageLabel() async {
    final label = await _csvStorage.locationLabel();

    if (!mounted) {
      return;
    }

    setState(() {
      _storageLabel = label;
    });
  }

  Future<void> _loadCsvRows() async {
    final lines = await _csvStorage.readRows();

    if (!mounted) {
      return;
    }

    setState(() {
      _csvRows
        ..clear()
        ..addAll(lines.reversed);
    });

    _writeLog('Loaded ${_csvRows.length} GPS rows from CSV');
  }

  Future<void> _captureLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Enable location services first');
      _writeLog('Location service is disabled');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnackBar('Location permission was not granted');
      _writeLog('Location permission denied');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final row =
        '${DateTime.now().toIso8601String()},${position.latitude},${position.longitude}';

    await _csvStorage.appendRow(row);

    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = position;
    });

    await _loadCsvRows();
    _showSnackBar('GPS coordinates saved to CSV');
    _writeLog('GPS saved: ${position.latitude}, ${position.longitude}');
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAlert() async {
    _writeLog('Showing alert dialog');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alert'),
        content: const Text('This is an alert pop-up message example.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDialogExample() async {
    _writeLog('Showing simple dialog');
    await showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Dialog'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dialog option example'),
          ),
        ],
      ),
    );
  }

  Future<void> _showToast() async {
    _writeLog('Showing toast');
    await Fluttertoast.showToast(msg: 'Toast message example');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Widget lifecycle and logging',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the button to rebuild the lifecycle example. Events are logged with print and dart:developer.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _highlightLifecycle = !_highlightLifecycle;
                        });
                        _writeLog(
                          'Lifecycle demo toggled to $_highlightLifecycle',
                        );
                      },
                      child: const Text('Trigger rebuild'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LifecycleExampleCard(
                        highlighted: _highlightLifecycle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pop-up messages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: _showAlert,
                      child: const Text('Alert'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _writeLog('Showing snackbar');
                        _showSnackBar('Snackbar message example');
                      },
                      child: const Text('Snackbar'),
                    ),
                    ElevatedButton(
                      onPressed: _showDialogExample,
                      child: const Text('Dialog'),
                    ),
                    ElevatedButton(
                      onPressed: _showToast,
                      child: const Text('Toast'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Persistence with SharedPreferences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Configuration name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text('Refresh every $_refreshSeconds seconds'),
                Slider(
                  value: _refreshSeconds.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$_refreshSeconds s',
                  onChanged: (value) {
                    setState(() {
                      _refreshSeconds = value.round();
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: _savePreferences,
                  child: const Text('Save configuration'),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sensors: GPS to CSV',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb
                      ? 'Running on web: CSV rows are stored in browser storage.'
                      : 'CSV file location: $_storageLabel',
                ),
                const SizedBox(height: 8),
                Text(
                  _currentPosition == null
                      ? 'No GPS reading captured yet.'
                      : 'Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _captureLocation,
                  child: const Text('Get GPS and save'),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ListView data from CSV',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: _csvRows.isEmpty
                      ? const Center(child: Text('No stored coordinates yet.'))
                      : ListView.separated(
                          itemCount: _csvRows.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final values = _csvRows[index].split(',');
                            final timestamp = values.isNotEmpty
                                ? values[0]
                                : '';
                            final latitude = values.length > 1 ? values[1] : '';
                            final longitude = values.length > 2
                                ? values[2]
                                : '';

                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place),
                              title: Text('$latitude , $longitude'),
                              subtitle: Text(timestamp),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.terminal),
                        title: Text(_logs[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LifecycleExampleCard extends StatefulWidget {
  const LifecycleExampleCard({super.key, required this.highlighted});

  final bool highlighted;

  @override
  State<LifecycleExampleCard> createState() => _LifecycleExampleCardState();
}

class _LifecycleExampleCardState extends State<LifecycleExampleCard> {
  final List<String> _lifecycleEvents = <String>[];

  void _recordEvent(String message) {
    print(message);
    developer.log(message, name: 'WeekActivity');

    if (!mounted) {
      return;
    }

    setState(() {
      _lifecycleEvents.insert(0, message);
      if (_lifecycleEvents.length > 5) {
        _lifecycleEvents.removeLast();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _recordEvent('LifecycleExampleCard.initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recordEvent('LifecycleExampleCard.didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant LifecycleExampleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recordEvent(
      'LifecycleExampleCard.didUpdateWidget: ${oldWidget.highlighted} -> ${widget.highlighted}',
    );
  }

  @override
  void deactivate() {
    print('LifecycleExampleCard.deactivate');
    developer.log('LifecycleExampleCard.deactivate', name: 'WeekActivity');
    super.deactivate();
  }

  @override
  void dispose() {
    print('LifecycleExampleCard.dispose');
    developer.log('LifecycleExampleCard.dispose', name: 'WeekActivity');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.highlighted
            ? Colors.lightBlue.shade50
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.highlighted ? 'Highlighted state' : 'Normal state',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _lifecycleEvents.isEmpty
                ? 'No lifecycle events yet'
                : _lifecycleEvents.first,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
