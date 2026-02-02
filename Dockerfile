# 第一阶段：构建环境
FROM ruby:3.0-slim AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 复制 Gemfile 和 Gemfile.lock
COPY Gemfile Gemfile.lock* ./

# 安装 Gems
RUN bundle lock --add-platform x86_64-linux 2>/dev/null || true && \
    bundle install --without development test && \
    bundle clean --force

# 复制源代码
COPY . .

# 构建静态网站
# 使用生产环境配置构建，输出到默认的 _site 目录
ENV JEKYLL_ENV=production
RUN bundle exec jekyll build --config _config.yml

# 第二阶段：运行环境 (Nginx)
# 使用极小的 nginx:alpine 镜像，仅用于提供静态文件服务
FROM nginx:alpine

# 从构建阶段复制生成的静态文件到 Nginx 默认目录
COPY --from=builder /app/_site /usr/share/nginx/html

# 暴露 80 端口 (原作为 4000，生产环境静态服务通常为 80)
EXPOSE 80

# 启动 Nginx
CMD ["nginx", "-g", "daemon off;"]
