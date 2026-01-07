# gem5 网站的 Docker 部署

本仓库包含 Docker 配置，可轻松在容器化环境中部署 gem5 网站。

## 前置要求

- Docker Engine（版本 20.10 或更高）
- Docker Compose（版本 2.0 或更高）

## 快速开始

### 使用 Docker Compose（推荐）

开发环境：
```bash
docker compose up --build
```

访问网站：http://localhost:4000

生产环境：
```bash
docker compose -f docker-compose.prod.yml up --build
```

访问网站：http://localhost

### 使用辅助脚本

仓库包含一个用于常见操作的辅助脚本：

```bash
# 开发模式，支持实时重载
./docker-run.sh dev

# 生产模式
./docker-run.sh prod

# 构建开发镜像
./docker-run.sh build-dev

# 构建生产镜像
./docker-run.sh build-prod

# 清理容器
./docker-run.sh clean
```

### 直接使用 Docker

开发环境：
1. 构建镜像：
   ```bash
   docker build -t gem5-website .
   ```

2. 运行容器：
   ```bash
   docker run -p 4000:4000 -v $(pwd):/app gem5-website
   ```

生产环境：
1. 构建生产镜像：
   ```bash
   docker build -t gem5-website-prod -f Dockerfile.prod .
   ```

2. 运行容器：
   ```bash
   docker run -p 80:80 gem5-website-prod
   ```

## 配置

### 开发环境设置
- 使用 Jekyll 开发服务器，支持实时重载
- 挂载当前目录以实现实时更新
- 同时使用 `_config.yml` 和 `_config_dev.yml` 文件
- 运行在端口 4000

### 生产环境设置
- 使用 Jekyll 构建静态网站
- 使用 Nginx 提供网站服务
- 针对性能进行优化
- 运行在端口 80（或映射的端口）

## 包含的文件

- `Dockerfile`: 开发环境的 Docker 配置
- `Dockerfile.prod`: 生产环境的 Docker 配置
- `docker-compose.yml`: 开发环境的 compose 文件
- `docker-compose.prod.yml`: 生产环境的 compose 文件
- `nginx.conf`: 生产环境的 Nginx 配置
- `.dockerignore`: Docker 构建时要排除的文件
- `docker-run.sh`: 常见操作的辅助脚本

## 开发

开发环境的 docker-compose 配置将当前目录挂载到容器中的 `/app`，允许在开发过程中实时重载更改。`_site` 目录被排除在挂载之外，以防止冲突。

## 生产构建

生产环境设置使用多阶段构建：
1. 第一阶段：使用 Ruby 构建 Jekyll 网站
2. 第二阶段：使用 Nginx 提供静态网站服务

这将创建一个优化的、轻量级的生产镜像。
