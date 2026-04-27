import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:elecko26_new/features/map/domain/entities/election_map.dart';
import 'package:elecko26_new/features/map/domain/usecases/get_election_map_data_usecase.dart';
import 'package:elecko26_new/app/injection_container.dart';

import 'package:flutter/foundation.dart';

class MapScreen extends StatefulWidget {
  final ValueListenable<int> selectedIndexNotifier;
  final int tabIndex;

  const MapScreen({
    Key? key,
    required this.selectedIndexNotifier,
    required this.tabIndex,
  }) : super(key: key);

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
        });
      }
    } catch (e) {
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
      case '더불어민주당': return Colors.blue;
      case '국민의힘': return Colors.red;
      case '정의당': return Colors.orange;
      case '기본소득당': return Colors.green;
      case '진보당': return Colors.purple;
      case '무소속': return Colors.grey;
      case '민주당': return Colors.blue;
      case '한나라당': return Colors.red;
      case '자유선진당': return Colors.orange;
      case '국민참여당': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.selectedIndexNotifier,
      builder: (context, currentIndex, _) {
        final bool isActive = currentIndex == widget.tabIndex;
        
        return Visibility(
          visible: isActive,
          maintainState: true,
          child: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return RepaintBoundary(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.2, 127.8),
          initialZoom: 7.2,
          minZoom: 6.8,
          maxZoom: 11.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          cameraConstraint: CameraConstraint.contain(
            bounds: LatLngBounds(
              const LatLng(32.5, 123.5),
              const LatLng(39.0, 132.5),
            ),
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.elecko26.app',
            tileDisplay: const TileDisplay.instant(),
          ),
          MarkerLayer(
            rotate: false,
            markers: [
              ..._mapData!.regions
                  .where((region) => region.region != '서울특별시')
                  .map((region) {
                final center = _getRegionCenter(region.region);
                return Marker(
                  point: center,
                  width: 100,
                  height: 60,
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => _showRegionInfo(region),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPartyColor(region.dominantParty)
                                  .withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                                Text(
                                  '${region.dominantPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              ..._mapData!.regions
                  .where((region) => region.region == '서울특별시')
                  .map((region) {
                final center = _getRegionCenter(region.region);
                return Marker(
                  point: center,
                  width: 110,
                  height: 70,
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => _showRegionInfo(region),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPartyColor(region.dominantParty)
                                  .withOpacity(0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.yellowAccent, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
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
                                  '${region.dominantPercentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  void _showRegionInfo(RegionalPartyData region) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 50),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        region.region,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow('우세 정당', region.dominantParty,
                      _getPartyColor(region.dominantParty)),
                  _buildInfoRow('예상 득표율',
                      '${region.dominantPercentage.toStringAsFixed(1)}%',
                      Colors.black87),
                  const SizedBox(height: 16),
                  const Text(
                    '정당별 예상 데이터',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...region.partyPercentages.entries.take(5).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: const TextStyle(fontSize: 13)),
                          Text('${entry.value.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
