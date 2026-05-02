#include <chrono>
#include <cmath>
#include <memory>
#include <optional>

#include "geometry_msgs/msg/twist.hpp"
#include "nav_msgs/msg/odometry.hpp"
#include "rclcpp/rclcpp.hpp"

using namespace std::chrono_literals;

// TODO:
// 1. Add a zig pkg into the repo (this meant adding to flake and cmake)
// 2. Build the zig pkg as a library
// 3. Include this library from the cmakelist
// 4. Reference it here

class DemoController : public rclcpp::Node {
public:
  DemoController()
      : rclcpp::Node("demo_controller"), last_log_time_(0, 0, RCL_ROS_TIME) {
    cmd_pub_ = this->create_publisher<geometry_msgs::msg::Twist>(
        "/model/minibot/cmd_vel", 10);
    odom_sub_ = this->create_subscription<nav_msgs::msg::Odometry>(
        "/model/minibot/odometry", 10,
        [this](nav_msgs::msg::Odometry::SharedPtr msg) {
          this->handle_odom(msg);
        });

    timer_ = this->create_wall_timer(100ms, [this]() { this->tick(); });

    RCLCPP_INFO(get_logger(), "Publishing Twist to /model/minibot/cmd_vel and "
                              "listening on /model/minibot/odometry");
  }

private:
  void handle_odom(const nav_msgs::msg::Odometry::SharedPtr msg) {
    last_odom_ = *msg;
    have_odom_ = true;
  }

  void tick() {
    const auto now = this->now();
    if (now.nanoseconds() == 0) {
      return;
    }

    if (!start_time_) {
      start_time_ = now;
    }

    const double elapsed = (now - *start_time_).seconds();

    geometry_msgs::msg::Twist cmd;
    if (elapsed < 4.0) {
      cmd.linear.x = 0.6;
    } else if (elapsed < 8.0) {
      cmd.angular.z = 0.6;
    } else if (elapsed < 12.0) {
      cmd.linear.x = 0.3;
      cmd.angular.z = -0.3;
    }

    cmd_pub_->publish(cmd);

    if (have_odom_ && (now - last_log_time_).seconds() >= 1.0) {
      const auto &pose = last_odom_.pose.pose.position;
      const auto &twist = last_odom_.twist.twist;
      RCLCPP_INFO(get_logger(),
                  "sim_t=%.1fs pose=(%.2f, %.2f) v=(%.2f m/s, %.2f rad/s)",
                  elapsed, pose.x, pose.y, twist.linear.x, twist.angular.z);
      last_log_time_ = now;
    }
  }

  rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_pub_;
  rclcpp::Subscription<nav_msgs::msg::Odometry>::SharedPtr odom_sub_;
  rclcpp::TimerBase::SharedPtr timer_;

  std::optional<rclcpp::Time> start_time_;
  rclcpp::Time last_log_time_;
  nav_msgs::msg::Odometry last_odom_;
  bool have_odom_{false};
};

int main(int argc, char **argv) {
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<DemoController>());
  rclcpp::shutdown();
  return 0;
}
