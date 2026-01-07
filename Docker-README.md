# gem5 网站的 Docker 部署

本仓库包含 Docker 配置，可轻松在容器化环境中运行 gem5 网站。

## 前置要求

- Docker Engine（版本 20.10 或更高）
- Docker Compose（版本 2.0 或更高）

## 快速开始

### 使用 Docker Compose（推荐）

```bash
docker compose up --build
```

访问网站：http://localhost:4000

### 直接使用 Docker

1. 构建镜像：
   ```bash
   docker build -t gem5-website .
   ```

2. 运行容器：
   ```bash
   docker run -p 4000:4000 -v $(pwd):/app gem5-website
   ```

## 配置

- 使用 Jekyll 开发服务器，支持实时重载
- 挂载当前目录以实现实时更新
- 运行在端口 4000

## 包含的文件

- `Dockerfile`: Docker 配置
- `docker-compose.yml`: Docker Compose 配置文件
- `.dockerignore`: Docker 构建时要排除的文件

## 离线部署

### 导出 Docker 镜像

在有网络连接的环境中，构建并导出 Docker 镜像：

1. **构建镜像**：
   ```bash
   docker build -t gem5-website:latest .
   ```

2. **导出镜像**（使用脚本）：
   ```bash
   bash script/export-docker-image.sh [标签] [输出文件名]
   ```

   示例：
   ```bash
   # 使用默认标签 latest 和默认文件名
   bash script/export-docker-image.sh

   # 指定标签和文件名
   bash script/export-docker-image.sh v1.0.0 gem5-website-v1.0.0.tar.gz
   ```

   或者手动导出：
   ```bash
   docker save gem5-website:latest | gzip > gem5-website-docker-image.tar.gz
   ```

3. **传输镜像文件**：
   将生成的 `.tar.gz` 文件传输到离线环境（使用 USB、网络传输等方式）

### 导入并运行镜像（离线环境）

在离线环境中：

1. **导入镜像**（使用脚本）：
   ```bash
   bash script/import-docker-image.sh [镜像文件] [标签]
   ```

   示例：
   ```bash
   # 使用默认文件名和标签
   bash script/import-docker-image.sh

   # 指定文件名和标签
   bash script/import-docker-image.sh gem5-website-v1.0.0.tar.gz v1.0.0
   ```

   或者手动导入：
   ```bash
   gunzip -c gem5-website-docker-image.tar.gz | docker load
   ```

2. **运行容器**：
   ```bash
   docker run -d -p 4000:4000 --name gem5-website gem5-website:latest
   ```

   或者使用 Docker Compose（需要先修改 `docker-compose.yml` 中的镜像名称）：
   ```bash
   docker compose up -d
   ```

3. **访问网站**：
   打开浏览器访问 http://localhost:4000

### 离线部署注意事项

- **镜像大小**：导出的镜像文件可能较大（通常几百 MB 到几 GB），请确保有足够的存储空间
- **平台兼容性**：确保导出和导入环境使用相同的 CPU 架构（如 x86_64）
- **依赖完整性**：Dockerfile 已优化，确保所有依赖（包括 Ruby gems 和系统包）都包含在镜像中
- **版本锁定**：建议在构建前生成 `Gemfile.lock` 以确保依赖版本一致性：
  ```bash
  bundle install
  ```

## 开发

docker-compose 配置将当前目录挂载到容器中的 `/app`，允许在开发过程中实时重载更改。`_site` 目录被排除在挂载之外，以防止冲突。
