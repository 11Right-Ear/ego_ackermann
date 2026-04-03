#!/bin/bash

echo "========================================="
echo "阿克曼车辆运动调试脚本"
echo "========================================="
echo ""

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

source /home/kkcqh/WTF/ackermann_ego_planner/devel/setup.bash

echo -e "${YELLOW}步骤 1: 检查 ROS Master...${NC}"
if roscore 2>&1 | head -1 | grep -q "started"; then
    echo -e "${GREEN}✓ ROS Master 已启动${NC}"
else
    echo -e "${RED}✗ ROS Master 未启动，请先运行 roscore${NC}"
    exit 1
fi

sleep 2

echo ""
echo -e "${YELLOW}步骤 2: 检查必要的话题...${NC}"
echo "等待话题注册..."
sleep 3

echo ""
echo "检查 /cmd_vel 话题:"
rostopic info /cmd_vel 2>/dev/null || echo -e "${RED}  ✗ /cmd_vel 不存在${NC}"

echo ""
echo "检查 /ackermann_cmd 话题:"
rostopic info /ackermann_cmd 2>/dev/null || echo -e "${RED}  ✗ /ackermann_cmd 不存在${NC}"

echo ""
echo "检查 /path 话题:"
rostopic info /path 2>/dev/null || echo -e "${RED}  ✗ /path 不存在${NC}"

echo ""
echo "检查 /odom 话题:"
rostopic info /odom 2>/dev/null || echo -e "${RED}  ✗ /odom 不存在${NC}"

echo ""
echo -e "${YELLOW}步骤 3: 检查运行的节点...${NC}"
rosnode list 2>/dev/null | grep -E "path_follower|cmd_vel|tf_publisher" || echo -e "${RED}  未找到关键节点${NC}"

echo ""
echo -e "${YELLOW}步骤 4: 测试手动控制...${NC}"
echo "尝试发布速度指令到 /cmd_vel..."
rostopic pub -r 5 /cmd_vel geometry_msgs/Twist '{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}' &
PUB_PID=$!
sleep 3
kill $PUB_PID 2>/dev/null

echo ""
echo "检查 /ackermann_cmd 是否有响应:"
rostopic echo /ackermann_cmd --noarr -n 1 2>/dev/null || echo -e "${RED}  ✗ 没有接收到 ackermann_cmd${NC}"

echo ""
echo "========================================="
echo -e "${YELLOW}调试建议:${NC}"
echo "1. 确保按顺序启动所有节点:"
echo "   - Gazebo 仿真环境"
echo "   - path_follower.launch"  
echo "   - EGO-Planner (run_in_sim.launch)"
echo ""
echo "2. 在 RViz 中使用 '2D Nav Goal' 发布目标点"
echo ""
echo "3. 检查以下话题连接:"
echo "   EGO-Planner -> /path -> path_follower"
echo "   path_follower -> /cmd_vel -> cmd_vel_to_ackermann_drive"
echo "   cmd_vel_to_ackermann_drive -> /ackermann_cmd -> Gazebo"
echo "========================================="

