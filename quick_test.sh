#!/bin/bash

echo "========================================="
echo "快速测试：阿克曼车辆控制"
echo "========================================="

source devel/setup.bash

# 检查 ROS 是否运行
if ! roscore 2>&1 | grep -q "started"; then
    echo "⚠ 检测到 roscore 可能未运行，请确保已启动 roscore"
fi

echo ""
echo "=== 当前话题状态 ==="
echo ""
echo "1. /path 话题:"
rostopic info /path 2>/dev/null || echo "   ✗ 未找到 /path 话题"

echo ""
echo "2. /cmd_vel 话题:"
rostopic info /cmd_vel 2>/dev/null || echo "   ✗ 未找到 /cmd_vel 话题"

echo ""
echo "3. /ackermann_cmd 话题:"
rostopic info /ackermann_cmd 2>/dev/null || echo "   ✗ 未找到 /ackermann_cmd 话题"

echo ""
echo "4. /odom 话题:"
rostopic info /odom 2>/dev/null || echo "   ✗ 未找到 /odom 话题"

echo ""
echo "=== 运行的节点 ==="
rosnode list 2>/dev/null | grep -E "path_follower|cmd_vel|tf_|gazebo|planning" || echo "未找到相关节点"

echo ""
echo "=== 手动控制测试 ==="
echo "尝试发送速度指令..."
(
    rostopic pub -r 5 /cmd_vel geometry_msgs/Twist \
      '{linear: {x: 0.3, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}' &
    sleep 3
) &>/dev/null

echo "等待 3 秒观察 Gazebo 中的车辆..."
sleep 3

echo ""
echo "检查 /ackermann_cmd 是否有数据:"
timeout 2 rostopic echo /ackermann_cmd --noarr -n 1 2>/dev/null || echo "✗ 无数据"

echo ""
echo "========================================="
echo "下一步建议:"
echo "1. 如果所有话题都是空的，请重新启动所有节点"
echo "2. 阅读 SOLUTION_GUIDE.md 获取详细诊断步骤"
echo "3. 运行 ./debug_vehicle_motion.sh 获取完整诊断"
echo "========================================="
