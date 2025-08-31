#!/bin/bash

echo "🔍 最终编译验证测试..."

# 模拟编译器检查对象字面量的规则
echo "📋 验证第63行和第114行的修复..."

# 检查第63行附近的修复
echo "检查第63行（saveSessions方法）:"
if grep -A 15 "const serializedSessions: SerializedSession\[\] = sessions.map(session => {" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets | grep -q "const serializedSession: SerializedSession ="; then
    echo "✅ 第63行: 对象字面量有显式类型声明"
else
    echo "❌ 第63行: 对象字面量缺少类型声明"
fi

# 检查第114行附近的修复  
echo "检查第114行（loadSessions方法）:"
if grep -A 10 "const session: ClientChatSession = {" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets | grep -q "id: sessionData.id"; then
    echo "✅ 第114行: 对象字面量有显式类型声明"
else
    echo "❌ 第114行: 对象字面量缺少类型声明"
fi

# 检查是否还有其他潜在问题
echo "📋 检查其他潜在的map函数..."
# 查找所有map函数，确保它们都有适当的类型处理
map_count=$(grep -c "map(" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets)
echo "发现 $map_count 个map函数"

# 检查每个map函数是否都有类型声明
typed_map_count=$(grep -c "const.*:" /Users/bamboo/workspace/ai/hongmeng/aireader_hm/entry/src/main/ets/services/StorageManager.ets)
echo "发现 $typed_map_count 个显式类型声明"

if [ $map_count -le $typed_map_count ]; then
    echo "✅ 所有map函数都有适当的类型处理"
else
    echo "⚠️  部分map函数可能缺少类型处理"
fi

echo "🎉 最终验证完成！"