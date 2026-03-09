import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    let onDismiss: () -> Void

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    @State private var gestureReady = false
    @State private var page1Appeared = false
    @State private var pageWhyAppeared = false
    @State private var page2Appeared = false
    @State private var page3Appeared = false

    private let pageCount = 4

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(UIColor.systemGray5))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Pages
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        welcomePage.frame(width: geo.size.width)
                        whyPage.frame(width: geo.size.width)
                        checkInDemoPage.frame(width: geo.size.width)
                        progressPage.frame(width: geo.size.width)
                    }
                    .offset(x: -CGFloat(currentPage) * geo.size.width + dragOffset)
                    .allowsHitTesting(gestureReady)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if value.translation.width < -threshold && currentPage < pageCount - 1 {
                                        currentPage += 1
                                    } else if value.translation.width > threshold && currentPage > 0 {
                                        currentPage -= 1
                                    }
                                    dragOffset = 0
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                triggerPageAnimation()
                            }
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                }

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage
                                  ? Color(UIColor.systemGreen)
                                  : Color(UIColor.systemGray4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.vertical, 16)

                // "Let's go!" on last page
                if currentPage == pageCount - 1 {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        dismiss()
                    } label: {
                        Text(L10n.onboardingLetsGo)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemGreen))
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.systemBackground))
            )
            .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.height > 100 &&
                           abs(value.translation.height) > abs(value.translation.width) {
                            dismiss()
                        }
                    }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            page1Appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                gestureReady = true
            }
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            store.completeOnboarding()
            onDismiss()
        }
    }

    private func triggerPageAnimation() {
        switch currentPage {
        case 1: pageWhyAppeared = true
        case 2: page2Appeared = true
        case 3: page3Appeared = true
        default: break
        }
    }

    // MARK: - Page 1: Welcome

    @State private var emojiFloating = false

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                floatingEmoji("🛌", offset: CGSize(width: -50, height: -30), delay: 0.0)
                floatingEmoji("🚴", offset: CGSize(width: 40, height: -45), delay: 0.2)
                floatingEmoji("🥗", offset: CGSize(width: -30, height: 25), delay: 0.4)
                floatingEmoji("🧠", offset: CGSize(width: 55, height: 15), delay: 0.6)
                floatingEmoji("💻", offset: CGSize(width: 0, height: 50), delay: 0.8)
            }
            .frame(height: 120)
            .padding(.bottom, 8)

            Text("LifeTrack")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(L10n.onboardingTagline)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func floatingEmoji(_ emoji: String, offset: CGSize, delay: Double) -> some View {
        Text(emoji)
            .font(.system(size: 36))
            .offset(x: offset.width,
                    y: offset.height + (page1Appeared ? 0 : 20))
            .opacity(page1Appeared ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.7).delay(delay),
                value: page1Appeared
            )
            .offset(y: emojiFloating ? -4 : 4)
            .animation(
                .easeInOut(duration: 2.0 + delay)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: emojiFloating
            )
            .onAppear { emojiFloating = true }
    }

    // MARK: - Page 2: Why Track?

    @State private var whyStep = 0

    private var whyPage: some View {
        VStack(spacing: 28) {
            Spacer()

            HStack(spacing: 20) {
                whyBubble(emoji: "✏️", word: L10n.onboardingWhyWord1, step: 1)
                whyBubble(emoji: "👀", word: L10n.onboardingWhyWord2, step: 2)
                whyBubble(emoji: "🌱", word: L10n.onboardingWhyWord3, step: 3)
            }

            // Arrows between steps
            HStack(spacing: 0) {
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(UIColor.systemGreen))
                    .opacity(whyStep >= 2 ? 1 : 0)
                    .scaleEffect(whyStep >= 2 ? 1 : 0.3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: whyStep)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(UIColor.systemGreen))
                    .opacity(whyStep >= 3 ? 1 : 0)
                    .scaleEffect(whyStep >= 3 ? 1 : 0.3)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: whyStep)
                Spacer()
            }
            .padding(.horizontal, 32)
            .offset(y: -18)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: pageWhyAppeared) { appeared in
            if appeared { startWhyAnimation() }
        }
    }

    private func whyBubble(emoji: String, word: String, step: Int) -> some View {
        VStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 44))
                .scaleEffect(whyStep >= step ? 1.0 : 0.2)
                .opacity(whyStep >= step ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6),
                    value: whyStep
                )

            Text(word)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .opacity(whyStep >= step ? 1 : 0)
                .offset(y: whyStep >= step ? 0 : 8)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8).delay(0.1),
                    value: whyStep
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func startWhyAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { whyStep = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { whyStep = 2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { whyStep = 3 }
    }

    // MARK: - Page 3: Check-in Demo

    @State private var demoCardDone = false
    @State private var demoProgress: CGFloat = 0

    private var checkInDemoPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(L10n.onboardingPage2Title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(L10n.onboardingPage2Subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                demoHabitCard
                demoProgressBar
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: page2Appeared) { appeared in
            if appeared { startPage2Animation() }
        }
    }

    private var demoHabitCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(demoCardDone
                          ? Color(UIColor.systemGreen).opacity(0.15)
                          : Color(UIColor.systemGray5))
                    .frame(width: 42, height: 42)
                Text("🚴")
                    .font(.system(size: 20))
            }

            Text(L10n.isRu ? "Активность" : "Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .fill(demoCardDone ? Color(UIColor.systemGreen) : Color.clear)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                demoCardDone ? Color.clear : Color(UIColor.systemGray4),
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(demoCardDone ? 1.0 : 0.9)

                if demoCardDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: demoCardDone)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(demoCardDone
                      ? Color(UIColor.systemGreen).opacity(0.1)
                      : Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    demoCardDone
                        ? Color(UIColor.systemGreen).opacity(0.25)
                        : Color.clear,
                    lineWidth: 1
                )
        )
    }

    private var demoProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 4)
                Capsule()
                    .fill(Color(UIColor.systemGreen))
                    .frame(width: geo.size.width * demoProgress, height: 4)
                    .animation(.easeInOut(duration: 0.6), value: demoProgress)
            }
        }
        .frame(height: 4)
    }

    private func startPage2Animation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                demoCardDone = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            demoProgress = 0.6
        }
    }

    // MARK: - Page 4: Progress Heatmap

    @State private var heatmapCellsVisible: Int = 0

    private let heatmapPattern: [[Bool]] = [
        [false, true,  true,  false, true,  true,  true],
        [true,  true,  false, true,  true,  true,  false],
        [true,  true,  true,  true,  false, true,  true],
        [false, true,  true,  true,  true,  true,  false],
        [true,  false, true,  true,  true,  true,  true],
    ]

    private var progressPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(L10n.onboardingPage3Title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(L10n.onboardingPage3Subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<7, id: \.self) { col in
                            let cellIndex = row * 7 + col
                            let isGreen = heatmapPattern[row][col]
                            let isVisible = cellIndex < heatmapCellsVisible

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    isVisible && isGreen
                                        ? Color(UIColor.systemGreen)
                                        : Color(UIColor.systemGray5)
                                )
                                .frame(width: 28, height: 28)
                                .scaleEffect(isVisible ? 1.0 : 0.5)
                                .opacity(isVisible ? 1.0 : 0.3)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.7)
                                    .delay(Double(cellIndex) * 0.05),
                                    value: heatmapCellsVisible
                                )
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 16)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: page3Appeared) { appeared in
            if appeared { heatmapCellsVisible = 35 }
        }
    }
}
