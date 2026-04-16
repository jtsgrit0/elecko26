import 'dart:io';
import 'package:elecko26/domain/entities/member.dart';
import 'package:elecko26/domain/repositories/member_repository.dart';
import 'package:elecko26/domain/usecases/nesdc_pdf_extractor.dart';
import 'package:elecko26/app/injection_container.dart';

/// 2018년도 PDF 데이터를 파싱해서 현재 정당 지지율에 반영하는 UseCase
class Update2018PartySupportFromPdfUseCase {
  final MemberRepository repository;

  Update2018PartySupportFromPdfUseCase({required this.repository});

  /// PDF 파일에서 2018년도 정당 지지율 데이터를 추출하여 회원 데이터에 반영
  Future<void> executeFromFile(String pdfFilePath) async {
    try {
      final file = File(pdfFilePath);
      if (!file.existsSync()) {
        throw Exception('PDF 파일을 찾을 수 없습니다: $pdfFilePath');
      }

      final pdfText = await file.readAsString();
      await executeFromText(pdfText);
    } catch (e) {
      print('PDF 파일 처리 중 오류: $e');
      rethrow;
    }
  }

  /// PDF 텍스트에서 2018년도 정당 지지율 데이터를 추출하여 회원 데이터에 반영
  Future<void> executeFromText(String pdfText) async {
    try {
      // 1. PDF에서 정당별 지지율 추출
      final partySupportRates = NesdcPdfExtractor.extractByParty(pdfText);
      
      if (partySupportRates.isEmpty) {
        print('PDF에서 정당별 지지율 데이터를 찾을 수 없습니다.');
        return;
      }

      print('추출된 정당별 지지율: $partySupportRates');

      // 2. 모든 회원 조회
      final members = await repository.getAllMembers();
      
      if (members.isEmpty) {
        print('회원 데이터가 없습니다.');
        return;
      }

      // 3. 각 회원의 지역구별 정당 지지율 업데이트
      final updatedMembers = <Member>[];
      
      for (final member in members) {
        final district = member.district;
        
        // 해당 지역구의 정당별 지지율 찾기
        final districtPartyRates = <String, double>{};
        
        for (final entry in partySupportRates.entries) {
          final party = entry.key;
          final candidates = entry.value;
          
          // 해당 정당의 후보자 중에서 지역구 매칭
          for (final candidate in candidates) {
            if (candidate.contains(district) || district.contains(candidate)) {
              // 간단한 매칭 로직 - 실제로는 더 정교한 매칭 필요
              final supportRate = _extractSupportRateFromCandidate(candidate, pdfText);
              if (supportRate > 0) {
                districtPartyRates[party] = supportRate;
                break;
              }
            }
          }
        }

        if (districtPartyRates.isNotEmpty) {
          // 회원 데이터 업데이트
          final updatedMember = member.copyWith(
            historical2018PartyRates: districtPartyRates,
          );
          updatedMembers.add(updatedMember);
          
          print('${member.name} (${member.district})의 2018년 정당 지지율 업데이트: $districtPartyRates');
        }
      }

      // 4. 업데이트된 회원들 저장
      if (updatedMembers.isNotEmpty) {
        await repository.updateMembers(updatedMembers);
        print('총 ${updatedMembers.length}명의 회원 2018년 정당 지지율 업데이트 완료');
      }
    } catch (e) {
      print('2018년도 PDF 데이터 처리 중 오류: $e');
      rethrow;
    }
  }

  /// 후보자 정보에서 지지율 추출
  double _extractSupportRateFromCandidate(String candidateInfo, String pdfText) {
    // 간단한 지지율 추출 로직
    final ratePattern = RegExp(r'(\d+\.?\d*)%');
    final match = ratePattern.firstMatch(candidateInfo);
    
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    
    return 0.0;
  }

  /// 현재 날짜 기준으로 가장 최근의 2018년도 PDF 데이터 자동 업데이트
  Future<void> executeAutoUpdate() async {
    try {
      // 1. 데이터 디렉토리에서 2018년도 PDF 파일 찾기
      final dataDir = Directory('data/pdfs/2018');
      if (!dataDir.existsSync()) {
        print('2018년도 PDF 디렉토리가 없습니다: ${dataDir.path}');
        return;
      }

      final pdfFiles = dataDir
          .listSync()
          .where((file) => file.path.endsWith('.txt'))
          .toList();

      if (pdfFiles.isEmpty) {
        print('2018년도 PDF 파일을 찾을 수 없습니다.');
        return;
      }

      // 2. 가장 최근 파일 사용
      pdfFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestPdfFile = pdfFiles.first;

      print('최신 2018년도 PDF 파일 사용: ${latestPdfFile.path}');
      await executeFromFile(latestPdfFile.path);
    } catch (e) {
      print('자동 업데이트 중 오류: $e');
      rethrow;
    }
  }
}