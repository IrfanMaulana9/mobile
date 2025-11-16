import 'package:get/get.dart';
import '../models/performance_result.dart';
import '../services/http_performance_service.dart';
import '../services/dio_performance_service.dart';

class PerformanceController extends GetxController {
  final httpService = HttpPerformanceService();
  final dioService = DioPerformanceService();

  final isLoading = false.obs;
  final httpResults = <PerformanceResult>[].obs;
  final dioResults = <PerformanceResult>[].obs;
  final selectedCity = 'Jakarta'.obs;
  final iterations = 5.obs;

  final cityCoordinates = {
    // Jawa
    'Jakarta': {'lat': -6.2088, 'lon': 106.8456},
    'Surabaya': {'lat': -7.2575, 'lon': 112.7521},
    'Bandung': {'lat': -6.9175, 'lon': 107.6062},
    'Yogyakarta': {'lat': -7.7956, 'lon': 110.3695},
    'Semarang': {'lat': -6.9667, 'lon': 110.4167},
    'Bogor': {'lat': -6.5971, 'lon': 106.8060},
    'Bekasi': {'lat': -6.2349, 'lon': 107.0055},
    'Depok': {'lat': -6.4025, 'lon': 106.7942},
    'Tangerang': {'lat': -6.1783, 'lon': 106.6326},
    'Cirebon': {'lat': -6.7033, 'lon': 108.4689},
    'Pekalongan': {'lat': -6.8889, 'lon': 109.6833},
    'Tegal': {'lat': -6.8667, 'lon': 109.1333},
    'Purwokerto': {'lat': -7.4167, 'lon': 109.2333},
    'Magelang': {'lat': -7.4833, 'lon': 110.2167},
    'Wonosobo': {'lat': -7.7167, 'lon': 107.5667},
    'Cilacap': {'lat': -7.7333, 'lon': 109.0167},
    'Kudus': {'lat': -6.9167, 'lon': 110.8333},
    'Jepara': {'lat': -6.8667, 'lon': 110.6667},
    'Pati': {'lat': -6.7667, 'lon': 111.1167},
    'Rembang': {'lat': -6.7167, 'lon': 111.4333},
    'Blora': {'lat': -6.9667, 'lon': 111.4},
    'Gresik': {'lat': -7.1667, 'lon': 112.6667},
    'Sidoarjo': {'lat': -7.4333, 'lon': 112.7167},
    'Mojokerto': {'lat': -7.4667, 'lon': 112.8167},
    'Jombang': {'lat': -7.5333, 'lon': 112.2333},
    'Nganjuk': {'lat': -7.5833, 'lon': 111.9},
    'Madiun': {'lat': -7.6333, 'lon': 111.5333},
    'Magetan': {'lat': -7.6333, 'lon': 111.3667},
    'Ngawi': {'lat': -7.4, 'lon': 111.4667},
    'Bojonegoro': {'lat': -7.1333, 'lon': 111.8833},
    'Tuban': {'lat': -6.9, 'lon': 112.0667},
    'Lamongan': {'lat': -6.9833, 'lon': 112.4167},
    'Pasuruan': {'lat': -7.6333, 'lon': 112.9},
    'Probolinggo': {'lat': -7.7667, 'lon': 113.2167},
    'Lumajang': {'lat': -8.0667, 'lon': 113.2333},
    'Jember': {'lat': -8.1667, 'lon': 113.7},
    'Banyuwangi': {'lat': -8.2167, 'lon': 114.3667},
    'Bondowoso': {'lat': -7.9167, 'lon': 113.8167},
    'Situbondo': {'lat': -7.7167, 'lon': 114.1167},
    'Pamekasan': {'lat': -7.1833, 'lon': 113.4833},
    'Sumenep': {'lat': -6.8667, 'lon': 114.7167},
    'Sampang': {'lat': -7.1167, 'lon': 113.2167},
    'Bangkalan': {'lat': -7.0333, 'lon': 112.7333},
    'Serang': {'lat': -6.4, 'lon': 106.15},
    'Pandeglang': {'lat': -6.3167, 'lon': 105.3},
    'Lebak': {'lat': -6.8667, 'lon': 105.95},
    'Cilegon': {'lat': -6.0167, 'lon': 106.2833},
    'Tasikmalaya': {'lat': -7.3333, 'lon': 108.2167},
    'Ciamis': {'lat': -7.3167, 'lon': 108.3667},
    'Banjar': {'lat': -7.3833, 'lon': 108.5333},
    'Garut': {'lat': -7.2167, 'lon': 107.8833},
    'Sukabumi': {'lat': -6.9167, 'lon': 106.9333},
    'Cianjur': {'lat': -6.8167, 'lon': 107.1333},
    'Purwakarta': {'lat': -6.5667, 'lon': 107.4333},
    'Subang': {'lat': -6.5667, 'lon': 107.8},
    'Indramayu': {'lat': -6.3167, 'lon': 108.3167},
    'Kuningan': {'lat': -6.9833, 'lon': 108.4833},
    'Majalengka': {'lat': -6.9, 'lon': 108.2167},
    'Sumedang': {'lat': -6.8667, 'lon': 107.8167},
    'Cirebon': {'lat': -6.7033, 'lon': 108.4689},
    
    // Sumatera
    'Medan': {'lat': 3.5952, 'lon': 98.6722},
    'Pematangsiantar': {'lat': 2.6333, 'lon': 99.0667},
    'Tebing Tinggi': {'lat': 3.3167, 'lon': 99.1667},
    'Binjai': {'lat': 3.6, 'lon': 98.4833},
    'Deli Serdang': {'lat': 3.2, 'lon': 99.5},
    'Langsa': {'lat': 4.4667, 'lon': 98.9667},
    'Lhokseumawe': {'lat': 5.1833, 'lon': 97.1667},
    'Banda Aceh': {'lat': 5.5667, 'lon': 95.3333},
    'Sabang': {'lat': 5.8833, 'lon': 95.3167},
    'Sigli': {'lat': 5.1333, 'lon': 96.1667},
    'Takengon': {'lat': 4.3167, 'lon': 96.8333},
    'Padang': {'lat': -0.9492, 'lon': 100.4172},
    'Bukittinggi': {'lat': -0.3167, 'lon': 100.3667},
    'Payakumbuh': {'lat': -0.2333, 'lon': 101.0167},
    'Pariaman': {'lat': -0.6333, 'lon': 100.1167},
    'Solok': {'lat': -0.7667, 'lon': 101.7667},
    'Sawahlunto': {'lat': -0.6833, 'lon': 100.7333},
    'Jambi': {'lat': -1.6, 'lon': 103.6},
    'Sungai Penuh': {'lat': -1.9333, 'lon': 101.4333},
    'Palembang': {'lat': -2.9667, 'lon': 104.7458},
    'Prabumulih': {'lat': -3.4333, 'lon': 104.7333},
    'Lubuklinggau': {'lat': -3.3, 'lon': 102.8167},
    'Lahat': {'lat': -3.7833, 'lon': 103.7667},
    'Bengkulu': {'lat': -3.8, 'lon': 102.2667},
    'Curup': {'lat': -3.5, 'lon': 102.5167},
    'Lampung': {'lat': -5.4164, 'lon': 105.2648},
    'Bandar Lampung': {'lat': -5.4164, 'lon': 105.2648},
    'Metro': {'lat': -5.1167, 'lon': 104.7667},
    'Kota Agung': {'lat': -5.2333, 'lon': 104.7333},
    
    // Kalimantan
    'Pontianak': {'lat': -0.0333, 'lon': 109.3333},
    'Singkawang': {'lat': 0.9, 'lon': 109.8},
    'Sambas': {'lat': 1.2667, 'lon': 109.8},
    'Sanggau': {'lat': 0.1333, 'lon': 110.5},
    'Ketapang': {'lat': -1.3, 'lon': 110.2},
    'Kuching': {'lat': 1.5533, 'lon': 110.3592},
    'Banjarmasin': {'lat': -3.3167, 'lon': 114.5833},
    'Banjarbaru': {'lat': -3.4667, 'lon': 114.8},
    'Martapura': {'lat': -3.4167, 'lon': 114.8333},
    'Kandangan': {'lat': -3.3333, 'lon': 114.3333},
    'Palangkaraya': {'lat': -1.9667, 'lon': 113.9167},
    'Sampit': {'lat': -2.5333, 'lon': 112.7667},
    'Pangkalan Bun': {'lat': -2.6833, 'lon': 111.9167},
    'Kumai': {'lat': -2.7, 'lon': 111.8167},
    'Samarinda': {'lat': -0.5, 'lon': 117.1667},
    'Balikpapan': {'lat': -1.2667, 'lon': 116.8333},
    'Bontang': {'lat': 0.1333, 'lon': 117.5},
    'Tarakan': {'lat': 3.3, 'lon': 117.6333},
    'Tanjung Selor': {'lat': 2.7167, 'lon': 117.3667},
    'Berau': {'lat': 2.1667, 'lon': 117.5},
    
    // Sulawesi
    'Manado': {'lat': 1.4934, 'lon': 124.8228},
    'Bitung': {'lat': 1.4333, 'lon': 125.1833},
    'Tomohon': {'lat': 1.3167, 'lon': 124.8},
    'Kotamobagu': {'lat': 0.7167, 'lon': 124.4},
    'Gorontalo': {'lat': 0.5333, 'lon': 123.0667},
    'Palu': {'lat': -0.9, 'lon': 119.8667},
    'Donggala': {'lat': -0.6333, 'lon': 119.8},
    'Manado': {'lat': 1.4934, 'lon': 124.8228},
    'Kendari': {'lat': -3.9667, 'lon': 122.6167},
    'Bau-Bau': {'lat': -5.4333, 'lon': 122.6167},
    'Kolaka': {'lat': -4.1667, 'lon': 121.6667},
    'Makassar': {'lat': -5.1477, 'lon': 119.4327},
    'Parepare': {'lat': -4.0167, 'lon': 119.6167},
    'Palopo': {'lat': -3.0167, 'lon': 120.2},
    'Watampone': {'lat': -4.2833, 'lon': 120.3333},
    'Sinjai': {'lat': -5.1167, 'lon': 120.2},
    'Bulukumba': {'lat': -5.5333, 'lon': 120.8333},
    'Bantaeng': {'lat': -5.3, 'lon': 120.2333},
    'Takalar': {'lat': -5.3167, 'lon': 119.3667},
    'Gowa': {'lat': -5.3667, 'lon': 119.6333},
    'Sungguminasa': {'lat': -5.4167, 'lon': 119.6667},
    'Maros': {'lat': -5.0167, 'lon': 119.6},
    'Pangkajene': {'lat': -4.7167, 'lon': 119.5},
    'Barru': {'lat': -4.5333, 'lon': 119.2667},
    'Sengkang': {'lat': -3.7, 'lon': 120.2667},
    'Sidenreng': {'lat': -3.6667, 'lon': 120.1667},
    'Enrekang': {'lat': -3.3667, 'lon': 119.8333},
    'Pinrang': {'lat': -3.55, 'lon': 119.4167},
    'Rappang': {'lat': -3.0167, 'lon': 119.5167},
    'Luwu': {'lat': -2.4167, 'lon': 120.1667},
    'Belopa': {'lat': -2.4333, 'lon': 120.2333},
    'Tana Toraja': {'lat': -2.9667, 'lon': 119.7333},
    'Rantepao': {'lat': -2.9667, 'lon': 119.7333},
    
    // Nusa Tenggara
    'Mataram': {'lat': -8.5833, 'lon': 116.1333},
    'Sumbawa Barat': {'lat': -8.6667, 'lon': 116.4167},
    'Sumbawa': {'lat': -8.5, 'lon': 117.4167},
    'Kupang': {'lat': -10.1667, 'lon': 123.5833},
    'Kefamenanu': {'lat': -9.1333, 'lon': 124.3},
    'Atambua': {'lat': -9.1, 'lon': 124.8833},
    'Dili': {'lat': -8.5667, 'lon': 125.5667},
    'Denpasar': {'lat': -8.6705, 'lon': 115.2126},
    'Ubud': {'lat': -8.5069, 'lon': 115.2625},
    'Kuta': {'lat': -8.7245, 'lon': 115.1689},
    'Sanur': {'lat': -8.6833, 'lon': 115.2667},
    'Gianyar': {'lat': -8.5, 'lon': 115.3333},
    'Klungkung': {'lat': -8.5333, 'lon': 115.4},
    'Bangli': {'lat': -8.2667, 'lon': 115.3833},
    'Kintamani': {'lat': -8.4167, 'lon': 115.3833},
    'Tabanan': {'lat': -8.5333, 'lon': 115.1167},
    'Jatiluwih': {'lat': -8.3333, 'lon': 115.1667},
    'Negara': {'lat': -8.3833, 'lon': 114.6333},
    'Gilimanuk': {'lat': -8.1667, 'lon': 114.4},
    'Singaraja': {'lat': -8.1167, 'lon': 115.0833},
    'Lovina': {'lat': -8.1333, 'lon': 115.2333},
    'Amlapura': {'lat': -8.2667, 'lon': 115.5667},
    'Candidasa': {'lat': -8.5, 'lon': 115.5333},
    
    // Maluku
    'Ambon': {'lat': -3.6833, 'lon': 128.1833},
    'Tual': {'lat': -5.3667, 'lon': 132.7333},
    'Manado Utara': {'lat': 1.5, 'lon': 124.8333},
    'Ternate': {'lat': 0.7667, 'lon': 127.3833},
    'Tidore': {'lat': 0.6667, 'lon': 127.4167},
    'Sofifi': {'lat': 0.7167, 'lon': 127.7667},
    
    // Papua
    'Jayapura': {'lat': -2.5333, 'lon': 140.7167},
    'Wamena': {'lat': -4.0833, 'lon': 138.9667},
    'Manokwari': {'lat': -0.8667, 'lon': 134.0833},
    'Sorong': {'lat': -0.8833, 'lon': 131.2667},
    'Merauke': {'lat': -8.4833, 'lon': 140.3667},
  };

