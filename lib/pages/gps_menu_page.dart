import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'gps_location_page.dart';
import 'network_location_page.dart';
import 'experiment_management_page.dart'; // import experiment management page

class GPSMenuPage extends StatelessWidget {
  static const String routeName = '/gps-menu';

  const GPSMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelacak Lokasi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView( // wrap with SingleChildScrollView to accommodate 3 cards
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Network Location Card
              GestureDetector(
                onTap: () => Get.toNamed(NetworkLocationPage.routeName),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.router,
                            color: Colors.blue.shade700,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Network Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lacak posisi menggunakan Network Provider',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // GPS Location Card
              GestureDetector(
                onTap: () => Get.toNamed(GPSLocationPage.routeName),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.gps_fixed,
                            color: Colors.green.shade700,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Lacak posisi menggunakan GPS',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Get.toNamed(ExperimentManagementPage.routeName),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade50,
                          Colors.purple.shade100,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.assessment,
                            color: Colors.purple.shade700,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manajemen Eksperimen',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Buat & analisis eksperimen lokasi GPS vs Network',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
