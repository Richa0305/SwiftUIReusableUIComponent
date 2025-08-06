import SwiftUI

struct MorningRoutineOnboardingView: View {
    @State private var currentIndex = 0
    @State private var showMask = false
    @State private var maskRadius: CGFloat = 0
    @State private var breatheIn = false
    @State private var isButtonPressed = false

    private let buttonRadius: CGFloat = 40
    private let bottomPadding: CGFloat = 60
    private let colors: [Color] = [.blue, .pink, .purple]
    private let items: [(symbol: String, title: String)] = [
        ("drop.fill",   "Drink Water"),
        ("figure.walk", "Exercise for half an hour"),
        ("pencil",      "Write goals for today")
    ]

    private var nextIndex: Int { (currentIndex + 1) % colors.count }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        colors[currentIndex],
                        colors[currentIndex].opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Masked reveal
                if showMask {
                    colors[nextIndex]
                        .ignoresSafeArea()
                        .mask(
                            Circle()
                                .frame(width: maskRadius * 2,
                                       height: maskRadius * 2)
                                .position(
                                    x: geo.size.width / 2,
                                    y: geo.size.height - buttonRadius - bottomPadding
                                )
                        )
                }

                VStack {
                    // Header
                    Text("Morning Routine")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                        .opacity(showMask ? 0 : 1)

                    Spacer()

                    // Symbol + Title
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .blur(radius: 10)

                            Image(systemName: items[currentIndex].symbol)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.white)
                                .scaleEffect(breatheIn ? 1.2 : 0.8)
                                .animation(
                                  .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                  value: breatheIn
                                )
                        }

                        Text(items[currentIndex].title)
                            .font(.title).bold()
                            .foregroundColor(.white)
                    }
                    .opacity(showMask ? 0 : 1)

                    Spacer()

                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<colors.count, id: \.self) { idx in
                            Circle()
                                .frame(width: idx == currentIndex ? 12 : 8,
                                       height: idx == currentIndex ? 12 : 8)
                                .foregroundColor(.white.opacity(idx == currentIndex ? 1 : 0.5))
                        }
                    }
                    .padding(.bottom, 16)
                    .opacity(showMask ? 0 : 1)

                    // Forward button
                    ZStack {
                        Circle()
                            .fill(colors[nextIndex])
                            .frame(width: buttonRadius * 2,
                                   height: buttonRadius * 2)
                            .shadow(color: .black.opacity(0.2),
                                    radius: 8, x: 0, y: 4)
                            .scaleEffect(isButtonPressed ? 0.9 : 1)

                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.white)
                            .scaleEffect(breatheIn ? 1.2 : 0.8)
                            .animation(
                              .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                              value: breatheIn
                            )
                    }
                    .padding(.bottom, bottomPadding)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    isButtonPressed = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    isButtonPressed = false
                                }
                                animateTransition(in: geo)
                            }
                    )
                }
            }
            .onAppear {
                // kick off first breathe animation
                breatheIn = true
            }
            .onChange(of: currentIndex) { _, _ in
                // restart breathing on each step change
                breatheIn = false
                DispatchQueue.main.async {
                    breatheIn = true
                }
            }
        }
    }

    private func animateTransition(in geo: GeometryProxy) {
        let maxRadius = hypot(geo.size.width, geo.size.height)
        maskRadius = buttonRadius
        showMask = true

        withAnimation(.easeInOut(duration: 0.5)) {
            maskRadius = maxRadius
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentIndex = nextIndex
            withAnimation(.easeInOut(duration: 0.5)) {
                maskRadius = buttonRadius
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showMask = false
            }
        }
    }
}

struct MorningRoutineOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        MorningRoutineOnboardingView()
    }
}
