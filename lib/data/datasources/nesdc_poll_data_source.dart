import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_application_1/core/platform/platform_info.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'nesdc_pdf_text_extractor_stub.dart'
    if (dart.library.ui) 'nesdc_pdf_text_extractor.dart';

import 'package:flutter_application_1/core/config/refresh_config.dart';

final Uri _nesdcOrigin = Uri.parse('https://www.nesdc.go.kr');

class NesdcPollEntry {
  final String registrationNo;
  final String agency;
  final String client;
  final String method;
  final String sampleFrame;
  final String pollName;
  final DateTime registeredDate;
  final String region;
  final String sourceUrl;
  final String? status;

  NesdcPollEntry({
    required this.registrationNo,
    required this.agency,
    required this.client,
    required this.method,
    required this.sampleFrame,
    required this.pollName,
    required this.registeredDate,
    required this.region,
    required this.sourceUrl,
    this.status,
  });
}

class NesdcPollDetail {
  final String detailUrl;
  final DateTime? surveyDate;
  final int? sampleSize;
  final double? marginOfError;
  final String? resultFileUrl;
  final String? detailText;
  final String? resultText;
  final Map<String, String> fields;

  NesdcPollDetail({
    required this.detailUrl,
    required this.surveyDate,
    required this.sampleSize,
    required this.marginOfError,
    required this.resultFileUrl,
    required this.detailText,
    required this.resultText,
    required this.fields,
  });

  factory NesdcPollDetail.fromJson(Map<String, dynamic> json, {required String detailUrl}) {
    DateTime? parseDate(String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final normalized = value.replaceAll('.', '-').replaceAll('/', '-');
      return DateTime.tryParse(normalized);
    }

    return NesdcPollDetail(
      detailUrl: detailUrl,
      surveyDate: parseDate(json['surveyDate'] as String?),
      sampleSize: (json['sampleSize'] as num?)?.toInt(),
      marginOfError: (json['marginOfError'] as num?)?.toDouble(),
      resultFileUrl: json['resultFileUrl'] as String?,
      detailText: json['detailText'] as String?,
      resultText: json['resultText'] as String?,
      fields: (json['fields'] as Map?)?.map(
            (key, value) => MapEntry('$key', '$value'),
          ) ??
          <String, String>{},
    );
  }

  double? findSupportRate(Iterable<String> names) {
    final source = resultText ?? detailText;
    if (source == null || source.isEmpty) {
      return null;
    }
    final uniqueNames = names
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final name in uniqueNames) {
      final value = _extractRate(source, name);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  double? _extractRate(String text, String name) {
    final normalizedName = _normalizeRateText(name);
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      final normalizedLine = _normalizeRateText(line);
      if (!normalizedLine.contains(normalizedName)) {
        continue;
      }

      final directMatch = RegExp('${RegExp.escape(normalizedName)}[:：]?([0-9]{1,2}(?:\\.[0-9]+)?)%')
          .firstMatch(normalizedLine);
      if (directMatch != null) {
        final value = double.tryParse(directMatch.group(1) ?? '');
        if (value != null) {
          return value / 100;
        }
      }

      final reverseMatch = RegExp('([0-9]{1,2}(?:\\.[0-9]+)?)%[^0-9]{0,6}${RegExp.escape(normalizedName)}')
          .firstMatch(normalizedLine);
      if (reverseMatch != null) {
        final value = double.tryParse(reverseMatch.group(1) ?? '');
        if (value != null) {
          return value / 100;
        }
      }

      final percentMatches =
          RegExp(r'([0-9]{1,2}(?:\.[0-9]+)?)%').allMatches(normalizedLine).toList();
      if (percentMatches.isNotEmpty) {
        final nameIndex = normalizedLine.indexOf(normalizedName);
        final best = percentMatches.reduce((a, b) {
          final aDist = (a.start - nameIndex).abs();
          final bDist = (b.start - nameIndex).abs();
          return aDist <= bDist ? a : b;
        });
        final value = double.tryParse(best.group(1) ?? '');
        if (value != null) {
          return value / 100;
        }
      }

      final hasRateKeyword =
          normalizedLine.contains('지지') || normalizedLine.contains('득표') || normalizedLine.contains('선호');
      if (hasRateKeyword) {
        final numberMatches = RegExp(r'([0-9]{1,2}(?:\.[0-9]+)?)').allMatches(normalizedLine);
        for (final match in numberMatches) {
          final value = double.tryParse(match.group(1) ?? '');
          if (value != null && value >= 0 && value <= 100) {
            return value / 100;
          }
        }
      }
    }

    final flat = _normalizeRateText(text.replaceAll('\n', ' '));
    final fallback = RegExp('${RegExp.escape(normalizedName)}[:：]?([0-9]{1,2}(?:\\.[0-9]+)?)%');
    final fallbackMatch = fallback.firstMatch(flat);
    if (fallbackMatch != null) {
      final value = double.tryParse(fallbackMatch.group(1) ?? '');
      if (value != null) {
        return value / 100;
      }
    }
    return null;
  }

