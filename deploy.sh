#!/bin/bash
# 玩出清北 - 后端部署脚本
# 用法: bash deploy.sh

SERVER="ubuntu@106.54.235.209"
KEY="$HOME/.openclaw/workspace/.openclaw/tmp/ssh_key"
REMOTE_DIR="/home/ubuntu/wanchuqingbei"

echo "📦 1. 打包后端..."
cd "$(dirname "$0")/backend"
mvn clean package -DskipTests -q
if [ $? -ne 0 ]; then
    echo "❌ Maven 打包失败"
    exit 1
fi
echo "✅ 打包完成"

echo "📤 2. 上传到服务器..."
ssh -i "$KEY" "$SERVER" "mkdir -p $REMOTE_DIR"
scp -i "$KEY" target/wanchuqingbei-server-1.0.0.jar "$SERVER:$REMOTE_DIR/"
echo "✅ 上传完成"

echo "🔄 3. 重启服务..."
ssh -i "$KEY" "$SERVER" "
    # 停止旧进程
    pkill -f 'wanchuqingbei-server' 2>/dev/null || true
    sleep 2

    # 启动新进程
    cd $REMOTE_DIR
    nohup java -jar wanchuqingbei-server-1.0.0.jar > app.log 2>&1 &
    echo \$! > app.pid
    sleep 5

    # 检查是否启动成功
    if curl -s http://localhost:8080/api/health | grep -q 'ok'; then
        echo '✅ 后端启动成功'
    else
        echo '❌ 后端启动失败，查看日志:'
        tail -20 app.log
    fi
"
echo "🎉 部署完成"
