import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/experiment_controller.dart';
import '../models/experiment_session.dart';

class ExperimentManagementPage extends StatefulWidget {
  static const String routeName = '/experiment-management';

  const ExperimentManagementPage({super.key});

  @override
  State<ExperimentManagementPage> createState() => _ExperimentManagementPageState();
}

class _ExperimentManagementPageState extends State<ExperimentManagementPage> with SingleTickerProviderStateMixin {
  late ExperimentController controller;
  late TabController _tabController;
  final nameController = TextEditingController();
  final intervalController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    controller = Get.find<ExperimentController>();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameController.dispose();
    intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Experiment Lab'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.create), text: 'Manager'),
            Tab(icon: Icon(Icons.timer), text: 'Recorder'),
            Tab(icon: Icon(Icons.table_chart), text: 'Compare'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExperimentManager(),
          _buildIntervalRecorder(),
          _buildComparisonTable(),
          _buildAnalyticsDashboard(),
        ],
      ),
    );
  }

  // TAB 1: Experiment Manager
  Widget _buildExperimentManager() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create New Session Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Experiment Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Session Name',
                      hintText: 'e.g., Campus Test 001',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: intervalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Interval (seconds)',
                      hintText: '10',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Create Session', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Current Session Info
          const Text(
            'Current Session',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.currentSession.value == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No active session',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            final session = controller.currentSession.value!;
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Records: ${session.totalRecords}'),
                        Text('Interval: ${session.intervalSeconds}s'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: controller.saveCurrentSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text('Save Session', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _createSession(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text('New Session', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Saved Sessions
          const Text(
            'Saved Sessions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.sessions.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No saved sessions',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.sessions.length,
              itemBuilder: (context, index) {
                final session = controller.sessions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(session.name),
                    subtitle: Text('${session.totalRecords} records • Created: ${session.createdAt.toString().split('.')[0]}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Text('Load'),
                          onTap: () => controller.loadSession(session),
                        ),
                        PopupMenuItem(
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          onTap: () => controller.deleteSession(session.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // TAB 2: Interval Recorder
  Widget _buildIntervalRecorder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.currentSession.value == null) {
              return Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create a session first to start recording',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      controller.currentSession.value!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Interval: ${controller.currentSession.value!.intervalSeconds} seconds',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      return Text(
                        controller.recordingMessage.value,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: controller.recordingProgress.value < 100 ? 
                            controller.recordingProgress.value / 100 : 1.0,
                          minHeight: 8,
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      return Text(
                        'Records: ${controller.recordingProgress.value}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      );
                    }),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(() {
                            return ElevatedButton.icon(
                              onPressed: controller.isRecording.value 
                                ? null 
                                : controller.startIntervalRecording,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Obx(() {
                            return ElevatedButton.icon(
                              onPressed: !controller.isRecording.value 
                                ? null 
                                : controller.stopRecording,
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // TAB 3: Comparison Table
  Widget _buildComparisonTable() {
    return Obx(() {
      if (controller.currentSession.value == null) {
        return Center(
          child: Text(
            'Load a session to compare data',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }

      final session = controller.currentSession.value!;
      final maxRecords = [session.gpsData.length, session.networkData.length].reduce((a, b) => a > b ? a : b);

      if (maxRecords == 0) {
        return Center(
          child: Text(
            'No data to compare. Start recording first.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('GPS Avg Accuracy', style: TextStyle(fontSize: 12)),
                          Text(
                            '${session.gpsAverageAccuracy.toStringAsFixed(2)}m',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Network Avg Accuracy', style: TextStyle(fontSize: 12)),
                          Text(
                            '${session.networkAverageAccuracy.toStringAsFixed(2)}m',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Difference', style: TextStyle(fontSize: 12)),
                          Text(
                            '${session.accuracyDifference.toStringAsFixed(2)}m',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Detailed Comparison Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('GPS Lat')),
                  DataColumn(label: Text('GPS Lon')),
                  DataColumn(label: Text('GPS Acc')),
                  DataColumn(label: Text('Net Lat')),
                  DataColumn(label: Text('Net Lon')),
                  DataColumn(label: Text('Net Acc')),
                ],
                rows: List.generate(maxRecords, (index) {
                  final gpsData = index < session.gpsData.length ? session.gpsData[index] : null;
                  final netData = index < session.networkData.length ? session.networkData[index] : null;

                  return DataRow(cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(Text(gpsData?.latitude.toStringAsFixed(5) ?? '-')),
                    DataCell(Text(gpsData?.longitude.toStringAsFixed(5) ?? '-')),
                    DataCell(Text(gpsData?.accuracy.toStringAsFixed(1) ?? '-')),
                    DataCell(Text(netData?.latitude.toStringAsFixed(5) ?? '-')),
                    DataCell(Text(netData?.longitude.toStringAsFixed(5) ?? '-')),
                    DataCell(Text(netData?.accuracy.toStringAsFixed(1) ?? '-')),
                  ]);
                }),
              ),
            ),
          ],
        ),
      );
    });
  }

  // TAB 4: Analytics Dashboard
  Widget _buildAnalyticsDashboard() {
    return Obx(() {
      if (controller.currentSession.value == null) {
        return Center(
          child: Text(
            'Load a session to view analytics',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }

      final session = controller.currentSession.value!;
      if (session.gpsData.isEmpty && session.networkData.isEmpty) {
        return Center(
          child: Text(
            'No data available for analytics',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Accuracy Comparison Chart
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accuracy Comparison',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: session.gpsAverageAccuracy,
                                  color: Colors.blue,
                                  width: 30,
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: session.networkAverageAccuracy,
                                  color: Colors.green,
                                  width: 30,
                                ),
                              ],
                            ),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return value == 0 ? const Text('GPS') : const Text('Network');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}m');
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Cards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detailed Statistics',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('GPS Records', '${session.gpsData.length}'),
                    _buildStatRow('Network Records', '${session.networkData.length}'),
                    _buildStatRow('GPS Avg Accuracy', '${session.gpsAverageAccuracy.toStringAsFixed(2)}m'),
                    _buildStatRow('Network Avg Accuracy', '${session.networkAverageAccuracy.toStringAsFixed(2)}m'),
                    _buildStatRow('Accuracy Difference', '${session.accuracyDifference.toStringAsFixed(2)}m'),
                    _buildStatRow('Recording Duration', '${(session.completedAt?.difference(session.createdAt).inSeconds ?? 0)}s'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Export Data
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export as CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _createSession() {
    final name = nameController.text.trim();
    final intervalStr = intervalController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a session name');
      return;
    }

    final interval = int.tryParse(intervalStr) ?? 10;
    if (interval < 5 || interval > 300) {
      Get.snackbar('Error', 'Interval must be between 5 and 300 seconds');
      return;
    }

    controller.createSession(name: name, intervalSeconds: interval);
    nameController.clear();
    intervalController.text = '10';
  }

  void _exportData() {
    final csv = controller.exportToCSV();
    Get.snackbar('Export', 'Data exported successfully!\n\n$csv');
  }
}
