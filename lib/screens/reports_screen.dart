import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/report_api_service.dart';
import 'create_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static final ReportApiService _reportApiService = ReportApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Report>>(
        stream: _reportApiService.watchRecentReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? const <Report>[];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _ReportCard(report: reports[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateReportScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _severityColor(
            report.severity,
          ).withValues(alpha: 0.14),
          child: Icon(
            Icons.report_problem,
            color: _severityColor(report.severity),
          ),
        ),
        title: Text(
          report.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${report.beach}\n${report.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          report.severity,
          style: TextStyle(
            color: _severityColor(report.severity),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'low':
      return Colors.green;
    case 'high':
      return Colors.orange;
    case 'critical':
      return Colors.red;
    default:
      return Colors.amber.shade800;
  }
}
