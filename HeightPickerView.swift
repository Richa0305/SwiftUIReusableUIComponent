import SwiftUI

// MARK: - HeightPickerView
// Combines the ruler, unit picker, and display into one view
struct HeightPickerView: View {
    @State private var heightCm: Double = 170.0
    @State private var unit: HeightUnit = .cm

    init() {
        UISegmentedControl.appearance().selectedSegmentTintColor = .black
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
    }

    var body: some View {
        VStack {
            // Question
            Text("What is your height?")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
            HStack(spacing: 24) {
                RulerView(heightCm: $heightCm, unit: unit)
                Spacer()
                VStack {
                    HeightDisplayView(heightCm: heightCm, unit: unit)
                    UnitPickerView(unit: $unit)
                }
                Spacer()
            }
        }
    }
}

// MARK: - HeightUnit Enum
// Handles unit definitions and conversions
enum HeightUnit: String, CaseIterable {
    case cm, ft

    var minValue: Double { self == .cm ? 100 : 3 }
    var maxValue: Double { self == .cm ? 220 : 7 }
    private static let cmToFeet = 0.0328084

    func convertedToUnit(fromCm cm: Double) -> Double {
        self == .cm ? cm : cm * Self.cmToFeet
    }

    func convertedToCm(fromUnit value: Double) -> Double {
        self == .cm ? value : value / Self.cmToFeet
    }
}

// MARK: - Preference for Tick Positions
private struct TickPreferenceData: Equatable {
    let index: Int
    let centerY: CGFloat
}
private struct TickPreferenceKey: PreferenceKey {
    static var defaultValue: [TickPreferenceData] = []
    static func reduce(value: inout [TickPreferenceData], nextValue: () -> [TickPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: - RulerView
// A scrollable ruler that reports the selected height
struct RulerView: View {
    @Binding var heightCm: Double
    let unit: HeightUnit
    let tickSpacing: CGFloat = 5
    let indicatorThickness: CGFloat = 2

    @State private var didInitScroll = false

    private var displayedHeight: Double {
        let raw = unit.convertedToUnit(fromCm: heightCm)
        let clamped = min(max(raw, unit.minValue), unit.maxValue)
        return (clamped * 10).rounded() / 10
    }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    tickList
                        .padding(.vertical, geo.size.height / 2)
                }
                .id(unit)
                .onAppear { scrollToCurrent(proxy) }
                .coordinateSpace(name: "ruler")
                .onPreferenceChange(TickPreferenceKey.self) { updateHeight(from: $0, in: geo) }
                .overlay(indicatorLine, alignment: .center)
            }
        }
        .frame(width: 60)
    }

    // Build the tick marks and labels
    private var tickList: some View {
        VStack(spacing: tickSpacing) {
            ForEach(0...Int((unit.maxValue - unit.minValue) * 10), id: \.self) { i in
                let value = unit.minValue + Double(i) * 0.1
                TickView(index: i, value: value)
                    .background(positionReporter(for: i))
                    .id(i)
            }
        }
    }

    // Individual tick mark
    @ViewBuilder
    private func TickView(index i: Int, value v: Double) -> some View {
        HStack(spacing: 4) {
            if i % 10 == 0 {
                Rectangle().frame(width: 30, height: 1)
                Text(String(format: "%.0f", v)).font(.caption).fixedSize()
            } else if i % 5 == 0 {
                Rectangle().frame(width: 20, height: 1).opacity(0.7)
            } else {
                Rectangle().frame(width: 15, height: 1).opacity(0.7)
            }
            Spacer()
        }
        .foregroundColor(.gray)
        .frame(height: tickSpacing)
    }

    // Reports each tick's center position
    private func positionReporter(for index: Int) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: TickPreferenceKey.self,
                value: [TickPreferenceData(index: index, centerY: geo.frame(in: .named("ruler")).midY)]
            )
        }
    }

    // Purple indicator line
    private var indicatorLine: some View {
        Rectangle()
            .fill(.purple)
            .frame(height: indicatorThickness)
            .frame(maxWidth: .infinity)
    }

    // Scroll to the current height on appear
    private func scrollToCurrent(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let idx = Int((displayedHeight - unit.minValue) / 0.1)
            proxy.scrollTo(idx, anchor: .center)
            didInitScroll = true
        }
    }

    // Update the bound heightCm based on nearest tick
    private func updateHeight(from prefs: [TickPreferenceData], in geo: GeometryProxy) {
        guard didInitScroll else { return }
        let centerY = geo.size.height / 2
        if let nearest = prefs.min(by: { abs($0.centerY - centerY) < abs($1.centerY - centerY) }) {
            let newValue = unit.minValue + Double(nearest.index) * 0.1
            heightCm = unit.convertedToCm(fromUnit: newValue)
        }
    }
}

// MARK: - UnitPickerView
// A segmented control to switch between cm and ft
struct UnitPickerView: View {
    @Binding var unit: HeightUnit

    var body: some View {
        Picker("Unit", selection: $unit) {
            ForEach(HeightUnit.allCases, id: \.self) { u in
                Text(u.rawValue.uppercased())
                    .foregroundColor(unit == u ? .white : .black)
                    .fontWeight(unit == u ? .bold : .regular)
            }
        }
        .pickerStyle(.segmented)
        .tint(.black)
        .frame(width: 150)
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
    }
}

// MARK: - HeightDisplayView
// Shows the numeric height value with animation
struct HeightDisplayView: View {
    let heightCm: Double
    let unit: HeightUnit

    private var displayedHeight: Double {
        let raw = unit.convertedToUnit(fromCm: heightCm)
        let clamped = min(max(raw, unit.minValue), unit.maxValue)
        return (clamped * 10).rounded() / 10
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(String(format: "%.1f", displayedHeight))
                .frame(maxWidth: displayedHeight < 100 ? 110 : 140)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.purple)
                .contentTransition(.numericText())
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                    value: displayedHeight
                )
            Text(unit.rawValue.lowercased())
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.purple)
        }
    }
}

// Preview for Xcode canvas
struct HeightPickerView_Previews: PreviewProvider {
    static var previews: some View {
        HeightPickerView()
    }
}
