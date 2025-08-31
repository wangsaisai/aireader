#!/bin/bash

echo "🔍 检查ArkTS语法问题..."

# 检查StorageManager.ets中的问题
echo "📋 检查StorageManager.ets..."
if grep -n "any" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "❌ 发现any类型使用"
else
    echo "✅ 没有发现any类型使用"
fi

if grep -n "@kit.CoreServiceKit" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "❌ 发现错误的导入路径"
else
    echo "✅ 导入路径正确"
fi

# 检查ClientSessionManager.ets中的问题
echo "📋 检查ClientSessionManager.ets..."
if grep -n "getContext(this)" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/ClientSessionManager.ets; then
    echo "⚠️  发现getContext(this)使用，需要处理"
else
    echo "✅ Context处理正确"
fi

# 检查Index.ets中的异步调用
echo "📋 检查Index.ets中的异步调用..."
if grep -n "await.*createSession\|await.*switchSession\|await.*deleteSession" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/pages/Index.ets; then
    echo "✅ 异步调用正确"
else
    echo "❌ 异步调用可能有问题"
fi

echo "🎉 检查完成！"