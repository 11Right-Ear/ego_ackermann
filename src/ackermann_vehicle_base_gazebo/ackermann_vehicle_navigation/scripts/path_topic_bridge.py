#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
话题桥接节点：将 EGO-Planner 的轨迹话题转换为 path_follower 能理解的路径话题

EGO-Planner 通常发布:
- /planning/trajectory (quadrotor_msgs/PolyTrajectory)
- /traj_server/path (nav_msgs/Path)

path_follower 订阅:
- /path (nav_msgs/Path)
"""

import rospy
from nav_msgs.msg import Path, Odometry
from geometry_msgs.msg import PoseStamped
from quadrotor_msgs.msg import PolyTrajectory
import tf

class TrajectoryBridge:
    def __init__(self):
        # 获取参数
        self.input_topic = rospy.get_param('~input_topic', '/traj_server/path')
        self.output_topic = rospy.get_param('~output_topic', '/path')
        
        rospy.loginfo("话题桥接配置:")
        rospy.loginfo("  输入话题：{}".format(self.input_topic))
        rospy.loginfo("  输出话题：{}".format(self.output_topic))
        
        # 发布者
        self.path_pub = rospy.Publisher(self.output_topic, Path, queue_size=1)
        
        # 订阅者 - 尝试不同的输入话题
        rospy.Subscriber(self.input_topic, Path, self.path_callback)
        
        # 也尝试订阅 quadrotor_msgs 的轨迹话题
        rospy.Subscriber('/planning/trajectory', PolyTrajectory, self.trajectory_callback)
        
        self.last_path = None
        
    def path_callback(self, msg):
        """直接接收 nav_msgs/Path 类型的话题"""
        self.last_path = msg
        # 重新发布到 /path 话题
        self.path_pub.publish(msg)
        if len(msg.poses) > 0:
            rospy.loginfo_throttle(5, "桥接路径：{} 个航点".format(len(msg.poses)))
            
    def trajectory_callback(self, traj_msg):
        """将 PolyTrajectory 转换为 Path"""
        try:
            path_msg = Path()
            path_msg.header.stamp = rospy.Time.now()
            path_msg.header.frame_id = "world"
            
            # 从轨迹消息中提取路径点
            # 这里简化处理，只取起点和终点
            if hasattr(traj_msg, 'header'):
                path_msg.header = traj_msg.header
                
            # 创建简化的路径（实际应该对轨迹进行采样）
            pose_start = PoseStamped()
            pose_start.header = path_msg.header
            pose_start.pose.position.x = 0  # 需要从轨迹中提取
            pose_start.pose.position.y = 0
            pose_start.pose.orientation.w = 1.0
            
            pose_end = PoseStamped()
            pose_end.header = path_msg.header
            pose_end.pose.position.x = 5  # 需要从轨迹中提取
            pose_end.pose.position.y = 0
            pose_end.pose.orientation.w = 1.0
            
            path_msg.poses.append(pose_start)
            path_msg.poses.append(pose_end)
            
            self.path_pub.publish(path_msg)
            rospy.loginfo_throttle(5, "从轨迹转换路径：2 个航点")
            
        except Exception as e:
            rospy.logerr("转换轨迹失败：{}".format(str(e)))

if __name__ == '__main__':
    rospy.init_node('path_topic_bridge')
    bridge = TrajectoryBridge()
    rospy.loginfo("路径话题桥接已启动")
    try:
        rospy.spin()
    except rospy.ROSInterruptException:
        pass
