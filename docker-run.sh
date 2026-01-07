#!/bin/bash

# gem5 网站的 Docker 管理脚本

set -e

echo "gem5 网站 - Docker 管理脚本"
echo "========================================"

if [ -z "$1" ]; then
    echo "用法: $0 {dev|prod|build-dev|build-prod|clean}"
    echo ""
    echo "命令:"
    echo "  dev        - 启动开发服务器（支持热重载）"
    echo "  prod       - 启动生产服务器"
    echo "  build-dev  - 构建开发镜像"
    echo "  build-prod - 构建生产镜像"
    echo "  clean      - 停止并删除所有容器"
    echo ""
    exit 1
fi

case $1 in
    dev)
        echo "正在启动开发服务器..."
        docker compose up --build
        ;;
    prod)
        echo "正在启动生产服务器..."
        docker compose -f docker-compose.prod.yml up --build
        ;;
    build-dev)
        echo "正在构建开发镜像..."
        docker compose build
        ;;
    build-prod)
        echo "正在构建生产镜像..."
        docker compose -f docker-compose.prod.yml build
        ;;
    clean)
        echo "正在停止并删除开发容器..."
        docker compose down -v
        echo "正在停止并删除生产容器..."
        docker compose -f docker-compose.prod.yml down -v
        ;;
    *)
        echo "无效命令: $1"
        echo "用法: $0 {dev|prod|build-dev|build-prod|clean}"
        exit 1
        ;;
esac