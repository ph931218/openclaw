#!/bin/bash
# Avast One 一键彻底清理脚本
# 用法：sudo bash avast_cleanup.sh

set -e

echo "🔪 正在停止所有 Avast 进程..."
pkill -9 -f "com.avast" 2>/dev/null || true
pkill -9 -f "Avast" 2>/dev/null || true
sleep 1

echo "📦 正在移除应用..."
rm -rf /Applications/Avast.app
rm -rf /Applications/com.avast.av.uninstaller.app

echo "🔧 正在移除 LaunchDaemons..."
rm -f /Library/LaunchDaemons/com.avast.init.plist
rm -f /Library/LaunchDaemons/com.avast.update.plist

echo "🔧 正在移除 LaunchAgents..."
rm -f /Library/LaunchAgents/com.avast.userinit.plist

echo "🗑️ 正在清理系统 Application Support..."
rm -rf /Library/Application\ Support/Avast

echo "🗑️ 正在清理用户 Application Support..."
rm -rf ~/Library/Application\ Support/Avast

echo "🗑️ 正在清理缓存..."
rm -rf ~/Library/Caches/Avast
rm -rf ~/Library/Caches/com.avast.AAFM

echo "🗑️ 正在清理偏好设置..."
rm -f ~/Library/Preferences/com.avast.AAFM.plist
rm -f /Library/Preferences/com.avast.* 2>/dev/null || true

echo "🗑️ 正在清理 Group Containers..."
rm -rf ~/Library/Group\ Containers/6H4HRTU5E3.com.avast.AAFM

echo "🗑️ 正在清理日志..."
rm -rf ~/Library/Logs/Avast

echo "🔧 正在移除系统扩展..."
# 移除 Avast 系统扩展
systemextensionsctl uninstall 5413549B-762F-4D5F-87A0-164AEA6D5FD4 com.avast.Antivirus.SystemExtension 2>/dev/null || true

echo "✅ Avast 清理完成！建议重启一次 Mac 确保所有残留被彻底清除。"
