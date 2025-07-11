/*
---------------------------------------------------------------
File name:          registry_client.dart
Author:             lgnorant-lu
Date created:       2025/07/11
Last modified:      2025/07/11
Dart Version:       3.2+
Description:        注册表网络客户端 (Registry Network Client)
---------------------------------------------------------------
Change History:
    2025/07/11: Initial creation - Phase 2.2 远程模板生态建设;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 认证类型枚举
enum AuthType {
  /// 无认证
  none,

  /// Token认证
  token,

  /// OAuth2认证
  oauth2,

  /// API Key认证
  apiKey,

  /// 证书认证
  certificate,
}

/// 认证配置
class AuthConfig {
  const AuthConfig({
    required this.type,
    required this.credentials,
  });

  /// 创建Token认证
  factory AuthConfig.token(String token) {
    return AuthConfig(
      type: AuthType.token,
      credentials: {'token': token},
    );
  }

  /// 创建API Key认证
  factory AuthConfig.apiKey(String apiKey, {String header = 'X-API-Key'}) {
    return AuthConfig(
      type: AuthType.apiKey,
      credentials: {'apiKey': apiKey, 'header': header},
    );
  }

  /// 创建OAuth2认证
  factory AuthConfig.oauth2(String accessToken) {
    return AuthConfig(
      type: AuthType.oauth2,
      credentials: {'accessToken': accessToken},
    );
  }

  /// 认证类型
  final AuthType type;

  /// 认证参数
  final Map<String, String> credentials;
}

/// HTTP请求配置
class RequestConfig {
  const RequestConfig({
    this.timeout = const Duration(seconds: 30),
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableCache = true,
    this.cacheTtl = const Duration(minutes: 5),
    this.userAgent = 'Ming-Status-CLI/2.1.0',
  });

  /// 超时时间
  final Duration timeout;

  /// 重试次数
  final int retryCount;

  /// 重试延迟
  final Duration retryDelay;

  /// 是否启用缓存
  final bool enableCache;

  /// 缓存TTL
  final Duration cacheTtl;

  /// 用户代理
  final String userAgent;
}

/// HTTP响应包装
class RegistryResponse<T> {
  const RegistryResponse({
    required this.statusCode,
    required this.headers,
    required this.responseTime,
    this.data,
    this.error,
    this.fromCache = false,
  });

  /// 状态码
  final int statusCode;

  /// 响应数据
  final T? data;

  /// 错误信息
  final String? error;

  /// 响应头
  final Map<String, String> headers;

  /// 是否来自缓存
  final bool fromCache;

  /// 响应时间
  final Duration responseTime;

  /// 是否成功
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// 是否客户端错误
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// 是否服务器错误
  bool get isServerError => statusCode >= 500;
}

/// 缓存条目
class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
    this.etag,
  });

  /// 缓存数据
  final String data;

  /// 缓存时间
  final DateTime cachedAt;

  /// TTL
  final Duration ttl;

  /// ETag
  final String? etag;

  /// 是否过期
  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
}

/// 注册表网络客户端
class RegistryClient {
  /// 构造函数
  RegistryClient({
    AuthConfig? authConfig,
    RequestConfig? requestConfig,
  })  : _authConfig = authConfig,
        _requestConfig = requestConfig ?? const RequestConfig() {
    _initializeHttpClient();
  }

  /// HTTP客户端
  late final HttpClient _httpClient;

  /// 认证配置
  AuthConfig? _authConfig;

  /// 请求配置
  RequestConfig _requestConfig;

  /// 响应缓存
  final Map<String, CacheEntry> _cache = {};

  /// 网络状态
  bool _isOnline = true;

  /// 设置认证配置
  void setAuth(AuthConfig authConfig) {
    _authConfig = authConfig;
  }

  /// 更新请求配置
  void updateConfig(RequestConfig config) {
    _requestConfig = config;
  }

  /// GET请求
  Future<RegistryResponse<Map<String, dynamic>>> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest('GET', url, headers: headers, queryParams: queryParams);
  }

  /// POST请求
  Future<RegistryResponse<Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _makeRequest('POST', url, body: body, headers: headers);
  }

  /// PUT请求
  Future<RegistryResponse<Map<String, dynamic>>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _makeRequest('PUT', url, body: body, headers: headers);
  }

  /// DELETE请求
  Future<RegistryResponse<Map<String, dynamic>>> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    return _makeRequest('DELETE', url, headers: headers);
  }

  /// 下载文件
  Future<RegistryResponse<List<int>>> downloadFile(
    String url, {
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
  }) async {
    final startTime = DateTime.now();

    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);

      // 设置请求头
      _setRequestHeaders(request, headers);

      final response = await request.close();
      final responseTime = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        final bytes = <int>[];
        final contentLength = response.contentLength;
        var receivedBytes = 0;

        await for (final chunk in response) {
          bytes.addAll(chunk);
          receivedBytes += chunk.length;
          onProgress?.call(receivedBytes, contentLength);
        }

        return RegistryResponse<List<int>>(
          statusCode: response.statusCode,
          data: bytes,
          headers: _extractHeaders(response),
          responseTime: responseTime,
        );
      } else {
        return RegistryResponse<List<int>>(
          statusCode: response.statusCode,
          error: 'HTTP ${response.statusCode}',
          headers: _extractHeaders(response),
          responseTime: responseTime,
        );
      }
    } catch (e) {
      return RegistryResponse<List<int>>(
        statusCode: 0,
        error: e.toString(),
        headers: {},
        responseTime: DateTime.now().difference(startTime),
      );
    }
  }

  /// 检查网络状态
  Future<bool> checkNetworkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final validEntries =
        _cache.values.where((entry) => !entry.isExpired).length;
    final expiredEntries = _cache.length - validEntries;

    return {
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': expiredEntries,
      'hitRate': 0.0, // TODO: 实现命中率统计
    };
  }

  /// 初始化HTTP客户端
  void _initializeHttpClient() {
    _httpClient = HttpClient();
    _httpClient.connectionTimeout = _requestConfig.timeout;
    _httpClient.userAgent = _requestConfig.userAgent;
  }

  /// 执行HTTP请求
  Future<RegistryResponse<Map<String, dynamic>>> _makeRequest(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    final startTime = DateTime.now();

    // 检查缓存
    if (method == 'GET' && _requestConfig.enableCache) {
      final cacheKey = _generateCacheKey(url, queryParams);
      final cachedEntry = _cache[cacheKey];
      if (cachedEntry != null && !cachedEntry.isExpired) {
        return RegistryResponse<Map<String, dynamic>>(
          statusCode: 200,
          data: json.decode(cachedEntry.data) as Map<String, dynamic>,
          headers: {},
          fromCache: true,
          responseTime: DateTime.now().difference(startTime),
        );
      }
    }

    // 构建URL
    var uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    // 重试逻辑
    for (var attempt = 0; attempt <= _requestConfig.retryCount; attempt++) {
      try {
        final response =
            await _executeRequest(method, uri, body: body, headers: headers);

        // 缓存GET请求的成功响应
        if (method == 'GET' &&
            response.isSuccess &&
            _requestConfig.enableCache) {
          final cacheKey = _generateCacheKey(url, queryParams);
          _cache[cacheKey] = CacheEntry(
            data: json.encode(response.data),
            cachedAt: DateTime.now(),
            ttl: _requestConfig.cacheTtl,
            etag: response.headers['etag'],
          );
        }

        return response;
      } catch (e) {
        if (attempt == _requestConfig.retryCount) {
          return RegistryResponse<Map<String, dynamic>>(
            statusCode: 0,
            error: e.toString(),
            headers: {},
            responseTime: DateTime.now().difference(startTime),
          );
        }

        // 等待重试
        await Future.delayed(_requestConfig.retryDelay * (attempt + 1));
      }
    }

    // 不应该到达这里
    return RegistryResponse<Map<String, dynamic>>(
      statusCode: 0,
      error: 'Unexpected error',
      headers: {},
      responseTime: DateTime.now().difference(startTime),
    );
  }

  /// 执行单次HTTP请求
  Future<RegistryResponse<Map<String, dynamic>>> _executeRequest(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final startTime = DateTime.now();

    late HttpClientRequest request;

    switch (method) {
      case 'GET':
        request = await _httpClient.getUrl(uri);
      case 'POST':
        request = await _httpClient.postUrl(uri);
      case 'PUT':
        request = await _httpClient.putUrl(uri);
      case 'DELETE':
        request = await _httpClient.deleteUrl(uri);
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }

    // 设置请求头
    _setRequestHeaders(request, headers);

    // 写入请求体
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(json.encode(body));
    }

    final response = await request.close();
    final responseTime = DateTime.now().difference(startTime);

    // 读取响应体
    final responseBody = await response.transform(utf8.decoder).join();

    Map<String, dynamic>? responseData;
    if (responseBody.isNotEmpty) {
      try {
        responseData = json.decode(responseBody) as Map<String, dynamic>;
      } catch (e) {
        // 响应不是JSON格式
        responseData = {'raw': responseBody};
      }
    }

    return RegistryResponse<Map<String, dynamic>>(
      statusCode: response.statusCode,
      data: responseData,
      error: response.statusCode >= 400 ? responseBody : null,
      headers: _extractHeaders(response),
      responseTime: responseTime,
    );
  }

  /// 设置请求头
  void _setRequestHeaders(
      HttpClientRequest request, Map<String, String>? headers) {
    // 设置认证头
    if (_authConfig != null) {
      switch (_authConfig!.type) {
        case AuthType.token:
          request.headers.set(
              'Authorization', 'Bearer ${_authConfig!.credentials['token']}');
        case AuthType.apiKey:
          final header = _authConfig!.credentials['header'] ?? 'X-API-Key';
          request.headers.set(header, _authConfig!.credentials['apiKey']!);
        case AuthType.oauth2:
          request.headers.set('Authorization',
              'Bearer ${_authConfig!.credentials['accessToken']}');
        case AuthType.certificate:
          // TODO: 实现证书认证
          break;
        case AuthType.none:
          break;
      }
    }

    // 设置自定义头
    if (headers != null) {
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
    }

    // 设置默认头
    request.headers.set('User-Agent', _requestConfig.userAgent);
    request.headers.set('Accept', 'application/json');
  }

  /// 提取响应头
  Map<String, String> _extractHeaders(HttpClientResponse response) {
    final headers = <String, String>{};
    response.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(', ');
    });
    return headers;
  }

  /// 生成缓存键
  String _generateCacheKey(String url, Map<String, String>? queryParams) {
    final buffer = StringBuffer(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      buffer.write('?');
      buffer.write(
        queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'),
      );
    }
    return buffer.toString();
  }

  /// 释放资源
  void dispose() {
    _httpClient.close();
    _cache.clear();
  }
}
