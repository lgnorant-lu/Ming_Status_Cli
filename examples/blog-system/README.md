# 博客系统示例项目

## 🎯 项目概述

这是一个使用 Ming Status CLI 创建的完整博客系统示例，展示了如何构建一个真实的多模块应用程序。

### 功能特性
- 📝 文章管理（创建、编辑、删除、发布）
- 👤 用户认证和授权
- 💬 评论系统
- 🏷️ 标签和分类
- 🔍 搜索功能
- 📱 响应式设计

### 技术栈
- **后端**: Dart + Shelf
- **前端**: Dart Web + HTML/CSS
- **数据库**: SQLite (开发) / PostgreSQL (生产)
- **认证**: JWT Token
- **部署**: Docker + Docker Compose

## 🏗️ 项目结构

```
blog-system/
├── ming_status.yaml          # 工作空间配置
├── backend/                  # 后端 API 服务
│   ├── lib/
│   │   ├── models/          # 数据模型
│   │   ├── services/        # 业务逻辑
│   │   ├── controllers/     # API 控制器
│   │   ├── middleware/      # 中间件
│   │   └── database/        # 数据库操作
│   ├── bin/
│   │   └── server.dart      # 服务器入口
│   ├── test/
│   └── pubspec.yaml
├── frontend/                 # 前端 Web 应用
│   ├── web/
│   │   ├── index.html
│   │   ├── styles/
│   │   └── scripts/
│   ├── lib/
│   │   ├── components/      # UI 组件
│   │   ├── pages/           # 页面
│   │   ├── services/        # API 服务
│   │   └── utils/           # 工具函数
│   ├── test/
│   └── pubspec.yaml
├── shared/                   # 共享代码
│   ├── lib/
│   │   ├── models/          # 共享数据模型
│   │   ├── constants/       # 常量定义
│   │   └── utils/           # 共享工具
│   ├── test/
│   └── pubspec.yaml
├── docker/                   # Docker 配置
│   ├── Dockerfile.backend
│   ├── Dockerfile.frontend
│   └── docker-compose.yml
├── scripts/                  # 构建和部署脚本
│   ├── build.sh
│   ├── deploy.sh
│   └── test.sh
└── docs/                     # 项目文档
    ├── api.md
    ├── deployment.md
    └── development.md
```

## 🚀 快速开始

### 1. 创建项目

```bash
# 克隆或创建项目
ming init blog-system
cd blog-system

# 配置项目信息
ming config --set project.name="Blog System"
ming config --set project.description="A complete blog system built with Ming CLI"
ming config --set project.author="Your Name"
ming config --set project.license="MIT"
```

### 2. 创建后端模块

```bash
# 创建后端 API 服务
ming create backend --template dart_server \
  --var package_name="blog_backend" \
  --var description="Blog system backend API" \
  --var use_shelf="true" \
  --var use_database="true" \
  --var auth_type="jwt"

# 进入后端目录并安装依赖
cd backend
dart pub get
```

### 3. 创建前端模块

```bash
# 返回根目录
cd ..

# 创建前端 Web 应用
ming create frontend --template dart_web \
  --var package_name="blog_frontend" \
  --var description="Blog system web frontend" \
  --var use_router="true" \
  --var use_components="true"

# 安装前端依赖
cd frontend
dart pub get
```

### 4. 创建共享模块

```bash
# 返回根目录
cd ..

# 创建共享代码模块
ming create shared --template dart_package \
  --var package_name="blog_shared" \
  --var description="Shared models and utilities for blog system"

# 安装共享模块依赖
cd shared
dart pub get
```

## 📝 核心代码示例

### 共享数据模型

**shared/lib/models/post.dart:**
```dart
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable()
class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool published;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.published = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);

  Post copyWith({
    String? title,
    String? content,
    List<String>? tags,
    bool? published,
  }) {
    return Post(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      published: published ?? this.published,
    );
  }
}
```

### 后端 API 控制器

