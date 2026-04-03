# 阿克曼车辆不移动问题解决方案

## 问题诊断

当在 RViz 中使用 '2D Nav Goal' 发布目标点后车辆不移动，通常有以下几个原因：

### 1. 关键节点未启动
检查以下节点是否都在运行：
- ✅ Gazebo 仿真环境
- ✅ tf_odom_publisher (里程计和 TF 发布)
- ✅ path_follower (路径跟随器)
- ✅ cmd_vel_to_ackermann_drive (速度转换)
- ✅ EGO-Planner 规划器

### 2. 话题名称不匹配
这是最常见的问题！数据流应该是：
```
EGO-Planner → /path (或 /planning/trajectory) 
→ path_follower 
→ /cmd_vel 
→ cmd_vel_to_ackermann_drive 
→ /ackermann_cmd 
→ Gazebo 控制器
```

### 3. TF 坐标变换问题
确保 TF 树正确：`world → odom → ackermann_vehicle → base_link`

## 快速修复步骤

### 步骤 1: 使用修复后的启动文件

我们已经更新了 `path_follower.launch`，请重新启动：

```bash
# 终端 1: 启动 Gazebo 仿真
source devel/setup.bash
roslaunch ackermann_vehicle_gazebo ackermann_vehicle_base.launch

# 终端 2: 启动导航节点（使用修复后的版本）
source devel/setup.bash
roslaunch ackermann_vehicle_navigation path_follower.launch

# 终端 3: 启动 EGO-Planner
source devel/setup.bash
roslaunch ego_planner run_in_sim.launch 2>/dev/null
```

### 步骤 2: 检查话题连接

在新终端中运行：
```bash
# 查看所有话题
rostopic list | grep -E "cmd_vel|ackermann|path|odom"

# 检查每个话题的发布者和订阅者
rostopic info /path
rostopic info /cmd_vel
rostopic info /ackermann_cmd
rostopic info /odom
```

**期望结果：**
- `/path`: 1 个发布者 (EGO-Planner), 1 个订阅者 (path_follower)
- `/cmd_vel`: 1 个发布者 (path_follower), 1 个订阅者 (cmd_vel_converter)
- `/ackermann_cmd`: 1 个发布者 (cmd_vel_converter), 1 个订阅者 (Gazebo 控制器)
- `/odom`: 1 个发布者 (tf_publisher), 多个订阅者

### 步骤 3: 手动测试车辆控制

如果话题都正确但车还是不动，尝试手动控制：

```bash
# 直接发布速度指令测试
rostopic pub -r 10 /cmd_vel geometry_msgs/Twist \
  '{linear: {x: 0.5, y: 0.0, z: 0.0}, angular: {x: 0.0, y: 0.0, z: 0.0}}'
```

如果车动了，说明 Gazebo 控制器正常，问题在 path_follower 或 EGO-Planner。

### 步骤 4: 使用话题桥接（如果需要）

如果 EGO-Planner 发布的话题不是 `/path`，使用话题桥接：

```bash
# 添加桥接节点到启动文件
rosrun ackermann_vehicle_navigation path_topic_bridge.py
```

或者修改 `path_follower.launch` 添加桥接节点。

### 步骤 5: 查看详细日志

```bash
# 查看 path_follower 节点的日志
rosnode list | grep path_follower
rosrun rqt_console rqt_console  # 或使用 rxconsole

# 或者直接看终端输出
# path_follower 应该打印 "vx: xxx" 的速度值
```

## 常见问题和解决方案

### 问题 A: 没有接收到路径
**症状**: path_follower 节点没有打印 "Received path with X poses"

**解决方案**:
1. 检查 EGO-Planner 是否正常启动
2. 查看 EGO-Planner 实际发布的话题：`rostopic list | grep traj`
3. 如果是 `/traj_server/path`，需要修改 path_follower 的订阅话题或添加桥接

### 问题 B: 收到路径但车不动
**症状**: path_follower 收到路径，但没有发布速度指令

**可能原因**:
1. 没有接收到里程计 (`/odom`)
2. TF 变换不正确
3. 路径点在车辆当前位置之外

**解决方案**:
```bash
# 检查里程计
rostopic echo /odom | head -20

# 检查 TF
rosrun tf view_frames  # 生成 frames.pdf 查看 TF 树
evince frames.pdf
```

### 问题 C: 发布了速度但车不动
**症状**: `/cmd_vel` 有数据，但车不动

**可能原因**:
1. cmd_vel_to_ackermann_drive 节点未运行
2. Gazebo 控制器订阅的是其他话题

**解决方案**:
```bash
# 检查转换器节点
rosnode list | grep cmd_vel

# 检查 Gazebo 控制器的订阅
rostopic info /ackermann_cmd
```

## 调试工具

### 运行完整诊断脚本
```bash
./debug_vehicle_motion.sh
```

### 使用 RQT 查看
```bash
# 查看节点图
rqt_graph

# 查看话题数据
rqt_plot '/cmd_vel/linear/x' '/cmd_vel/angular/z'
```

## 已修复的代码问题

在 `path_follower.py` 中修复了以下问题：
1. ✅ 将 `if seq is 0:` 改为 `if seq == 0:` (Python 比较运算符)
2. ✅ 减少了日志输出频率 (避免刷屏)
3. ✅ 添加了路径接收确认日志

在 `path_follower.launch` 中添加了：
1. ✅ path_follower 节点（之前被注释掉）
2. ✅ cmd_vel_to_ackermann_drive 节点

## 联系和支持

如果以上步骤都不能解决问题，请提供以下信息：
1. `rostopic list` 的完整输出
2. `rosnode list` 的完整输出  
3. path_follower 节点的日志输出
4. RViz 中的截图（显示路径和车辆位置）
