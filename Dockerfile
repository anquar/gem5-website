# 构建阶段：安装编译工具和依赖
FROM ruby:3.0-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Gemfile and Gemfile.lock (if exists) for reproducible builds
COPY Gemfile Gemfile.lock* ./

# Install gems for the correct platform
RUN bundle lock --add-platform x86_64-linux 2>/dev/null || true && \
    bundle install --without development test && \
    bundle clean --force

# 运行阶段：只包含运行时需要的文件
FROM ruby:3.0-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy the application files
COPY . .

# Expose port 4000 for Jekyll
EXPOSE 4000

# Build the site and serve
CMD ["sh", "-c", "bundle exec jekyll serve --host=0.0.0.0 --port=4000"]