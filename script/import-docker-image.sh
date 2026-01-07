#!/bin/bash

# 导入 Docker 镜像脚本
# 用于在离线环境中导入 Docker 镜像

set -e

IMAGE_FILE="${1:-gem5-website-docker-image.tar.gz}"
IMAGE_NAME="gem5-website"
IMAGE_TAG="${2:-latest}"

echo "=========================================="
echo "导入 Docker 镜像"
echo "=========================================="
echo "镜像文件: ${IMAGE_FILE}"
echo ""

# 检查文件是否存在
if [ ! -f "${IMAGE_FILE}" ]; then
    echo "错误: 文件 ${IMAGE_FILE} 不存在"
    exit 1
fi

# 检查文件类型并导入
if [[ "${IMAGE_FILE}" == *.gz ]]; then
    echo "正在解压并导入镜像..."
    gunzip -c "${IMAGE_FILE}" | docker load
else
    echo "正在导入镜像..."
    docker load -i "${IMAGE_FILE}"
fi

# 验证镜像是否导入成功
if docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" > /dev/null 2>&1; then
    echo ""
    echo "=========================================="
    echo "导入成功！"
    echo "=========================================="
    echo "镜像已导入: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo ""
    echo "要运行容器，请使用:"
    echo "  docker run -d -p 4000:4000 --name gem5-website ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "或者使用 Docker Compose:"
    echo "  docker compose up -d"
    echo ""
else
    echo "警告: 无法验证镜像是否导入成功"
    echo "请检查导入的镜像标签:"
    docker images | grep gem5-website || echo "未找到 gem5-website 镜像"
fi