**backend/lib/controllers/posts_controller.dart:**
```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/post_service.dart';
import '../middleware/auth_middleware.dart';

class PostsController {
  final PostService _postService;

  PostsController(this._postService);

  Router get router {
    final router = Router();

    // 公开路由
    router.get('/posts', _getPosts);
    router.get('/posts/<id>', _getPost);

    // 需要认证的路由
    router.post('/posts', Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(_createPost));
    
    router.put('/posts/<id>', Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(_updatePost));
    
    router.delete('/posts/<id>', Pipeline()
        .addMiddleware(authMiddleware)
        .addHandler(_deletePost));

    return router;
  }

  Future<Response> _getPosts(Request request) async {
    try {
      final posts = await _postService.getAllPosts();
      return Response.ok(
        jsonEncode(posts.map((p) => p.toJson()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch posts'}),
      );
    }
  }

  Future<Response> _createPost(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      final post = await _postService.createPost(
        title: data['title'],
        content: data['content'],
        authorId: request.context['userId'] as String,
        tags: List<String>.from(data['tags'] ?? []),
      );

      return Response.ok(
        jsonEncode(post.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Invalid request data'}),
      );
    }
  }

  // 其他方法...
}
```

### 前端组件

**frontend/lib/components/post_card.dart:**
```dart
import 'dart:html' as html;
import 'package:blog_shared/models/post.dart';

class PostCard {
  final Post post;

  PostCard(this.post);

  html.Element render() {
    final card = html.DivElement()
      ..className = 'post-card'
      ..innerHTML = '''
        <div class="post-header">
          <h2 class="post-title">${_escapeHtml(post.title)}</h2>
          <div class="post-meta">
            <span class="post-date">${_formatDate(post.createdAt)}</span>
            <div class="post-tags">
              ${post.tags.map((tag) => '<span class="tag">$tag</span>').join('')}
            </div>
          </div>
        </div>
        <div class="post-content">
          ${_truncateContent(post.content, 200)}
        </div>
        <div class="post-actions">
          <button class="btn btn-primary" data-post-id="${post.id}">
            阅读更多
          </button>
        </div>
      ''';

    // 添加事件监听
    final readMoreBtn = card.querySelector('.btn-primary') as html.ButtonElement;
    readMoreBtn.onClick.listen((_) => _navigateToPost(post.id));

    return card;
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  void _navigateToPost(String postId) {
    html.window.location.href = '/posts/$postId';
  }
}
```

## 🧪 测试

### 运行所有测试
```bash
# 在项目根目录
ming test

# 或者分别测试各模块
cd backend && dart test
cd ../frontend && dart test
cd ../shared && dart test
```

### 集成测试
```bash
# 启动后端服务
cd backend
dart run bin/server.dart &

# 运行前端开发服务器
cd ../frontend
dart run build_runner serve &

# 运行集成测试
cd ..
dart test test/integration/
```

## 🚀 部署

### 使用 Docker

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f
```

### 手动部署

```bash
# 构建后端
cd backend
dart compile exe bin/server.dart -o blog_server

# 构建前端
cd ../frontend
dart run build_runner build --release

# 部署到服务器
scp blog_server user@server:/opt/blog/
scp -r build/ user@server:/var/www/blog/
```

## 📊 性能优化

### 后端优化
- 数据库连接池
- Redis 缓存
- API 响应压缩
- 请求限流

### 前端优化
- 代码分割
- 懒加载
- 图片优化
- CDN 加速

## 🔧 开发工具

### 推荐的 VS Code 扩展
```json
{
  "recommendations": [
    "dart-code.dart-code",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "ms-vscode-remote.remote-containers"
  ]
}
```

### 开发脚本
```bash
# 启动开发环境
./scripts/dev.sh

# 运行测试
./scripts/test.sh

# 构建生产版本
./scripts/build.sh

# 部署到生产环境
./scripts/deploy.sh
```

## 📚 学习资源

- [Dart 服务器开发](https://dart.dev/server)
- [Shelf 框架文档](https://pub.dev/packages/shelf)
- [Dart Web 开发](https://dart.dev/web)
- [Docker 部署指南](https://docs.docker.com/)

## 🤝 贡献

欢迎贡献代码和改进建议！请查看 [贡献指南](../../CONTRIBUTING.md)。

---

**这个示例展示了 Ming CLI 在实际项目中的强大能力！** 🚀

通过这个博客系统，你可以学习到完整的全栈开发流程和最佳实践。

*示例版本: 1.0.0 | 最后更新: 2025-07-08*
