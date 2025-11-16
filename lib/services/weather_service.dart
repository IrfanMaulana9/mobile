import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherData> getWeatherByCoordinates({
    required double latitude,
    required double longitude,
    String location = 'Jakarta',
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m',
        'timezone': 'Asia/Jakarta',
      };

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      
      print('[v0] Calling Open-Meteo API: $uri');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('API request timeout'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final current = json['current'];

        print('[v0] API Response: $current');

        return WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          weatherCode: current['weather_code'].toString(),
          humidity: (current['relative_humidity_2m'] as num).toDouble(),
          windSpeed: (current['wind_speed_10m'] as num).toDouble(),
          location: location,
          timestamp: DateTime.now(),
        );
      } else {
        throw Exception('Failed to load weather: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching weather: $e');
      rethrow;
    }
  }

  Future<WeatherData> getWeatherByCity(String city) async {
    final coordinates = {
      // Jawa
      'Jakarta': (-6.2088, 106.8456),
      'Surabaya': (-7.2504, 112.7688),
      'Bandung': (-6.9175, 107.6062),
      'Medan': (3.5952, 98.6722),
      'Yogyakarta': (-7.7956, 110.3695),
      'Semarang': (-6.9667, 110.4167),
      'Bogor': (-6.5971, 106.8060),
      'Bekasi': (-6.2349, 107.0055),
      'Depok': (-6.4025, 106.7942),
      'Tangerang': (-6.1783, 106.6326),
      'Cirebon': (-6.7033, 108.4689),
      'Pekalongan': (-6.8889, 109.6833),
      'Tegal': (-6.8667, 109.1333),
      'Purwokerto': (-7.4167, 109.2333),
      'Magelang': (-7.4833, 110.2167),
      'Wonosobo': (-7.7167, 107.5667),
      'Cilacap': (-7.7333, 109.0167),
      'Kudus': (-6.9167, 110.8333),
      'Jepara': (-6.8667, 110.6667),
      'Pati': (-6.7667, 111.1167),
      'Rembang': (-6.7167, 111.4333),
      'Blora': (-6.9667, 111.4),
      'Gresik': (-7.1667, 112.6667),
      'Sidoarjo': (-7.4333, 112.7167),
      'Mojokerto': (-7.4667, 112.8167),
      'Jombang': (-7.5333, 112.2333),
      'Nganjuk': (-7.5833, 111.9),
      'Madiun': (-7.6333, 111.5333),
      'Magetan': (-7.6333, 111.3667),
      'Ngawi': (-7.4, 111.4667),
      'Bojonegoro': (-7.1333, 111.8833),
      'Tuban': (-6.9, 112.0667),
      'Lamongan': (-6.9833, 112.4167),
      'Pasuruan': (-7.6333, 112.9),
      'Probolinggo': (-7.7667, 113.2167),
      'Lumajang': (-8.0667, 113.2333),
      'Jember': (-8.1667, 113.7),
      'Banyuwangi': (-8.2167, 114.3667),
      'Bondowoso': (-7.9167, 113.8167),
      'Situbondo': (-7.7167, 114.1167),
      'Pamekasan': (-7.1833, 113.4833),
      'Sumenep': (-6.8667, 114.7167),
      'Sampang': (-7.1167, 113.2167),
      'Bangkalan': (-7.0333, 112.7333),
      'Serang': (-6.4, 106.15),
      'Pandeglang': (-6.3167, 105.3),
      'Lebak': (-6.8667, 105.95),
      'Cilegon': (-6.0167, 106.2833),
      'Tasikmalaya': (-7.3333, 108.2167),
      'Ciamis': (-7.3167, 108.3667),
      'Banjar': (-7.3833, 108.5333),
      'Garut': (-7.2167, 107.8833),
      'Sukabumi': (-6.9167, 106.9333),
      'Cianjur': (-6.8167, 107.1333),
      'Purwakarta': (-6.5667, 107.4333),
      'Subang': (-6.5667, 107.8),
      'Indramayu': (-6.3167, 108.3167),
      'Kuningan': (-6.9833, 108.4833),
      'Majalengka': (-6.9, 108.2167),
      'Sumedang': (-6.8667, 107.8167),
      
      // Sumatera
      'Pematangsiantar': (2.6333, 99.0667),
      'Tebing Tinggi': (3.3167, 99.1667),
      'Binjai': (3.6, 98.4833),
      'Deli Serdang': (3.2, 99.5),
      'Langsa': (4.4667, 98.9667),
      'Lhokseumawe': (5.1833, 97.1667),
      'Banda Aceh': (5.5667, 95.3333),
      'Sabang': (5.8833, 95.3167),
      'Sigli': (5.1333, 96.1667),
      'Takengon': (4.3167, 96.8333),
      'Padang': (-0.9492, 100.4172),
      'Bukittinggi': (-0.3167, 100.3667),
      'Payakumbuh': (-0.2333, 101.0167),
      'Pariaman': (-0.6333, 100.1167),
      'Solok': (-0.7667, 101.7667),
      'Sawahlunto': (-0.6833, 100.7333),
      'Jambi': (-1.6, 103.6),
      'Sungai Penuh': (-1.9333, 101.4333),
      'Palembang': (-2.9667, 104.7458),
      'Prabumulih': (-3.4333, 104.7333),
      'Lubuklinggau': (-3.3, 102.8167),
      'Lahat': (-3.7833, 103.7667),
      'Bengkulu': (-3.8, 102.2667),
      'Curup': (-3.5, 102.5167),
      'Bandar Lampung': (-5.4164, 105.2648),
      'Metro': (-5.1167, 104.7667),
      'Kota Agung': (-5.2333, 104.7333),
      
      // Kalimantan
      'Pontianak': (-0.0333, 109.3333),
      'Singkawang': (0.9, 109.8),
      'Sambas': (1.2667, 109.8),
      'Sanggau': (0.1333, 110.5),
      'Ketapang': (-1.3, 110.2),
      'Kuching': (1.5533, 110.3592),
      'Banjarmasin': (-3.3167, 114.5833),
      'Banjarbaru': (-3.4667, 114.8),
      'Martapura': (-3.4167, 114.8333),
      'Kandangan': (-3.3333, 114.3333),
      'Palangkaraya': (-1.9667, 113.9167),
      'Sampit': (-2.5333, 112.7667),
      'Pangkalan Bun': (-2.6833, 111.9167),
      'Kumai': (-2.7, 111.8167),
      'Samarinda': (-0.5, 117.1667),
      'Balikpapan': (-1.2667, 116.8333),
      'Bontang': (0.1333, 117.5),
      'Tarakan': (3.3, 117.6333),
      'Tanjung Selor': (2.7167, 117.3667),
      'Berau': (2.1667, 117.5),
      
      // Sulawesi
      'Manado': (1.4934, 124.8228),
      'Bitung': (1.4333, 125.1833),
      'Tomohon': (1.3167, 124.8),
      'Kotamobagu': (0.7167, 124.4),
      'Gorontalo': (0.5333, 123.0667),
      'Palu': (-0.9, 119.8667),
      'Donggala': (-0.6333, 119.8),
      'Kendari': (-3.9667, 122.6167),
      'Bau-Bau': (-5.4333, 122.6167),
      'Kolaka': (-4.1667, 121.6667),
      'Makassar': (-5.1477, 119.4327),
      'Parepare': (-4.0167, 119.6167),
      'Palopo': (-3.0167, 120.2),
      'Watampone': (-4.2833, 120.3333),
      'Sinjai': (-5.1167, 120.2),
      'Bulukumba': (-5.5333, 120.8333),
      'Bantaeng': (-5.3, 120.2333),
      'Takalar': (-5.3167, 119.3667),
      'Gowa': (-5.3667, 119.6333),
      'Sungguminasa': (-5.4167, 119.6667),
      'Maros': (-5.0167, 119.6),
      'Pangkajene': (-4.7167, 119.5),
      'Barru': (-4.5333, 119.2667),
      'Sengkang': (-3.7, 120.2667),
      'Sidenreng': (-3.6667, 120.1667),
      'Enrekang': (-3.3667, 119.8333),
      'Pinrang': (-3.55, 119.4167),
      'Rappang': (-3.0167, 119.5167),
      'Luwu': (-2.4167, 120.1667),
      'Belopa': (-2.4333, 120.2333),
      'Tana Toraja': (-2.9667, 119.7333),
      'Rantepao': (-2.9667, 119.7333),
      
      // Nusa Tenggara
      'Mataram': (-8.5833, 116.1333),
      'Sumbawa Barat': (-8.6667, 116.4167),
      'Sumbawa': (-8.5, 117.4167),
      'Kupang': (-10.1667, 123.5833),
      'Kefamenanu': (-9.1333, 124.3),
      'Atambua': (-9.1, 124.8833),
      'Dili': (-8.5667, 125.5667),
      'Denpasar': (-8.6705, 115.2126),
      'Ubud': (-8.5069, 115.2625),
      'Kuta': (-8.7245, 115.1689),
      'Sanur': (-8.6833, 115.2667),
      'Gianyar': (-8.5, 115.3333),
      'Klungkung': (-8.5333, 115.4),
      'Bangli': (-8.2667, 115.3833),
      'Kintamani': (-8.4167, 115.3833),
      'Tabanan': (-8.5333, 115.1167),
      'Jatiluwih': (-8.3333, 115.1667),
      'Negara': (-8.3833, 114.6333),
      'Gilimanuk': (-8.1667, 114.4),
      'Singaraja': (-8.1167, 115.0833),
      'Lovina': (-8.1333, 115.2333),
      'Amlapura': (-8.2667, 115.5667),
      'Candidasa': (-8.5, 115.5333),
      
      // Maluku
      'Ambon': (-3.6833, 128.1833),
      'Tual': (-5.3667, 132.7333),
      'Ternate': (0.7667, 127.3833),
      'Tidore': (0.6667, 127.4167),
      'Sofifi': (0.7167, 127.7667),
      
      // Papua
      'Jayapura': (-2.5333, 140.7167),
      'Wamena': (-4.0833, 138.9667),
      'Manokwari': (-0.8667, 134.0833),
      'Sorong': (-0.8833, 131.2667),
      'Merauke': (-8.4833, 140.3667),
    };

    final coord = coordinates[city] ?? coordinates['Jakarta']!;
    return getWeatherByCoordinates(
      latitude: coord.$1,
      longitude: coord.$2,
      location: city,
    );
  }
}
