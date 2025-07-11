/*
---------------------------------------------------------------
File name:          http_client.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        HTTP网络客户端 (HTTP Client)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Task 2.2.5 网络通信和离线支持;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

/// HTTP协议版本枚举
enum HttpVersion {
  /// HTTP/1.1
  http1_1,

  /// HTTP/2
  http2,

  /// HTTP/3
  http3,
}

/// 压缩类型枚举
enum CompressionType {
  /// 无压缩
  none,

  /// Gzip压缩
  gzip,

  /// Brotli压缩
  brotli,

  /// Deflate压缩
  deflate,
}

/// 网络质量枚举
enum NetworkQuality {
  /// 优秀
  excellent,

  /// 良好
  good,

  /// 一般
  fair,

  /// 差
  poor,

  /// 离线
  offline,
}

/// HTTP请求配置
class HttpRequestConfig {
  /// 请求超时时间
  final Duration timeout;

  /// 连接超时时间
  final Duration connectTimeout;

  /// 读取超时时间
  final Duration readTimeout;

  /// 最大重试次数
  final int maxRetries;

  /// 是否跟随重定向
  final bool followRedirects;

  /// 最大重定向次数
  final int maxRedirects;

  /// 压缩类型
  final CompressionType compression;

  /// 是否验证SSL证书
  final bool verifySsl;

  /// 用户代理
  final String userAgent;

  /// 自定义头部
  final Map<String, String> headers;

  const HttpRequestConfig({
    this.timeout = const Duration(seconds: 30),
    this.connectTimeout = const Duration(seconds: 10),
    this.readTimeout = const Duration(seconds: 20),
    this.maxRetries = 3,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.compression = CompressionType.gzip,
    this.verifySsl = true,
    this.userAgent = 'Ming-CLI/1.0',
    this.headers = const {},
  });
}

/// HTTP响应
class HttpResponse {
  /// 状态码
  final int statusCode;

  /// 响应头
  final Map<String, String> headers;

  /// 响应体
  final Uint8List body;

  /// 响应时间
  final Duration responseTime;

  /// 是否来自缓存
  final bool fromCache;

  /// 压缩类型
  final CompressionType compression;

  /// 内容长度
  final int contentLength;

  const HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.responseTime,
    required this.fromCache,
    required this.compression,
    required this.contentLength,
  });

  /// 是否成功
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// 是否重定向
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// 是否客户端错误
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// 是否服务器错误
  bool get isServerError => statusCode >= 500;

  /// 响应体文本
  String get bodyText => utf8.decode(body);

  /// 响应体JSON
  dynamic get bodyJson => jsonDecode(bodyText);
}

/// 连接池信息
class ConnectionPool {
  /// 最大连接数
  final int maxConnections;

  /// 当前活跃连接数
  int activeConnections = 0;

  /// 空闲连接数
  int idleConnections = 0;

  /// Keep-Alive超时时间
  final Duration keepAliveTimeout;

  /// 连接创建时间
  final Map<String, DateTime> connectionTimes = {};

  /// 连接使用统计
  final Map<String, int> connectionUsage = {};

  ConnectionPool({
    this.maxConnections = 100,
    this.keepAliveTimeout = const Duration(minutes: 5),
  });

  /// 是否可以创建新连接
  bool get canCreateConnection => activeConnections < maxConnections;

  /// 连接池使用率
  double get utilizationRate => activeConnections / maxConnections;
}

/// 网络质量检测器
class NetworkQualityDetector {
  /// 延迟阈值配置
  static const Map<NetworkQuality, int> _latencyThresholds = {
    NetworkQuality.excellent: 50, // <50ms
    NetworkQuality.good: 150, // 50-150ms
    NetworkQuality.fair: 300, // 150-300ms
    NetworkQuality.poor: 1000, // 300-1000ms
  };

  /// 带宽阈值配置 (KB/s)
  static const Map<NetworkQuality, int> _bandwidthThresholds = {
    NetworkQuality.excellent: 10240, // >10MB/s
    NetworkQuality.good: 1024, // 1-10MB/s
    NetworkQuality.fair: 256, // 256KB-1MB/s
    NetworkQuality.poor: 64, // 64-256KB/s
  };

  /// 检测网络质量
  static Future<NetworkQuality> detectQuality(String testUrl) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 发送测试请求
      final client = io.HttpClient();
      final request = await client.getUrl(Uri.parse(testUrl));
      final response = await request.close();

      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      // 计算带宽 (简化计算)
      final contentLength = response.contentLength;
      final bandwidth = contentLength > 0
          ? (contentLength / stopwatch.elapsedMilliseconds * 1000) ~/ 1024
          : 0;

      client.close();

      // 根据延迟和带宽判断网络质量
      return _calculateQuality(latency, bandwidth);
    } catch (e) {
      return NetworkQuality.offline;
    }
  }

  /// 计算网络质量
  static NetworkQuality _calculateQuality(int latency, int bandwidth) {
    // 延迟评分
    NetworkQuality latencyQuality = NetworkQuality.poor;
    for (final entry in _latencyThresholds.entries) {
      if (latency <= entry.value) {
        latencyQuality = entry.key;
        break;
      }
    }

    // 带宽评分
    NetworkQuality bandwidthQuality = NetworkQuality.poor;
    for (final entry in _bandwidthThresholds.entries.toList().reversed) {
      if (bandwidth >= entry.value) {
        bandwidthQuality = entry.key;
        break;
      }
    }

    // 取较低的评分
    final qualities = [latencyQuality, bandwidthQuality];
    qualities.sort((a, b) => b.index.compareTo(a.index));
    return qualities.first;
  }
}

/// HTTP客户端
class HttpClient {
  /// 请求配置
  final HttpRequestConfig _config;

  /// 连接池
  final ConnectionPool _connectionPool;

  /// 网络质量
  NetworkQuality _networkQuality = NetworkQuality.good;

  /// 请求统计
  final Map<String, int> _requestStats = {};

  /// 响应缓存
  final Map<String, HttpResponse> _responseCache = {};

  /// 代理配置
  String? _proxyUrl;

  /// 认证信息
  String? _authToken;

  /// 构造函数
  HttpClient({
    HttpRequestConfig? config,
    ConnectionPool? connectionPool,
  })  : _config = config ?? const HttpRequestConfig(),
        _connectionPool = connectionPool ?? ConnectionPool() {
    _initializeClient();
  }

  /// GET请求
  Future<HttpResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    return await _makeRequest(
      'GET',
      url,
      headers: headers,
      queryParams: queryParams,
    );
  }

  /// POST请求
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    String? contentType,
  }) async {
    return await _makeRequest(
      'POST',
      url,
      headers: headers,
      body: body,
      contentType: contentType,
    );
  }

  /// PUT请求
  Future<HttpResponse> put(
    String url, {
    Map<String, String>? headers,
    dynamic body,
    String? contentType,
  }) async {
    return await _makeRequest(
      'PUT',
      url,
      headers: headers,
      body: body,
      contentType: contentType,
    );
  }

  /// DELETE请求
  Future<HttpResponse> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    return await _makeRequest(
      'DELETE',
      url,
      headers: headers,
    );
  }

  /// 下载文件
  Future<HttpResponse> download(
    String url,
    String outputPath, {
    Function(int downloaded, int total)? onProgress,
  }) async {
    final response = await get(url);

    if (response.isSuccess) {
      final file = io.File(outputPath);
      await file.writeAsBytes(response.body);

      // 模拟进度回调
      onProgress?.call(response.body.length, response.body.length);
    }

    return response;
  }

  /// 上传文件
  Future<HttpResponse> upload(
    String url,
    String filePath, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    Function(int uploaded, int total)? onProgress,
  }) async {
    final file = io.File(filePath);
    final fileBytes = await file.readAsBytes();

    // 模拟进度回调
    onProgress?.call(fileBytes.length, fileBytes.length);

    return await post(
      url,
      headers: {
        'Content-Type': 'multipart/form-data',
        ...?headers,
      },
      body: fileBytes,
    );
  }

  /// 设置代理
  void setProxy(String proxyUrl) {
    _proxyUrl = proxyUrl;
  }

  /// 设置认证令牌
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// 检测网络质量
  Future<void> detectNetworkQuality(String testUrl) async {
    _networkQuality = await NetworkQualityDetector.detectQuality(testUrl);
  }

  /// 获取网络质量
  NetworkQuality get networkQuality => _networkQuality;

  /// 获取连接池状态
  ConnectionPool get connectionPool => _connectionPool;

  /// 获取请求统计
  Map<String, dynamic> getRequestStats() {
    return {
      'totalRequests':
          _requestStats.values.fold(0, (sum, count) => sum + count),
      'requestsByMethod': Map.from(_requestStats),
      'cacheHitRate': _calculateCacheHitRate(),
      'connectionPoolUtilization': _connectionPool.utilizationRate,
      'networkQuality': _networkQuality.name,
    };
  }

  /// 清理缓存
  void clearCache() {
    _responseCache.clear();
  }

  /// 关闭客户端
  void close() {
    _responseCache.clear();
    _connectionPool.activeConnections = 0;
    _connectionPool.idleConnections = 0;
  }

  /// 发起HTTP请求
  Future<HttpResponse> _makeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
    dynamic body,
    String? contentType,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 构建完整URL
      final uri = _buildUri(url, queryParams);

      // 检查缓存
      if (method == 'GET') {
        final cached = _getCachedResponse(uri.toString());
        if (cached != null) {
          return cached;
        }
      }

      // 检查连接池
      if (!_connectionPool.canCreateConnection) {
        throw Exception('Connection pool exhausted');
      }

      // 更新连接池状态
      _connectionPool.activeConnections++;

      // 构建请求头
      final requestHeaders = _buildHeaders(headers, contentType);

      // 模拟HTTP请求
      await Future.delayed(Duration(milliseconds: _getRequestDelay()));

      // 模拟响应
      final response =
          _createMockResponse(method, uri, body, stopwatch.elapsed);

      // 更新统计
      _updateRequestStats(method);

      // 缓存GET响应
      if (method == 'GET' && response.isSuccess) {
        _cacheResponse(uri.toString(), response);
      }

      // 更新连接池状态
      _connectionPool.activeConnections--;
      _connectionPool.idleConnections++;

      return response;
    } catch (e) {
      _connectionPool.activeConnections--;
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  /// 构建URI
  Uri _buildUri(String url, Map<String, String>? queryParams) {
    final uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      });
    }
    return uri;
  }

  /// 构建请求头
  Map<String, String> _buildHeaders(
    Map<String, String>? headers,
    String? contentType,
  ) {
    final requestHeaders = <String, String>{
      'User-Agent': _config.userAgent,
      'Accept-Encoding': _getAcceptEncoding(),
      ..._config.headers,
    };

    if (contentType != null) {
      requestHeaders['Content-Type'] = contentType;
    }

    if (_authToken != null) {
      requestHeaders['Authorization'] = 'Bearer $_authToken';
    }

    if (headers != null) {
      requestHeaders.addAll(headers);
    }

    return requestHeaders;
  }

  /// 获取Accept-Encoding头
  String _getAcceptEncoding() {
    switch (_config.compression) {
      case CompressionType.gzip:
        return 'gzip, deflate';
      case CompressionType.brotli:
        return 'br, gzip, deflate';
      case CompressionType.deflate:
        return 'deflate';
      case CompressionType.none:
        return 'identity';
    }
  }

  /// 获取请求延迟 (根据网络质量)
  int _getRequestDelay() {
    switch (_networkQuality) {
      case NetworkQuality.excellent:
        return 10;
      case NetworkQuality.good:
        return 50;
      case NetworkQuality.fair:
        return 150;
      case NetworkQuality.poor:
        return 500;
      case NetworkQuality.offline:
        return 5000;
    }
  }

  /// 创建模拟响应
  HttpResponse _createMockResponse(
    String method,
    Uri uri,
    dynamic body,
    Duration responseTime,
  ) {
    // 模拟不同的响应
    final statusCode = _getMockStatusCode(method, uri);
    final responseBody = _getMockResponseBody(method, uri, body);

    return HttpResponse(
      statusCode: statusCode,
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': responseBody.length.toString(),
        'Server': 'Ming-Server/1.0',
        'Date': DateTime.now().toUtc().toString(),
      },
      body: Uint8List.fromList(responseBody.codeUnits),
      responseTime: responseTime,
      fromCache: false,
      compression: _config.compression,
      contentLength: responseBody.length,
    );
  }

  /// 获取模拟状态码
  int _getMockStatusCode(String method, Uri uri) {
    // 模拟不同的状态码
    if (uri.path.contains('error')) {
      return 500;
    } else if (uri.path.contains('notfound')) {
      return 404;
    } else if (uri.path.contains('unauthorized')) {
      return 401;
    } else if (method == 'POST' && uri.path.contains('create')) {
      return 201;
    } else {
      return 200;
    }
  }

  /// 获取模拟响应体
  String _getMockResponseBody(String method, Uri uri, dynamic body) {
    return jsonEncode({
      'method': method,
      'url': uri.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'success': true,
      'data': {
        'message': 'Mock response from HTTP client',
        'requestBody': body?.toString(),
      },
    });
  }

  /// 获取缓存响应
  HttpResponse? _getCachedResponse(String url) {
    final cached = _responseCache[url];
    if (cached != null) {
      // 检查缓存是否过期 (简化实现)
      final cacheAge = DateTime.now().difference(
          DateTime.parse(cached.headers['Date'] ?? DateTime.now().toString()));

      if (cacheAge.inMinutes < 5) {
        return HttpResponse(
          statusCode: cached.statusCode,
          headers: cached.headers,
          body: cached.body,
          responseTime: cached.responseTime,
          fromCache: true,
          compression: cached.compression,
          contentLength: cached.contentLength,
        );
      } else {
        _responseCache.remove(url);
      }
    }
    return null;
  }

  /// 缓存响应
  void _cacheResponse(String url, HttpResponse response) {
    // 限制缓存大小
    if (_responseCache.length >= 1000) {
      final oldestKey = _responseCache.keys.first;
      _responseCache.remove(oldestKey);
    }

    _responseCache[url] = response;
  }

  /// 更新请求统计
  void _updateRequestStats(String method) {
    _requestStats[method] = (_requestStats[method] ?? 0) + 1;
  }

  /// 计算缓存命中率
  double _calculateCacheHitRate() {
    final totalRequests =
        _requestStats.values.fold(0, (sum, count) => sum + count);
    final cacheHits = _responseCache.length;
    return totalRequests > 0 ? cacheHits / totalRequests : 0.0;
  }

  /// 初始化客户端
  void _initializeClient() {
    // 初始化连接池
    _connectionPool.idleConnections = 0;
    _connectionPool.activeConnections = 0;

    // 初始化统计
    _requestStats.clear();

    // 检测初始网络质量
    Future.delayed(const Duration(milliseconds: 100), () {
      detectNetworkQuality('https://www.google.com');
    });
  }
}
