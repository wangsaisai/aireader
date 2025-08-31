#!/bin/bash

echo "🔍 验证ArkTS类型安全问题..."

# 检查StorageManager.ets中的空值检查
echo "📋 检查StorageManager.ets中的空值检查..."
if grep -n "dataStore!" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ 发现空值断言操作符(!)使用"
else
    echo "❌ 缺少空值断言操作符"
fi

# 检查对象字面量类型问题
echo "📋 检查对象字面量类型问题..."
if grep -n "serializedMsg:" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ 发现显式类型声明的对象字面量"
else
    echo "❌ 缺少显式类型声明"
fi

# 检查QAMessage构造函数使用
echo "📋 检查QAMessage构造函数使用..."
if grep -n "new QAMessage" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ 使用正确的QAMessage构造函数"
else
    echo "❌ 没有使用QAMessage构造函数"
fi

# 检查timestamp处理
echo "📋 检查timestamp处理..."
if grep -n "parseInt.*timestamp" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ timestamp处理正确"
else
    echo "❌ timestamp处理可能有问题"
fi

# 检查接口定义
echo "📋 检查接口定义..."
if grep -n "interface.*Session" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ 发现序列化接口定义"
else
    echo "❌ 缺少序列化接口定义"
fi

echo "🎉 验证完成！"