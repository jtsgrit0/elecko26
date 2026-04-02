import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/features/map/domain/entities/election_map.dart';
import 'package:flutter_application_1/features/map/domain/usecases/get_election_map_data_usecase.dart';
import 'package:flutter_application_1/features/map/data/repositories/map_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final GetElectionMapDataUseCase _useCase;
  ElectionMapData? _mapData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _useCase = GetElectionMapDataUseCase(MapRepositoryImpl());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _useCase();
      setState(() {
        _mapData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 로드 실패: $e')),
      );
    }
  }

  Color _getPartyColor(String party) {
    switch (party) {
      case '민주당':
        return Colors.blue;
      case '한나라당':
        return Colors.red;
      case '자유선진당':
        return Colors.orange;
      case '국민참여당':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대한민국 선거 지도'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(36.5, 127.5), // 대한민국 중심
                initialZoom: 7.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_mapData != null)
                  MarkerLayer(
                    markers: _mapData!.regions.map((region) {
                      // 간단하게 지역별 마커 표시 (실제로는 폴리곤이 좋음)
                      final center = _getRegionCenter(region.region);
                      return Marker(
                        point: center,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getPartyColor(region.dominantParty).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${region.region}\n${region.dominantParty}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
    );
  }

  // 지역별 중심 좌표 (간단한 매핑)
  LatLng _getRegionCenter(String region) {
    const centers = {
      '서울특별시': LatLng(37.5665, 126.9780),
      '부산광역시': LatLng(35.1796, 129.0756),
      '대구광역시': LatLng(35.8714, 128.6014),
      '인천광역시': LatLng(37.4563, 126.7052),
      '광주광역시': LatLng(35.1595, 126.8526),
      '대전광역시': LatLng(36.3504, 127.3845),
      '울산광역시': LatLng(35.5384, 129.3114),
      '세종특별자치시': LatLng(36.4800, 127.2890),
      '경기도': LatLng(37.4138, 127.5183),
      '강원도': LatLng(37.8228, 128.1555),
      '충청북도': LatLng(36.6357, 127.4914),
      '충청남도': LatLng(36.5184, 126.8000),
      '전라북도': LatLng(35.7175, 127.1530),
      '전라남도': LatLng(34.8679, 126.9910),
      '경상북도': LatLng(36.4919, 128.8889),
      '경상남도': LatLng(35.4606, 128.2132),
      '제주특별자치도': LatLng(33.4996, 126.5312),
    };
    return centers[region] ?? const LatLng(36.5, 127.5);
  }
}