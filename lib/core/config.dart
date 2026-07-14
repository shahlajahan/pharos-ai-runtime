class Config {
  const Config({
    this.appName = 'Pharos AI Runtime',
    this.version = '0.1.0',
    this.environment = 'development',
    this.logLevel = 'info',
  });

  final String appName;
  final String version;
  final String environment;
  final String logLevel;
}