  String _normalizeRateText(String text) {
    return text.replaceAll(RegExp(r'[\s·•\-\(\)\[\]{}<>]'), '');
  }
}

class NesdcPollDataSource {
  NesdcPollDataSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, NesdcPollDetail> _detailCache = {};

  Future<List<NesdcPollEntry>> fetchLatest({int pages = kNesdcPagesToFetch}) async {
    final webOverride = _resolveWebBackendOverride();
    if (webOverride != null) {
      final fromBackend = await _fetchLatestFromBackend(pages, baseOverride: webOverride);
      if (fromBackend.isNotEmpty) {
        return fromBackend;
      }
    }
    if (kNesdcBackendUrl.trim().isNotEmpty) {
      final fromBackend = await _fetchLatestFromBackend(pages);
      if (fromBackend.isNotEmpty) {
        return fromBackend;
      }
    }
    final entries = <NesdcPollEntry>[];

    for (var page = 1; page <= pages; page++) {
      final url = _buildListUri(page);
      final response = await _client.get(url, headers: _defaultHeaders());
      if (response.statusCode != 200) {
        continue;
      }

      final body = _decodeBody(response);
      entries.addAll(_parseListHtml(body));
    }

    return entries;
  }

  Future<List<NesdcPollEntry>> _fetchLatestFromBackend(int pages, {Uri? baseOverride}) async {
    final base = baseOverride ?? _resolveBackendBase();
    if (base.toString().trim().isEmpty) {
      return [];
    }
    final url = _buildBackendUrl(base, pages);

    final response = await _client.get(url, headers: const {
      'Accept': 'application/json',
    });
    if (response.statusCode != 200) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    final rawEntries = decoded is List ? decoded : (decoded is Map<String, dynamic> ? decoded['entries'] : null);
    if (rawEntries is! List) {
      return [];
    }

    final entries = <NesdcPollEntry>[];
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final registeredDate = DateTime.tryParse('${raw['registeredDate']}') ?? DateTime.now();
      final entry = NesdcPollEntry(
        registrationNo: '${raw['registrationNo'] ?? ''}',
        agency: '${raw['agency'] ?? ''}',
        client: '${raw['client'] ?? ''}',
        method: '${raw['method'] ?? ''}',
        sampleFrame: '${raw['sampleFrame'] ?? ''}',
        pollName: '${raw['pollName'] ?? ''}',
        registeredDate: registeredDate,
        region: '${raw['region'] ?? ''}',
        sourceUrl: '${raw['sourceUrl'] ?? ''}',
        status: raw['status'] == null ? null : '${raw['status']}',
      );
      entries.add(entry);

      final detailJson = raw['detail'];
      if (detailJson is Map<String, dynamic>) {
        _detailCache[entry.sourceUrl] = NesdcPollDetail.fromJson(
          detailJson,
          detailUrl: entry.sourceUrl,
        );
      }
    }

