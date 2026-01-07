#!/bin/bash

# 导出 Docker 镜像脚本
# 用于创建可离线部署的 Docker 镜像

set -e

IMAGE_NAME="gem5-website"
IMAGE_TAG="${1:-latest}"
OUTPUT_FILE="${2:-gem5-website-docker-image.tar.gz}"

echo "=========================================="
echo "导出 Docker 镜像"
echo "=========================================="
echo "镜像名称: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "输出文件: ${OUTPUT_FILE}"
echo ""

# 检查镜像是否存在
if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" > /dev/null 2>&1; then
    echo "错误: 镜像 ${IMAGE_NAME}:${IMAGE_TAG} 不存在"
    echo "请先构建镜像: docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
    exit 1
fi

# 导出镜像为 tar 文件
echo "正在导出镜像..."
TAR_FILE="${OUTPUT_FILE%.gz}"
docker save "${IMAGE_NAME}:${IMAGE_TAG}" -o "${TAR_FILE}"

# 压缩 tar 文件
echo "正在压缩镜像文件..."
gzip -f "${TAR_FILE}"

# 计算文件大小
FILE_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)

echo ""
echo "=========================================="
echo "导出完成！"
echo "=========================================="
echo "镜像文件: ${OUTPUT_FILE}"
echo "文件大小: ${FILE_SIZE}"
echo ""
echo "要导入镜像，请使用:"
echo "  gunzip -c ${OUTPUT_FILE} | docker load"
echo "或者使用脚本:"
echo "  bash script/import-docker-image.sh ${OUTPUT_FILE}"
echo ""
