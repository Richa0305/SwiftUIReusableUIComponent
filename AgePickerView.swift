import SwiftUI
struct AgePickerView: View {
    @Binding var selectedAge: Int
    @State private var dragOffset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    
    private let ageRange = 18...100
    private let itemWidth: CGFloat = 170
    private let itemSpacing: CGFloat = 10
    
    private var totalItemWidth: CGFloat {
        itemWidth + itemSpacing
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                titleSection
                Spacer()
                agePickerView
                    .frame(height: 120)
                Spacer()
                Spacer()
            }
            
            // Full-screen transparent overlay catching drags everywhere
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                      DragGesture()
                        .onChanged { value in
                          dragOffset = value.translation.width
                        }
                        .onEnded { value in
                          // 1) Where SwiftUI “predicts” we’d finish:
                          let predictedDrag = value.predictedEndTranslation.width
                          let predictedTotalOffset = currentOffset + predictedDrag

                          // 2) Compute the nearest item index from that
                          let rawIndex = -predictedTotalOffset / totalItemWidth
                          let rounded  = Int(round(rawIndex))

                          // 3) Clamp to your range
                          let clamped  = min(max(rounded, 0), ageRange.count - 1)

                          // 4) Update state
                          selectedAge   = ageRange.lowerBound + clamped
                          currentOffset = CGFloat(clamped) * -totalItemWidth

                          // 5) Reset dragOffset & animate
                          withAnimation(.easeOut(duration: 0.4)) {
                            dragOffset = 0
                          }
                        }
                    )

            }
            
        }
        .onAppear {
            // initialize offset so selectedAge starts centered
            currentOffset = CGFloat(selectedAge - ageRange.lowerBound) * -totalItemWidth
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("What is your Age?")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
        }
        .padding(.horizontal, 20)
    }
    
    private var agePickerView: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            
            HStack(spacing: itemSpacing) {
                ForEach(Array(ageRange), id: \.self) { age in
                    ageNumberView(age: age)
                }
            }
            .offset(x: currentOffset + dragOffset + centerX - itemWidth/2)
        }
    }
    
    private func ageNumberView(age: Int) -> some View {
        let isSelected = age == selectedAge
        return Text("\(age)")
            .font(.system(size: 120, weight: isSelected ? .medium : .light))
            .foregroundColor(isSelected ? .black : .gray)
            .frame(width: itemWidth, height: 80)
            .scaleEffect(isSelected ? 1 : 0.8)
            .opacity(isSelected ? 1 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: selectedAge)
    }
    
    private func updateSelectedAgeFromOffset(centerX: CGFloat) {
        let totalOffset = currentOffset + dragOffset
        let index = Int(round(-totalOffset / totalItemWidth))
        let clamped = max(0, min(index, ageRange.count - 1))
        let newAge = ageRange.lowerBound + clamped
        if newAge != selectedAge {
            selectedAge = newAge
        }
    }
    
    private func snapToNearestAge(velocity: CGFloat) {
        var target = selectedAge
        if abs(velocity) > 50 {
            let momentum = Int(velocity / 100)
            target = max(ageRange.lowerBound,
                         min(ageRange.upperBound, selectedAge - momentum))
        }
        let idx = target - ageRange.lowerBound
        let newOffset = CGFloat(idx) * -totalItemWidth
        
        withAnimation(.easeOut(duration: 0.4)) {
            currentOffset = newOffset
            dragOffset = 0
            selectedAge = target
        }
    }
}


// MARK: - Preview
struct AgePickerView_Previews: PreviewProvider {
    @State static var age = 30
    static var previews: some View {
        AgePickerView(selectedAge: $age)
            .previewLayout(.sizeThatFits)
    }
}
