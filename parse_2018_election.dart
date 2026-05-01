import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  // 2018년도 시도지사 선거 결과 파일 읽기
  final filePath =
      '/Users/jtsgrit0/Documents/flutter/elecko26/전국동시지방선거 개표결과(제7회)/20180619-7지선-01-(시도지사)_읍면동별개표자료.xlsx';

  try {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    print('=== 2018년도 지방선거 정당별 지지율 분석 ===\n');

    // 각 시트에서 데이터 추출
    for (final table in excel.tables.keys) {
      print('시트: $table');
      final sheet = excel.tables[table]!;

      // 첫 10행을 확인하여 구조 파악
      for (int i = 0; i < 10; i++) {
        final row = sheet.row(i);
        if (row.isNotEmpty) {
          print('행 $i: ${row.map((cell) => cell?.value ?? '').toList()}');
        }
      }
      print('---\n');
    }
  } catch (e) {
    print('파일 읽기 오류: $e');
  }
}
