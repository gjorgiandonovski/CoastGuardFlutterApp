import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const String _allReportsFilter = 'All';

  String _selectedFilter = _allReportsFilter;
  String? _selectedBeachId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('beaches').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final beaches =
            snapshot.data?.docs.map(_Beach.fromDocument).toList() ?? <_Beach>[];

        return _MapScreenBody(
          beaches: beaches,
          selectedBeachId: _selectedBeachId,
          selectedFilter: _selectedFilter,
          onFilterSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
              _selectedBeachId = null;
            });
          },
          onBeachSelected: (beach) {
            setState(() {
              _selectedBeachId = beach.id;
            });
          },
        );
      },
    );
  }
}

class _MapScreenBody extends StatelessWidget {
  const _MapScreenBody({
    required this.beaches,
    required this.selectedBeachId,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onBeachSelected,
  });

  final List<_Beach> beaches;
  final String? selectedBeachId;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<_Beach> onBeachSelected;

  @override
  Widget build(BuildContext context) {
    final filters = _reportFilters;
    final effectiveFilter = filters.contains(selectedFilter)
        ? selectedFilter
        : _MapScreenState._allReportsFilter;
    final visibleBeaches = beaches
        .where(
          (beach) =>
              effectiveFilter == _MapScreenState._allReportsFilter ||
              beach.reportTypes.contains(effectiveFilter),
        )
        .toList();
    final selectedBeach = visibleBeaches.isEmpty
        ? null
        : visibleBeaches.firstWhere(
            (beach) => beach.id == selectedBeachId,
            orElse: () => visibleBeaches.first,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReportFilterChips(
                filters: filters,
                selectedFilter: effectiveFilter,
                onSelected: onFilterSelected,
              ),
              const SizedBox(height: 12),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CoastalMapCard(
                        beaches: visibleBeaches,
                        selectedBeach: selectedBeach,
                        onBeachSelected: onBeachSelected,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 320,
                      child: selectedBeach == null
                          ? const _EmptyDetails()
                          : _SelectedBeachDetails(beach: selectedBeach),
                    ),
                  ],
                )
              else ...[
                _CoastalMapCard(
                  beaches: visibleBeaches,
                  selectedBeach: selectedBeach,
                  onBeachSelected: onBeachSelected,
                ),
                const SizedBox(height: 12),
                selectedBeach == null
                    ? const _EmptyDetails()
                    : _SelectedBeachDetails(beach: selectedBeach),
              ],
              const SizedBox(height: 16),
              _BeachList(
                beaches: visibleBeaches,
                selectedBeach: selectedBeach,
                onBeachSelected: onBeachSelected,
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> get _reportFilters {
    final reportTypes =
        beaches
            .expand((beach) => beach.reportTypes)
            .where((type) => type.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return [_MapScreenState._allReportsFilter, ...reportTypes];
  }
}

class _ReportFilterChips extends StatelessWidget {
  const _ReportFilterChips({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            FilterChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              showCheckmark: false,
              avatar: Icon(
                filter == _MapScreenState._allReportsFilter
                    ? Icons.tune
                    : Icons.report_problem_outlined,
                size: 18,
              ),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CoastalMapCard extends StatelessWidget {
  const _CoastalMapCard({
    required this.beaches,
    required this.selectedBeach,
    required this.onBeachSelected,
  });

  final List<_Beach> beaches;
  final _Beach? selectedBeach;
  final ValueChanged<_Beach> onBeachSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pinnedBeaches = beaches
        .where((beach) => beach.hasCoordinates)
        .toList();

    return Container(
      height: 330,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _CoastalMapPainter()),
                ),
                for (final beach in pinnedBeaches)
                  _BeachPin(
                    beach: beach,
                    position: _projectBeachPosition(beach, pinnedBeaches, size),
                    isSelected: beach.id == selectedBeach?.id,
                    onSelected: onBeachSelected,
                  ),
                if (pinnedBeaches.isEmpty)
                  Center(
                    child: _MapNotice(
                      icon: Icons.location_off_outlined,
                      message: beaches.isEmpty
                          ? 'No beaches found in Firestore.'
                          : 'Add latitude and longitude fields to show pins.',
                    ),
                  ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${pinnedBeaches.length}/${beaches.length} pins',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Offset _projectBeachPosition(_Beach beach, List<_Beach> beaches, Size size) {
    if (beaches.length == 1) {
      return Offset(size.width * 0.48, size.height * 0.48);
    }

    final minLat = beaches.map((beach) => beach.latitude!).reduce(math.min);
    final maxLat = beaches.map((beach) => beach.latitude!).reduce(math.max);
    final minLng = beaches.map((beach) => beach.longitude!).reduce(math.min);
    final maxLng = beaches.map((beach) => beach.longitude!).reduce(math.max);
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;

    if (latSpan == 0 || lngSpan == 0) {
      return Offset(size.width * 0.48, size.height * 0.48);
    }

    final normalizedX = (beach.longitude! - minLng) / lngSpan;
    final normalizedY = 1 - ((beach.latitude! - minLat) / latSpan);

    return Offset(
      size.width * (0.18 + normalizedX * 0.62),
      size.height * (0.16 + normalizedY * 0.68),
    );
  }
}

class _BeachPin extends StatelessWidget {
  const _BeachPin({
    required this.beach,
    required this.position,
    required this.isSelected,
    required this.onSelected,
  });

  final _Beach beach;
  final Offset position;
  final bool isSelected;
  final ValueChanged<_Beach> onSelected;

  @override
  Widget build(BuildContext context) {
    final pinColor = _riskColor(beach.riskLevel);
    final pinSize = isSelected ? 46.0 : 38.0;

    return Positioned(
      left: position.dx - pinSize / 2,
      top: position.dy - pinSize,
      width: pinSize,
      height: pinSize,
      child: Semantics(
        button: true,
        label: 'Select ${beach.name}',
        child: GestureDetector(
          onTap: () => onSelected(beach),
          child: AnimatedScale(
            scale: isSelected ? 1.08 : 1,
            duration: const Duration(milliseconds: 160),
            child: Icon(
              Icons.location_on,
              size: pinSize,
              color: pinColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedBeachDetails extends StatelessWidget {
  const _SelectedBeachDetails({required this.beach});

  final _Beach beach;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskColor = _riskColor(beach.riskLevel);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beach.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (beach.municipality.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          beach.municipality,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                if (beach.status.isNotEmpty)
                  _StatusPill(label: beach.status, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (beach.reportTypes.isNotEmpty)
                  _MetricTile(
                    icon: Icons.report_problem_outlined,
                    label: 'Report',
                    value: beach.reportTypes.join(', '),
                    color: colorScheme.tertiary,
                  ),
                if (beach.riskLevel.isNotEmpty)
                  _MetricTile(
                    icon: Icons.warning_amber_outlined,
                    label: 'Risk',
                    value: beach.riskLevel,
                    color: riskColor,
                  ),
                _MetricTile(
                  icon: Icons.assignment_outlined,
                  label: 'Active',
                  value: beach.activeReports.toString(),
                  color: colorScheme.primary,
                ),
              ],
            ),
            if (beach.cleanlinessScore != null) ...[
              const SizedBox(height: 16),
              Text(
                'Cleanliness',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: beach.cleanlinessScore!.clamp(0, 100) / 100,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _cleanlinessColor(beach.cleanlinessScore!),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${beach.cleanlinessScore}/100',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (beach.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                beach.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 132,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyDetails extends StatelessWidget {
  const _EmptyDetails();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Select a beach to see details.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _BeachList extends StatelessWidget {
  const _BeachList({
    required this.beaches,
    required this.selectedBeach,
    required this.onBeachSelected,
  });

  final List<_Beach> beaches;
  final _Beach? selectedBeach;
  final ValueChanged<_Beach> onBeachSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Beach list', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (beaches.isEmpty)
          const _MapNotice(
            icon: Icons.beach_access_outlined,
            message: 'No beaches found for this filter.',
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: beaches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final beach = beaches[index];

              return _BeachListTile(
                beach: beach,
                isSelected: beach.id == selectedBeach?.id,
                onTap: () => onBeachSelected(beach),
              );
            },
          ),
      ],
    );
  }
}

class _BeachListTile extends StatelessWidget {
  const _BeachListTile({
    required this.beach,
    required this.isSelected,
    required this.onTap,
  });

  final _Beach beach;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final riskColor = _riskColor(beach.riskLevel);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.54)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: riskColor.withValues(alpha: 0.14),
          child: Icon(Icons.beach_access, color: riskColor),
        ),
        title: Text(beach.name),
        subtitle: Text(
          [
            beach.municipality,
            ...beach.reportTypes,
            if (!beach.hasCoordinates) 'No coordinates',
          ].where((value) => value.isNotEmpty).join(' • '),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (beach.riskLevel.isNotEmpty)
              Text(
                beach.riskLevel,
                style: TextStyle(color: riskColor, fontWeight: FontWeight.w700),
              ),
            if (beach.cleanlinessScore != null)
              Text(
                '${beach.cleanlinessScore}/100',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoastalMapPainter extends CustomPainter {
  const _CoastalMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final seaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB9ECF2), Color(0xFF4DA7BC)],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, seaPaint);
    _drawWaterLines(canvas, size);

    final landPath = Path()
      ..moveTo(size.width * 0.42, 0)
      ..cubicTo(
        size.width * 0.29,
        size.height * 0.16,
        size.width * 0.54,
        size.height * 0.26,
        size.width * 0.43,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.56,
        size.width * 0.70,
        size.height * 0.62,
        size.width * 0.56,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.91,
        size.width * 0.61,
        size.height,
        size.width * 0.58,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(
      landPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFDFA2), Color(0xFF8DB57B)],
        ).createShader(Offset.zero & size),
    );

    final coastPath = Path()
      ..moveTo(size.width * 0.42, 0)
      ..cubicTo(
        size.width * 0.29,
        size.height * 0.16,
        size.width * 0.54,
        size.height * 0.26,
        size.width * 0.43,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.56,
        size.width * 0.70,
        size.height * 0.62,
        size.width * 0.56,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.91,
        size.width * 0.61,
        size.height,
        size.width * 0.58,
        size.height,
      );

    canvas.drawPath(
      coastPath,
      Paint()
        ..color = const Color(0xFFF7C873)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      coastPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawWaterLines(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.13 + i * 0.14);
      final path = Path()..moveTo(size.width * 0.05, y);

      for (var x = 0.05; x < 0.78; x += 0.16) {
        path.quadraticBezierTo(
          size.width * (x + 0.04),
          y - 10,
          size.width * (x + 0.08),
          y,
        );
        path.quadraticBezierTo(
          size.width * (x + 0.12),
          y + 10,
          size.width * (x + 0.16),
          y,
        );
      }

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Beach {
  const _Beach({
    required this.id,
    required this.name,
    required this.municipality,
    required this.riskLevel,
    required this.reportTypes,
    required this.status,
    required this.activeReports,
    required this.description,
    this.cleanlinessScore,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String municipality;
  final String riskLevel;
  final List<String> reportTypes;
  final String status;
  final int? cleanlinessScore;
  final int activeReports;
  final String description;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory _Beach.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final location = data['location'];

    return _Beach(
      id: doc.id,
      name: _readString(data, const [
        'name',
        'beachName',
        'title',
      ], fallback: doc.id),
      municipality: _readString(data, const ['municipality', 'city', 'area']),
      riskLevel: _readString(data, const ['riskLevel', 'risk', 'severity']),
      reportTypes: _readReportTypes(data),
      status: _readString(data, const ['status', 'condition']),
      cleanlinessScore: _readInt(data, const [
        'cleanlinessScore',
        'cleanliness',
        'score',
      ])?.clamp(0, 100),
      activeReports: _readReportCount(data),
      description: _readString(data, const ['description', 'notes', 'summary']),
      latitude:
          _readDouble(data, const ['latitude', 'lat']) ??
          (location is GeoPoint ? location.latitude : null),
      longitude:
          _readDouble(data, const ['longitude', 'lng', 'lon']) ??
          (location is GeoPoint ? location.longitude : null),
    );
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return fallback;
  }

  static List<String> _readReportTypes(Map<String, dynamic> data) {
    final reportTypes = <String>{};

    for (final key in const [
      'reportType',
      'reportTypes',
      'category',
      'categories',
      'primaryReport',
      'mainIssue',
    ]) {
      _addReportType(reportTypes, data[key]);
    }

    final reports = data['reports'];
    if (reports is Iterable) {
      for (final report in reports) {
        _addReportType(reportTypes, report);
      }
    }

    return reportTypes.toList()..sort();
  }

  static void _addReportType(Set<String> reportTypes, Object? value) {
    if (value == null) {
      return;
    }

    if (value is Iterable && value is! String) {
      for (final item in value) {
        _addReportType(reportTypes, item);
      }
      return;
    }

    if (value is Map) {
      for (final key in const [
        'reportType',
        'type',
        'category',
        'issue',
        'mainIssue',
      ]) {
        _addReportType(reportTypes, value[key]);
      }
      return;
    }

    final text = value.toString().trim();
    if (text.isNotEmpty) {
      reportTypes.add(text);
    }
  }

  static int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static double? _readDouble(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static int _readReportCount(Map<String, dynamic> data) {
    final reports = data['reports'];
    if (reports is Iterable) {
      return reports.length;
    }

    return _readInt(data, const [
          'activeReports',
          'reportCount',
          'reportsCount',
        ]) ??
        0;
  }
}

Color _riskColor(String riskLevel) {
  final risk = riskLevel.toLowerCase();
  if (risk.contains('high') || risk.contains('critical')) {
    return const Color(0xFFD9534F);
  }
  if (risk.contains('medium') ||
      risk.contains('moderate') ||
      risk.contains('advisory')) {
    return const Color(0xFFE29F36);
  }
  if (risk.contains('low') || risk.contains('safe')) {
    return const Color(0xFF2E8B57);
  }

  return const Color(0xFF4F6C8A);
}

Color _cleanlinessColor(int cleanlinessScore) {
  if (cleanlinessScore >= 80) {
    return const Color(0xFF2E8B57);
  }
  if (cleanlinessScore >= 60) {
    return const Color(0xFFE29F36);
  }

  return const Color(0xFFD9534F);
}
