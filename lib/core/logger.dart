class Logger {
  const Logger();

  void debug(String message) => _log('DEBUG', message);

  void info(String message) => _log('INFO', message);

  void warning(String message) => _log('WARNING', message);

  void error(String message) => _log('ERROR', message);

  void _log(String level, String message) => print('[$level] $message');
}
