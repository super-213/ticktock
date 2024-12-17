import SwiftUI
import UIKit
import AVFoundation

struct TimerView: View {
    @State private var selectedTime: Double = 0
    @State private var timerActive = false
    @State private var remainingTime: Double = 0
    @State private var timer: Timer? = nil
    @State private var startAngle: Double = 0
    @State private var selectedUnit: TimeUnit = .second
    @State private var audioPlayer: AVAudioPlayer?  // 音频播放器
    @State private var isAlarmPlaying = false      // 标记来追踪警报状态
    @State private var alarmTimer: Timer?
    
    
    // 开始按钮部分
    var buttonContent: some View {
        Circle()
            .fill(timerActive ? Color.gray : (isAlarmPlaying ? Color.red : Color.green))
            .frame(width: 120, height: 120)
            .overlay(
                Text(isAlarmPlaying ? "停止" : "开始")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            )
    }
    
    // 计时器结束处理
    // 在 handleTimerComplete 中使用系统声音
    func handleTimerComplete() {
        timer?.invalidate()
        timerActive = false
        isAlarmPlaying = true
        
        // 创建一个重复播放系统声音的计时器
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(1005)
        }
        
        impactFeedback.impactOccurred(intensity: 1.0)
    }
    
    // 停止警报的方法
    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
        isAlarmPlaying = false
    }
    
    enum TimeUnit {
        case hour, minute, second
        
        var increment: Double {
            switch self {
            case .hour: return 3600  //可调的时间增量
            case .minute: return 60
            case .second: return 1
            }
        }
    }
    
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var formattedTime: String {
        let hours = Int(selectedTime) / 3600
        let minutes = (Int(selectedTime) % 3600) / 60
        let seconds = Int(selectedTime) % 60
        
        var result = ""
        if hours > 0 {
            result += "\(hours)时"
        }
        if minutes > 0 || hours > 0 {
            result += String(format: "%02d分", minutes)
        }
        result += String(format: "%02d秒", seconds)
        
        return result
    }
    
    // 添加总的最大时间限制
    let maxTotalTime: Double = 24 * 3600 // 24小时
    
    var displayTime: String {
        if timerActive {
            let hours = Int(remainingTime) / 3600
            let minutes = (Int(remainingTime) % 3600) / 60
            let seconds = Int(remainingTime) % 60
            
            var result = ""
            if hours > 0 {
                result += "\(hours)时"
            }
            if minutes > 0 || hours > 0 {
                result += String(format: "%02d分", minutes)
            }
            result += String(format: "%02d秒", seconds)
            
            return result
        } else {
            return formattedTime
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // 顶部时间显示
                Text(displayTime)
                    .font(.system(size: 46, weight: .medium))
                    .padding(.top, 50)
                
                Spacer()
                    .frame(height: geometry.size.height * 0.33)
                
                // 时间单位选择器
                HStack(spacing: 20) {
                    TimeUnitButton(title: "时", isSelected: selectedUnit == .hour) {
                        selectedUnit = .hour
                    }
                    
                    TimeUnitButton(title: "分", isSelected: selectedUnit == .minute) {
                        selectedUnit = .minute
                    }
                    
                    TimeUnitButton(title: "秒", isSelected: selectedUnit == .second) {
                        selectedUnit = .second
                    }
                }
                .padding(.bottom, 15)
                
                // Click Wheel 区域
                ZStack {
                    // 外圈
                    Circle()
                        .stroke(lineWidth: 8)
                        .frame(width: 280, height: 280)
                        .foregroundColor(.gray.opacity(0.3))
                    
                    // 进度圈
                    Circle()
                        .trim(from: 0, to: timerActive ? CGFloat(remainingTime / selectedTime) : 1)
                        .stroke(timerActive ? Color.green : Color.blue,
                               style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                    
                    // Click Wheel
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 260, height: 260) //可调圆圈半径
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let center = CGPoint(x: value.startLocation.x,
                                                       y: value.startLocation.y)
                                    let currentPoint = value.location
                                    let angle = atan2(currentPoint.y - center.y,
                                                    currentPoint.x - center.x)
                                    
                                    if startAngle == 0 {
                                        startAngle = angle
                                    }
                                    
                                    let deltaAngle = angle - startAngle
                                    startAngle = angle
                                    
                                    // 分别获取时、分、秒的当前值
                                    var hours = Int(selectedTime) / 3600
                                    var minutes = (Int(selectedTime) % 3600) / 60
                                    var seconds = Int(selectedTime) % 60
                                    
                                    let sensitivity: Double = 0.025
                                    
                                    if deltaAngle > 0 {
                                        if abs(deltaAngle) >= sensitivity {  // 使用 sensitivity 来控制增量
                                            switch selectedUnit {
                                            case .hour:
                                                if hours < 24 {
                                                    hours = min(hours + 1, 24)
                                                }
                                            case .minute:
                                                if minutes < 59 {
                                                    minutes = min(minutes + 1, 59)
                                                }
                                            case .second:
                                                if seconds < 59 {
                                                    seconds = min(seconds + 1, 59)
                                                }
                                            }
                                            impactFeedback.impactOccurred()
                                            startAngle = angle  // 重置起始角度，为下一次增量做准备
                                        }
                                    } else if deltaAngle < 0 {
                                        if abs(deltaAngle) >= sensitivity {
                                            switch selectedUnit {
                                            case .hour:
                                                if hours > 0 {
                                                    hours = max(hours - 1, 0)
                                                }
                                            case .minute:
                                                if minutes > 0 {
                                                    minutes = max(minutes - 1, 0)
                                                }
                                            case .second:
                                                if seconds > 0 {
                                                    seconds = max(seconds - 1, 0)
                                                }
                                            }
                                            impactFeedback.impactOccurred()
                                            startAngle = angle  // 重置起始角度，为下一次增量做准备
                                        }
                                    }
                                    
                                    // 重新计算总时间
                                    let newTime = Double(hours * 3600 + minutes * 60 + seconds)
                                    if newTime <= maxTotalTime {
                                        selectedTime = newTime
                                    }
                                }
                                .onEnded { _ in
                                    startAngle = 0
                                }
                        )
                    
                    // 内圈
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(radius: 2)
                    
                    // 开始按钮
                    Button(action: {
                        if isAlarmPlaying {
                            stopAlarm()
                        } else if selectedTime > 0 {
                            startTimer()
                        }
                    }) {
                        buttonContent
                    }
                    .disabled(timerActive)
                }
                
                Spacer()
                
                if timerActive {
                    Button(action: cancelTimer) {
                        Text("取消")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 50)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    func startTimer() {
        remainingTime = selectedTime
        timerActive = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                handleTimerComplete()
            }
        }
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timerActive = false
        remainingTime = 0
        if isAlarmPlaying {
            stopAlarm()
        }
    }
}

struct TimeUnitButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .foregroundColor(isSelected ? .white : .blue)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                )
        }
    }
}

struct ContentView: View {
    var body: some View {
        TimerView()
    }
}

@main
struct TimerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
