//
//  ChartViews.swift
//  Turbo Boost Switcher
//

import SwiftUI

struct ChartEntry: Identifiable {
    let id = UUID()
    let value: Double
    let timestamp: Date
    let isTbEnabled: Bool
}

@objc public final class ChartDataSet: NSObject, ObservableObject {
    @Published var entries: [ChartEntry] = []
    @objc public dynamic var currentValue: String = ""
    @objc public dynamic var maxValue: Double = 100
    @objc public dynamic var minValue: Double = 0
    @objc public dynamic var step: Double = 20
    @objc public dynamic var marker: Double = 0
    
    let chartType: ChartType
    @objc public let title: String
    
    @objc public init(chartType: Int, title: String) {
        self.chartType = ChartType(rawValue: chartType) ?? .temperature
        self.title = title
        super.init()
    }
    
    @objc public func addEntry(value: Double, currentValue: String, isTbEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let entry = ChartEntry(value: value, timestamp: Date(), isTbEnabled: isTbEnabled)
            
            var newEntries = self.entries
            newEntries.append(entry)
            
            // 只保留5分钟内的数据
            let fiveMinutesAgo = Date().addingTimeInterval(-300)
            newEntries = newEntries.filter { $0.timestamp >= fiveMinutesAgo }
            
            self.entries = newEntries
            self.currentValue = currentValue
            
            print("[ChartDataSet] addEntry: title=\(self.title), isTbEnabled=\(isTbEnabled ? "YES" : "NO"), count=\(newEntries.count)")
        }
    }
    
    @objc public func clearEntries() {
        DispatchQueue.main.async { [weak self] in
            self?.entries = []
            print("[ChartDataSet] clearEntries: title=\(self?.title ?? "unknown")")
        }
    }
}

enum ChartType: Int {
    case temperature = 0
    case cpuLoad = 2
    case cpuFrequency = 3
}

enum ChartTheme {
    static let tbEnabledColor = Color.orange
    static let tbDisabledColor = Color.blue
    
    static func color(for isTbEnabled: Bool) -> Color {
        isTbEnabled ? tbEnabledColor : tbDisabledColor
    }
    
    static func nsColor(for isTbEnabled: Bool) -> NSColor {
        isTbEnabled ? .systemOrange : .systemBlue
    }
}

struct LineChartView: View {
    @ObservedObject var dataSet: ChartDataSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dataSet.title)
                    .font(.headline)
                Spacer()
                Text(dataSet.currentValue)
                    .font(.body.monospacedDigit())
            }
            
            Divider()
            
            if dataSet.entries.isEmpty {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    Text("No data")
                        .foregroundColor(.secondary)
                }
                .frame(height: 170)
            } else {
                ChartFrameView(dataSet: dataSet)
                    .frame(height: 170)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ChartFrameView: NSViewRepresentable {
    @ObservedObject var dataSet: ChartDataSet
    
    func makeNSView(context: Context) -> ChartNSView {
        let view = ChartNSView()
        view.wantsLayer = true
        return view
    }
    
    func updateNSView(_ nsView: ChartNSView, context: Context) {
        nsView.entries = dataSet.entries
        nsView.minValue = dataSet.minValue
        nsView.maxValue = dataSet.maxValue
        nsView.chartType = dataSet.chartType
        nsView.needsDisplay = true
    }
}

class ChartNSView: NSView {
    var entries: [ChartEntry] = []
    var minValue: Double = 0
    var maxValue: Double = 100
    var chartType: ChartType = .temperature
    
    override var isFlipped: Bool { true }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              entries.count > 1 else { return }
        
        let bounds = self.bounds
        let padding: CGFloat = 40
        let chartWidth = bounds.width - padding
        let chartHeight = bounds.height - 20
        
        let timeRange = entries.first!.timestamp...entries.last!.timestamp
        let timeInterval = timeRange.upperBound.timeIntervalSince(timeRange.lowerBound)
        guard timeInterval > 0 else { return }
        
        func xForTime(_ time: Date) -> CGFloat {
            let ratio = time.timeIntervalSince(timeRange.lowerBound) / timeInterval
            return padding + CGFloat(ratio) * chartWidth
        }
        
        func yForValue(_ value: Double) -> CGFloat {
            let range = maxValue - minValue
            guard range > 0 else { return chartHeight / 2 }
            let ratio = (value - minValue) / range
            return 10 + CGFloat(1 - ratio) * chartHeight
        }
        
        for i in 1..<entries.count {
            let prev = entries[i - 1]
            let curr = entries[i]
            
            let x1 = xForTime(prev.timestamp)
            let y1 = yForValue(prev.value)
            let x2 = xForTime(curr.timestamp)
            let y2 = yForValue(curr.value)
            
            let color = ChartTheme.nsColor(for: prev.isTbEnabled)
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(2.0)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            
            context.move(to: CGPoint(x: x1, y: y1))
            context.addLine(to: CGPoint(x: x2, y: y2))
            context.strokePath()
            
            let fillColor = color.withAlphaComponent(0.15)
            context.setFillColor(fillColor.cgColor)
            context.move(to: CGPoint(x: x1, y: y1))
            context.addLine(to: CGPoint(x: x2, y: y2))
            context.addLine(to: CGPoint(x: x2, y: chartHeight + 10))
            context.addLine(to: CGPoint(x: x1, y: chartHeight + 10))
            context.closePath()
            context.fillPath()
        }
        
        drawYAxis(context: context, bounds: bounds, padding: padding, chartHeight: chartHeight)
    }
    
    private func drawYAxis(context: CGContext, bounds: NSRect, padding: CGFloat, chartHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        let steps = 4
        for i in 0...steps {
            let value = minValue + (maxValue - minValue) * Double(i) / Double(steps)
            let y = 10 + CGFloat(Double(steps - i) / Double(steps)) * chartHeight
            
            let label = formatValue(value)
            let attrString = NSAttributedString(string: label, attributes: attrs)
            let size = attrString.size()
            
            context.setFillColor(NSColor.tertiaryLabelColor.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: padding - 5, y: y))
            context.addLine(to: CGPoint(x: bounds.width - 10, y: y))
            context.strokePath()
            
            attrString.draw(in: CGRect(x: 2, y: y - size.height / 2, width: padding - 8, height: size.height))
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch chartType {
        case .temperature:
            return String(format: "%.0f°", value)
        case .cpuLoad:
            return String(format: "%.0f%%", value)
        case .cpuFrequency:
            return String(format: "%.1f", value)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
        }
    }
}