  Future<void> runPerformanceTest() async {
    isLoading.value = true;
    httpResults.clear();
    dioResults.clear();

    try {
      final coords = cityCoordinates[selectedCity.value]!;
      final lat = coords['lat'] as double;
      final lon = coords['lon'] as double;

      print('[PerformanceController] Starting test for ${selectedCity.value}');
      print('[PerformanceController] Iterations: ${iterations.value}');

      // Run HTTP tests
      print('[PerformanceController] Running HTTP tests...');
      final httpTestResults = await httpService.runMultipleTests(
        iterations: iterations.value,
        latitude: lat,
        longitude: lon,
      );
      httpResults.addAll(httpTestResults);

      // Delay antar library test
      await Future.delayed(const Duration(seconds: 1));

      // Run Dio tests
      print('[PerformanceController] Running Dio tests...');
      final dioTestResults = await dioService.runMultipleTests(
        iterations: iterations.value,
        latitude: lat,
        longitude: lon,
      );
      dioResults.addAll(dioTestResults);

      print('[PerformanceController] Tests completed');
    } catch (e) {
      print('[PerformanceController] Error: $e');
      Get.snackbar('Error', 'Gagal menjalankan test: $e');
    } finally {
      isLoading.value = false;
    }
  }

  PerformanceStats getHttpStats() {
    return PerformanceStats(results: httpResults);
  }

  PerformanceStats getDioStats() {
    return PerformanceStats(results: dioResults);
  }

  String getWinner() {
    if (httpResults.isEmpty || dioResults.isEmpty) return 'N/A';

    final httpAvg = getHttpStats().averageResponseTime;
    final dioAvg = getDioStats().averageResponseTime;

    if (httpAvg < dioAvg) {
      return 'HTTP (${(dioAvg - httpAvg).toStringAsFixed(2)}ms lebih cepat)';
    } else if (dioAvg < httpAvg) {
      return 'Dio (${(httpAvg - dioAvg).toStringAsFixed(2)}ms lebih cepat)';
    } else {
      return 'Sama cepat';
    }
  }
}
