const Duration kProdRefreshInterval = Duration(hours: 1);
const Duration kDevRefreshInterval = Duration(seconds: 30);

const bool kIsReleaseMode = bool.fromEnvironment('dart.vm.product');

Duration defaultRefreshInterval() {
  return kIsReleaseMode ? kProdRefreshInterval : kDevRefreshInterval;
}

const int kNesdcPagesToFetch = 2;

const String kNesdcBaseUrl = String.fromEnvironment(
  'NESDC_BASE_URL',
  defaultValue: 'https://www.nesdc.go.kr',
);

const String kNesdcBackendUrl = String.fromEnvironment(
  'NESDC_BACKEND_URL',
  defaultValue: '',
);