struct ChartContainerView: View {
    @ObservedObject var tempDataSet: ChartDataSet
    @ObservedObject var cpuLoadDataSet: ChartDataSet
    @ObservedObject var cpuFreqDataSet: ChartDataSet
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                LineChartView(dataSet: tempDataSet)
                LineChartView(dataSet: cpuLoadDataSet)
            }
            
            HStack(spacing: 16) {
                LineChartView(dataSet: cpuFreqDataSet)
            }
            
            HStack(spacing: 16) {
                LegendItem(color: ChartTheme.tbDisabledColor, label: "TB Disabled")
                LegendItem(color: ChartTheme.tbEnabledColor, label: "TB Enabled")
            }
            .font(.caption)
        }
        .padding()
    }
}

@objc public class SwiftUIChartManager: NSObject {
    private var hostingView: NSHostingView<ChartContainerView>?
    private var tempDataSet: ChartDataSet?
    private var cpuLoadDataSet: ChartDataSet?
    private var cpuFreqDataSet: ChartDataSet?
    
    @objc public func createChartView(_ containerView: NSView,
                                        tempTitle: String,
                                        cpuLoadTitle: String,
                                        cpuFreqTitle: String,
                                        baseFreq: Float) {
        print("[SwiftUIChartManager] createChartView called, baseFreq: \(baseFreq)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.tempDataSet = ChartDataSet(chartType: 0, title: tempTitle)
            self.tempDataSet?.maxValue = 100
            self.tempDataSet?.minValue = 0
            
            self.cpuLoadDataSet = ChartDataSet(chartType: 2, title: cpuLoadTitle)
            self.cpuLoadDataSet?.maxValue = 100
            self.cpuLoadDataSet?.minValue = 0
            
            self.cpuFreqDataSet = ChartDataSet(chartType: 3, title: cpuFreqTitle)
            let maxFreq = baseFreq > 0.0 ? Float(roundf((baseFreq * 2) + 0.5)) : 4.0
            self.cpuFreqDataSet?.maxValue = Double(maxFreq)
            self.cpuFreqDataSet?.minValue = 0
            
            guard let temp = self.tempDataSet,
                  let cpuLoad = self.cpuLoadDataSet,
                  let cpuFreq = self.cpuFreqDataSet else {
                print("[SwiftUIChartManager] ERROR: Failed to create data sets")
                return
            }
            
            let chartView = ChartContainerView(
                tempDataSet: temp,
                cpuLoadDataSet: cpuLoad,
                cpuFreqDataSet: cpuFreq
            )
            
            self.hostingView = NSHostingView(rootView: chartView)
            self.hostingView?.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(self.hostingView!)
            
            NSLayoutConstraint.activate([
                self.hostingView!.topAnchor.constraint(equalTo: containerView.topAnchor),
                self.hostingView!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                self.hostingView!.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                self.hostingView!.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
            ])
            
            print("[SwiftUIChartManager] NSHostingView added to container")
        }
    }
    
    @objc public func addTempEntry(_ value: Double, currentValue: String, isTbEnabled: Bool) {
        tempDataSet?.addEntry(value: value, currentValue: currentValue, isTbEnabled: isTbEnabled)
    }
    
    @objc public func addCpuLoadEntry(_ value: Double, currentValue: String, isTbEnabled: Bool) {
        cpuLoadDataSet?.addEntry(value: value, currentValue: currentValue, isTbEnabled: isTbEnabled)
    }
    
    @objc public func addCpuFreqEntry(_ value: Double, currentValue: String, isTbEnabled: Bool) {
        guard value > 0 else { return }
        cpuFreqDataSet?.addEntry(value: value, currentValue: currentValue, isTbEnabled: isTbEnabled)
    }
    
    @objc public func clearAllData() {
        tempDataSet?.clearEntries()
        cpuLoadDataSet?.clearEntries()
        cpuFreqDataSet?.clearEntries()
        print("[SwiftUIChartManager] All chart data cleared")
    }
}