    return entries;
  }

  Future<NesdcPollDetail?> fetchDetail(String detailUrl) async {
    if (_detailCache.containsKey(detailUrl)) {
      return _detailCache[detailUrl];
    }

    final target = _toTargetUri(detailUrl);
    final response = await _client.get(_wrapProxy(target), headers: _defaultHeaders());
    if (response.statusCode != 200) {
      return null;
    }

    final body = _decodeBody(response);
    final document = html_parser.parse(body);

    final fields = _extractFields(document);
    final tableText = _extractTableText(document);
    final detailText = _mergeDetailText(document.body?.text, tableText);

    final surveyDate = _parseSurveyDate(fields, detailText);
    var sampleSize = _parseSampleSize(fields, detailText);
    var marginOfError = _parseMarginOfError(fields, detailText);

    final resultFileUrl = _findResultFileUrl(document);
    String? resultText;
    if (resultFileUrl != null) {
      final fileTarget = _toTargetUri(resultFileUrl);
      final fileResponse = await _client.get(_wrapProxy(fileTarget), headers: _defaultHeaders());
      if (fileResponse.statusCode == 200) {
        resultText = _tryExtractPdfText(fileResponse.bodyBytes);
        if (!kReleaseMode) {
          debugPrint('[NESDC] PDF extracted: url=$resultFileUrl bytes=${fileResponse.bodyBytes.length} textLen=${resultText?.length ?? 0}');
        }
      } else {
        if (!kReleaseMode) {
          debugPrint('[NESDC] PDF fetch failed: url=$resultFileUrl status=${fileResponse.statusCode}');
        }
      }
    } else {
      if (!kReleaseMode) {
        debugPrint('[NESDC] No result file url for detail: $detailUrl');
      }
    }

    final detail = NesdcPollDetail(
      detailUrl: detailUrl,
      surveyDate: surveyDate,
      sampleSize: sampleSize,
      marginOfError: marginOfError,
      resultFileUrl: resultFileUrl,
      detailText: detailText,
      resultText: resultText,
      fields: fields,
    );

    _detailCache[detailUrl] = detail;
    if (!kReleaseMode) {
      debugPrint(
        '[NESDC] detail parsed: url=$detailUrl survey=${surveyDate?.toIso8601String()} sample=$sampleSize margin=$marginOfError resultUrl=${resultFileUrl ?? "-"}',
      );
    }
    return detail;
  }

  Uri _buildListUri(int page) {
    final target = _nesdcOrigin.replace(
      path: '/portal/bbs/B0000005/list.do',
      queryParameters: {
        'menuNo': '200467',
        'pageIndex': '$page',
      },
    );
    return _wrapProxy(target);
  }

  Uri _wrapProxy(Uri target) {
    final base = Uri.parse(kNesdcBaseUrl);
    if (base.host.contains('nesdc.go.kr')) {
      return target;
    }
    return base.replace(queryParameters: {'url': target.toString()});
  }

  Uri _resolveBackendBase() {
    final raw = kNesdcBackendUrl.trim();
    if (raw.isEmpty) {
      return Uri.parse(raw);
    }
    final base = Uri.parse(raw);
    if (kIsWeb) {
      return base;
    }
    if (defaultTargetPlatform == TargetPlatform.android &&
        (base.host == 'localhost' || base.host == '127.0.0.1')) {
      return base.replace(host: '10.0.2.2');
    }
    return base;
  }

  Uri? _resolveWebBackendOverride() {
    if (!kIsWeb) {
      return null;
    }
    if (kNesdcBackendUrl.trim().isNotEmpty) {
      return null;
    }
    try {
      return Uri.base.resolve('data/nesdc_polls.json');
    } catch (_) {
      return null;
    }
  }

  Uri _buildBackendUrl(Uri base, int pages) {
    if (_isJsonEndpoint(base)) {
      return base;
    }
    final path = base.path.endsWith('/') ? '${base.path}polls' : '${base.path}/polls';
    return base.replace(path: path, queryParameters: {
      ...base.queryParameters,
      'pages': '$pages',
    });
  }

  bool _isJsonEndpoint(Uri base) {
    return base.path.toLowerCase().endsWith('.json');
  }

  Uri _toTargetUri(String urlOrPath) {
    final uri = Uri.parse(urlOrPath);
    if (uri.hasScheme) {
      return uri;
    }
    return _nesdcOrigin.resolve(urlOrPath);
  }

  Map<String, String> _defaultHeaders() {
    return const {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    };
  }

  String _decodeBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      return response.body;
    }
  }

  List<NesdcPollEntry> _parseListHtml(String html) {
    final document = html_parser.parse(html);
    final entries = <NesdcPollEntry>[];

    final rows = document.querySelectorAll('div.board a');
    for (final row in rows) {
      final spanCols = row
          .querySelectorAll('span.col')
          .map((e) => e.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final cols = spanCols.isNotEmpty
          ? spanCols
          : row.text
              .split(RegExp(r'\s{2,}'))
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();

      final entry = _buildEntryFromColumns(cols, row.attributes['href']);
      if (entry != null) {
        entries.add(entry);
      }
    }

    if (entries.isNotEmpty) {
      return entries;
    }

    final tableRows = document.querySelectorAll('table tbody tr');
    for (final row in tableRows) {
      final cols = row
          .querySelectorAll('td')
          .map((e) => e.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (cols.isEmpty) {
        continue;
      }

      final link = row.querySelector('a');
      final entry = _buildEntryFromColumns(cols, link?.attributes['href']);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  NesdcPollEntry? _buildEntryFromColumns(List<String> cols, String? href) {
    if (cols.length < 7) {
      return null;
    }

    final hasRegion = cols.length >= 8;
    final hasStatus = cols.length >= 9;

    final registrationNo = cols[0];
    final agency = cols[1];
    final client = cols[2];
    final method = cols[3];
    final sampleFrame = cols[4];
    final pollName = cols[5];
    final registeredDateText = cols[6];
    final region = hasRegion ? cols[7] : '';
    final status = hasStatus ? cols[8] : null;

    final registeredDate = DateTime.tryParse(registeredDateText) ?? DateTime.now();
    final sourceUrl = href == null
        ? _nesdcOrigin.toString()
        : _nesdcOrigin.resolve(href).toString();

    return NesdcPollEntry(
      registrationNo: registrationNo,
      agency: agency,
      client: client,
      method: method,
      sampleFrame: sampleFrame,
      pollName: pollName,
      registeredDate: registeredDate,
      region: region,
      sourceUrl: sourceUrl,
      status: status,
    );
  }

  Map<String, String> _extractFields(html_dom.Document document) {
    final fields = <String, String>{};
    for (final th in document.querySelectorAll('th')) {
      final label = th.text.trim();
      final td = th.nextElementSibling;
      if (label.isEmpty || td == null) {
        continue;
      }
      final value = td.text.trim();
      if (value.isNotEmpty) {
        fields[label] = value;
      }
    }

    for (final dt in document.querySelectorAll('dt')) {
      final label = dt.text.trim();
      final dd = dt.nextElementSibling;
      if (label.isEmpty || dd == null) {
        continue;
      }
      final value = dd.text.trim();
      if (value.isNotEmpty) {
        fields[label] = value;
      }
    }
    return fields;
  }

  DateTime? _parseSurveyDate(Map<String, String> fields, String? fallbackText) {
    final candidates = [
      fields['조사기간'],
      fields['조사일시'],
      fields['조사일'],
    ];

    for (final value in candidates) {
      final date = _parseDateFromText(value);
      if (date != null) {
        return date;
      }
    }

    return _parseDateFromText(fallbackText);
  }

  DateTime? _parseDateFromText(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }

    final rangeMatch = RegExp(r'(\d{4}[-./]\d{1,2}[-./]\d{1,2}).*?(\d{4}[-./]\d{1,2}[-./]\d{1,2})')
        .firstMatch(text);
    if (rangeMatch != null) {
      final end = _parseDateToken(rangeMatch.group(2));
      return end;
    }

    final singleMatch = RegExp(r'(\d{4}[-./]\d{1,2}[-./]\d{1,2})').firstMatch(text);
    if (singleMatch != null) {
      return _parseDateToken(singleMatch.group(1));
    }
    return null;
  }

  DateTime? _parseDateToken(String? token) {
    if (token == null) {
      return null;
    }
    final normalized = token.replaceAll('.', '-').replaceAll('/', '-');
    return DateTime.tryParse(normalized);
  }

  int? _parseSampleSize(Map<String, String> fields, String? fallbackText) {
    final candidates = [
      fields['표본크기'],
      fields['표본'],
      fields['표본수'],
    ];

    for (final value in candidates) {
      final parsed = _parseSampleSizeFromText(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return _parseSampleSizeFromText(fallbackText);
  }

  int? _parseSampleSizeFromText(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final match = RegExp(r'([0-9,]{3,})\s*명').firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  double? _parseMarginOfError(Map<String, String> fields, String? fallbackText) {
    final candidates = [
      fields['표본오차'],
      fields['오차범위'],
      fields['오차한계'],
    ];

    for (final value in candidates) {
      final parsed = _parseMarginFromText(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return _parseMarginFromText(fallbackText);
  }

  double? _parseMarginFromText(String? text) {
    if (text == null || text.isEmpty) {
      return null;
    }
    final strictMatch = RegExp(r'±\s*([0-9]+(?:\.[0-9]+)?)\s*%p?').firstMatch(text) ??
        RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%p').firstMatch(text);
    if (strictMatch != null) {
      final value = double.tryParse(strictMatch.group(1)!);
      if (value != null && value <= 20) {
        return value;
      }
      return null;
    }

    final looseMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*%').firstMatch(text);
    if (looseMatch == null) {
      return null;
    }
    final value = double.tryParse(looseMatch.group(1)!);
    if (value == null || value > 20) {
      return null;
    }
    if (text.contains('신뢰') || text.contains('유의')) {
      return null;
    }
    return value;
  }

  String? _findResultFileUrl(html_dom.Document document) {
    String? pdfUrl;
    String? otherUrl;

    final candidates = <html_dom.Element>[
      ...document.querySelectorAll('div[id^="realfile_"] a'),
      ...document.querySelectorAll('.file a'),
      ...document.querySelectorAll('a'),
    ];

    for (final link in candidates) {
      final raw = _pickLinkRaw(link);
      if (raw == null || raw.isEmpty) {
        continue;
      }

      final resolved = _resolveAttachmentUrl(raw);
      if (resolved == null || _isRootUrl(resolved)) {
        continue;
      }

      final lower = resolved.toLowerCase();
      if (lower.endsWith('.pdf')) {
        pdfUrl = resolved;
        break;
      }

      final isAttachment = raw.contains('fileDown') ||
          raw.contains('FileDown') ||
          raw.contains('view(') ||
          lower.contains('filedown');
      if (otherUrl == null && isAttachment) {
        otherUrl = resolved;
      }
    }

    return pdfUrl ?? otherUrl;
  }

  String? _resolveAttachmentUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('view(')) {
      final match = RegExp(r'view\(([^)]*)\)').firstMatch(trimmed);
      if (match != null) {
        final args = _extractQuotedArgs(match.group(1) ?? '');
        if (args.length >= 4) {
          final base = _nesdcOrigin.resolve('/portal/cmm/fms/FileDown.do').toString();
          final query =
              'atchFileId=${args[0]}&fileSn=${args[1]}&bbsId=${args[2]}&bbsKey=${args[3]}';
          return '$base?$query';
        }
      }
    }

    if (trimmed.contains('FileDown') || trimmed.contains('fileDown')) {
      final match = RegExp("(https?://[^'\"\\s]+)").firstMatch(trimmed);
      if (match != null) {
        return match.group(1);
      }
      final functionMatch = RegExp(r"\(([^)]*)\)").firstMatch(trimmed);
      if (functionMatch != null) {
        final inside = functionMatch.group(1) ?? '';
        final args = _extractQuotedArgs(inside);
        if (args.isNotEmpty) {
          final candidate = args.first;
          if (candidate.startsWith('/')) {
            return _nesdcOrigin.resolve(candidate).toString();
          }
          if (candidate.startsWith('http')) {
            return candidate;
          }
        }
      }
      final hrefMatch = RegExp(r'(/[^\\s]+fileDown[^\\s]+)').firstMatch(trimmed);
      if (hrefMatch != null) {
        return _nesdcOrigin.resolve(hrefMatch.group(1)!).toString();
      }
    }

    if (trimmed.startsWith('javascript')) {
      return null;
    }

    if (trimmed.startsWith('/')) {
      return _nesdcOrigin.resolve(trimmed).toString();
    }

    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    return null;
  }

  String? _pickLinkRaw(html_dom.Element link) {
    final href = link.attributes['href']?.trim() ?? '';
    final onclick = link.attributes['onclick']?.trim() ?? '';
    final dataUrl = link.attributes['data-url'] ??
        link.attributes['data-href'] ??
        link.attributes['data-download'] ??
        link.attributes['data-file'];

    final dataValue = dataUrl?.trim();
    if (dataValue != null && dataValue.isNotEmpty) {
      return dataValue;
    }
    if (onclick.isNotEmpty && _isJunkHref(href)) {
      return onclick;
    }
    if (href.isNotEmpty && !_isJunkHref(href)) {
      return href;
    }
    if (onclick.isNotEmpty) {
      return onclick;
    }
    return null;
  }

  bool _isJunkHref(String href) {
    final lower = href.trim().toLowerCase();
    return lower.isEmpty ||
        lower == '#' ||
        lower == 'javascript:void(0);' ||
        lower == 'javascript:;' ||
        lower.startsWith('javascript:') ||
        lower == 'void(0)';
  }

  bool _isRootUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    return uri.host == _nesdcOrigin.host &&
        (uri.path.isEmpty || uri.path == '/');
  }

  List<String> _extractQuotedArgs(String text) {
    final args = <String>[];
    final matches = RegExp("'([^']*)'|\"([^\"]*)\"").allMatches(text);
    for (final match in matches) {
      final value = match.group(1) ?? match.group(2);
      if (value != null) {
        args.add(value);
      }
    }
    return args;
  }

  String? _extractTableText(html_dom.Document document) {
    final lines = <String>[];
    for (final row in document.querySelectorAll('table tr')) {
      final cells = row
          .querySelectorAll('th, td')
          .map((e) => e.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) {
        lines.add(cells.join(' '));
      }
    }
    if (lines.isEmpty) {
      return null;
    }
    return lines.join('\n');
  }

  String? _mergeDetailText(String? bodyText, String? tableText) {
    final parts = <String>[];
    if (bodyText != null && bodyText.trim().isNotEmpty) {
      parts.add(bodyText.trim());
    }
    if (tableText != null && tableText.trim().isNotEmpty) {
      parts.add(tableText.trim());
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join('\n');
  }

  String? _tryExtractPdfText(Uint8List bytes) {
    return extractPdfText(bytes);
  }
}
