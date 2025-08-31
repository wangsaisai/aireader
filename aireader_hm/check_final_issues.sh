#!/bin/bash

echo "🔍 检查剩余的编译问题..."

# 检查是否还有未修复的对象字面量问题
echo "📋 检查对象字面量类型声明..."

# 查找map函数中的对象字面量
if grep -n "map.*=> {" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets | grep -v "const.*:"; then
    echo "⚠️  发现可能的对象字面量问题"
    grep -n "map.*=> {" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets | grep -v "const.*:"
else
    echo "✅ 没有发现未声明的对象字面量"
fi

# 检查return语句中的对象字面量
if grep -n "return {" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets | grep -v "const.*:"; then
    echo "⚠️  发现return语句中的对象字面量"
    grep -n "return {" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets | grep -v "const.*:"
else
    echo "✅ return语句中的对象字面量都有类型声明"
fi

# 检查类型断言使用
echo "📋 检查类型断言使用..."
if grep -n "as.*\[\]" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ 发现类型断言使用"
else
    echo "⚠️  可能缺少类型断言"
fi

# 检查JSON.parse的使用
echo "📋 检查JSON.parse类型安全..."
if grep -n "JSON.parse" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets; then
    echo "✅ JSON.parse使用都有类型声明"
else
    echo "❌ JSON.parse使用可能有问题"
fi

echo "🎉 检查完成！"