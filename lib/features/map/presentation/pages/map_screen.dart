import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/features/map/domain/entities/election_map.dart';
import 'package:flutter_application_1/features/map/domain/usecases/get_election_map_data_usecase.dart';
import 'package:flutter_application_1/app/injection_container.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final GetElectionMapDataUseCase _useCase;
  ElectionMapData? _mapData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _useCase = sl<GetElectionMapDataUseCase>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _useCase();
      if (mounted) {
        setState(() {
          _mapData = data;
          _isLoading = false;
          print('✅ 지도 데이터 로드 성공: ${data.regions.length}개 지역');
        });
      }
    } catch (e, stackTrace) {
      print('❌ 에러 발생: $e');
      print('스택트레이스: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = '데이터 로드 실패: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _getPartyColor(String party) {
    switch (party) {
      case '더불어민주당':
        return Colors.blue;
      case '국민의힘':
        return Colors.red;
      case '정의당':
        return Colors.orange;
      case '기본소득당':
        return Colors.green;
      case '진보당':
        return Colors.purple;
      case '무소속':
        return Colors.grey;
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
        title: const Text('예상 득표율 지도'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('지도 데이터 로드 중...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadData();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_mapData == null) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(36.5, 127.5), // 대한민국 중심
        initialZoom: 7.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers: [
            // 다른 지역 마커들 (서울 제외)
            ..._mapData!.regions.where((region) => region.region != '서울특별시').map((region) {
              final center = _getRegionCenter(region.region);
              return Marker(
                point: center,
                width: 120,
                height: 80,
                child: GestureDetector(
                  onTap: () => _showRegionInfo(region),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPartyColor(region.dominantParty).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              region.region,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                            Text(
                              region.dominantParty,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            // 서울특별시 마커 (제일 앞으로 표시)
            ..._mapData!.regions.where((region) => region.region == '서울특별시').map((region) {
              final center = _getRegionCenter(region.region);
              return Marker(
                point: center,
                width: 120,
                height: 80,
                child: GestureDetector(
                  onTap: () => _showRegionInfo(region),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPartyColor(region.dominantParty).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.yellow, width: 2), // 서울 강조
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              region.region,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                            Text(
                              region.dominantParty,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  void _showRegionInfo(RegionalPartyData region) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(region.region),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                '우세 정당: ${region.dominantParty}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '예상 득표율: ${region.dominantPercentage.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                '정당별 예상 득표율:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...region.partyPercentages.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${entry.key}: ${entry.value.toStringAsFixed(2)}%'),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
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