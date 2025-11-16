import 'package:get/get.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherController extends GetxController {
  final weatherService = WeatherService();
  
  final Rx<WeatherData?> weatherData = Rx<WeatherData?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString selectedCity = 'Jakarta'.obs;

  final cities = [
    // Jawa
    'Jakarta', 'Surabaya', 'Bandung', 'Semarang', 'Yogyakarta', 'Malang', 'Bogor', 'Depok', 'Bekasi', 'Tangerang',
    'Cirebon', 'Pekalongan', 'Kudus', 'Jepara', 'Rembang', 'Blora', 'Grobogan', 'Purwodadi', 'Salatiga', 'Sukoharjo',
    'Karanganyar', 'Sragen', 'Wonogiri', 'Klaten', 'Boyolali', 'Magelang', 'Wonosobo', 'Purworejo', 'Kebumen', 'Cilacap',
    'Banyumas', 'Purwokerto', 'Tegal', 'Brebes', 'Pemalang', 'Batang', 'Kendal', 'Demak', 'Gresik', 'Sidoarjo',
    'Pasuruan', 'Probolinggo', 'Lumajang', 'Jember', 'Banyuwangi', 'Bondowoso', 'Situbondo', 'Tuban', 'Lamongan', 'Ngawi',
    'Magetan', 'Madiun', 'Ponorogo', 'Pacitan', 'Trenggalek', 'Tulungagung', 'Blitar', 'Kediri', 'Nganjuk', 'Mojokerto',
    
    // Sumatera
    'Medan', 'Palembang', 'Pekanbaru', 'Jambi', 'Bandar Lampung', 'Banda Aceh', 'Padang', 'Bengkulu', 'Dumai', 'Batam',
    'Tanjung Pinang', 'Binjai', 'Deli Serdang', 'Langsa', 'Lhokseumawe', 'Sibolga', 'Pematangsiantar', 'Tebing Tinggi',
    'Asahan', 'Labuhan Batu', 'Mandailing Natal', 'Tapanuli Selatan', 'Tapanuli Tengah', 'Tapanuli Utara', 'Nias',
    'Pesisir Selatan', 'Solok', 'Sawahlunto', 'Bukittinggi', 'Payakumbuh', 'Pariaman', 'Agam', 'Lima Puluh Kota',
    'Pasaman', 'Pasaman Barat', 'Kerinci', 'Merangin', 'Sarolangun', 'Batanghari', 'Muaro Jambi', 'Tanjung Jabung Timur',
    'Tanjung Jabung Barat', 'Tebo', 'Bungo', 'Mukomuko', 'Seluma', 'Kaur', 'Rejang Lebong', 'Lebak', 'Tanggamus',
    'Lampung Selatan', 'Lampung Timur', 'Lampung Utara', 'Way Kanan', 'Tulang Bawang', 'Pesawaran', 'Pringsewu',
    
    // Kalimantan
    'Banjarmasin', 'Samarinda', 'Pontianak', 'Palangkaraya', 'Tarakan', 'Balikpapan', 'Bontang', 'Singkawang',
    'Sambas', 'Bengkayang', 'Landak', 'Mempawah', 'Kubu Raya', 'Sanggau', 'Sekadau', 'Sintang', 'Kapuas Hulu',
    'Melawi', 'Kayong Utara', 'Ketapang', 'Kubu Raya', 'Paser', 'Kutai Kartanegara', 'Kutai Barat', 'Berau',
    'Penajam Paser Utara', 'Mahakam Ulu', 'Barito Utara', 'Barito Timur', 'Barito Selatan', 'Kapuas', 'Katingan',
    'Seruyan', 'Sukamara', 'Lamandau', 'Gunung Mas', 'Pulang Pisau', 'Murung Raya', 'Banjar', 'Barito Kuala',
    'Tabalong', 'Tanah Bumbu', 'Tanah Laut', 'Hulu Sungai Selatan', 'Hulu Sungai Tengah', 'Hulu Sungai Utara',
    'Tapin', 'Balangan', 'Kabupaten Banjar',
    
    // Sulawesi
    'Makassar', 'Manado', 'Palu', 'Kendari', 'Gorontalo', 'Tomohon', 'Bitung', 'Kotamobagu', 'Tondano',
    'Minahasa', 'Minahasa Utara', 'Minahasa Selatan', 'Minahasa Tenggara', 'Bolaang Mongondow', 'Bolaang Mongondow Utara',
    'Bolaang Mongondow Timur', 'Bolaang Mongondow Selatan', 'Talaud', 'Sangihe', 'Kepulauan Siau Tagulandang Biaro',
    'Donggala', 'Sigi', 'Parigi Moutong', 'Toli-Toli', 'Buol', 'Morowali', 'Morowali Utara', 'Banggai',
    'Banggai Kepulauan', 'Banggai Laut', 'Poso', 'Tojo Una-Una', 'Kolaka', 'Kolaka Utara', 'Kolaka Timur',
    'Konawe', 'Konawe Selatan', 'Konawe Utara', 'Muna', 'Muna Barat', 'Buton', 'Buton Utara', 'Buton Tengah',
    'Buton Selatan', 'Wakatobi', 'Bombana', 'Luwu', 'Luwu Utara', 'Luwu Timur', 'Tana Toraja', 'Toraja Utara',
    'Sidenreng Rappang', 'Enrekang', 'Sinjai', 'Bulukumba', 'Bantaeng', 'Jeneponto', 'Takalar', 'Gowa',
    'Maros', 'Pangkajene Kepulauan', 'Barru', 'Bone', 'Soppeng', 'Wajo', 'Sidrap', 'Pinrang', 'Polewali Mandar',
    'Mamasa', 'Mamuju', 'Mamuju Utara', 'Mamuju Tengah', 'Sulbar',
    
    // Nusa Tenggara
    'Mataram', 'Kupang', 'Denpasar', 'Ubud', 'Singaraja', 'Gianyar', 'Klungkung', 'Bangli', 'Karangasem',
    'Badung', 'Tabanan', 'Jembrana', 'Buleleng', 'Lombok Utara', 'Lombok Tengah', 'Lombok Timur', 'Lombok Barat',
    'Sumbawa', 'Sumbawa Barat', 'Dompu', 'Bima', 'Kota Bima', 'Flores Timur', 'Ende', 'Ngada', 'Nagekeo',
    'Manggarai', 'Manggarai Barat', 'Manggarai Timur', 'Rote Ndao', 'Kupang', 'Timor Tengah Selatan', 'Timor Tengah Utara',
    'Belu', 'Alor', 'Lembata', 'Flores',
    
    // Maluku
    'Ambon', 'Ternate', 'Tidore', 'Manado Utara', 'Maluku Tengah', 'Maluku Tenggara', 'Maluku Tenggara Barat',
    'Buru', 'Buru Selatan', 'Seram Bagian Barat', 'Seram Bagian Timur', 'Kepulauan Aru', 'Halmahera Selatan',
    'Halmahera Tengah', 'Halmahera Utara', 'Halmahera Barat', 'Pulau Morotai', 'Pulau Taliabu', 'Obi',
    
    // Papua
    'Jayapura', 'Sorong', 'Manokwari', 'Timika', 'Merauke', 'Nabire', 'Wamena', 'Biak', 'Yapen Waropen',
    'Supiori', 'Biak Numfor', 'Waropen', 'Cenderawasih', 'Jayawijaya', 'Pegunungan Bintang', 'Yahukimo',
    'Tolikara', 'Sarmi', 'Keerom', 'Mappi', 'Asmat', 'Boven Digoel', 'Mappi', 'Mimika', 'Puncak Jaya',
    'Puncak', 'Dogiyai', 'Intan Jaya', 'Deiyai', 'Paniai', 'Mamberamo Raya', 'Mamberamo Tengah', 'Nduga',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchWeather('Jakarta');
  }

  Future<void> fetchWeather(String city) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      selectedCity.value = city;
      
      print('[v0] Fetching weather for: $city');
      
      final data = await weatherService.getWeatherByCity(city);
      weatherData.value = data;
      
      print('[v0] Weather data updated: ${data.location}');
    } catch (e) {
      errorMessage.value = 'Gagal memuat cuaca: $e';
      print('[v0] Error: $errorMessage.value');
    } finally {
      isLoading.value = false;
    }
  }
}
