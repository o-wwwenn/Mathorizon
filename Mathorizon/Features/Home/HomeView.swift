import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QuestionCategory.createdAt) private var categories: [QuestionCategory]

    @State private var showAdmin = false
    @State private var animateCards = false

    private var arithmeticCategory: QuestionCategory? {
        categories.first { $0.name == "四則運算" }
    }

    private var algebraCategory: QuestionCategory? {
        categories.first { $0.name == "代數" }
    }

    private var ratioCategory: QuestionCategory? {
        categories.first { $0.name.contains("比例") }
    }

    private var mixedDeck: QuizDeck {
        QuizDeck(
            title: "混合",
            iconName: "square.grid.2x2.fill",
            palette: .jade,
            cardColorHex: nil,
            questions: categories.flatMap(\.questions).shuffled()
        )
    }

    private var extraCategories: [QuestionCategory] {
        categories.filter { category in
            category.name != "四則運算" &&
            category.name != "代數" &&
            !category.name.contains("比例")
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let safeHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom
                let horizontalPadding: CGFloat = 22
                let titleHorizontalPadding: CGFloat = horizontalPadding
                let spacing: CGFloat = 14
                let topArea = max(170, safeHeight * 0.24)
                let smallCardHeight = max(72, safeHeight * 0.09)
                let largeCardHeight = max(168, (safeHeight - topArea - smallCardHeight - spacing * 4) / 2)

                ZStack {
                    Color(red: 0.985, green: 0.973, blue: 0.955)
                        .ignoresSafeArea()

                    HomeBackgroundGlow(isAnimated: animateCards)

                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            Spacer(minLength: 0)

                            HomeBrandBanner()
                        }
                        .frame(maxWidth: .infinity, maxHeight: topArea, alignment: .bottomLeading)
                        .padding(.horizontal, titleHorizontalPadding)
                        .padding(.bottom, 26)

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: spacing) {
                                HStack(spacing: spacing) {
                                    Button {
                                        showAdmin = true
                                    } label: {
                                        SmallHomeCard(
                                            title: "題庫",
                                            iconName: "books.vertical.fill",
                                            color: Color(red: 0.91, green: 0.68, blue: 0.20),
                                            delay: 0.02,
                                            animateCards: animateCards
                                        )
                                    }
                                    .buttonStyle(CardPressStyle())
                                    .hoverEffect(.lift)
                                    .frame(height: smallCardHeight)

                                    NavigationLink {
                                        ScoreHistoryView()
                                    } label: {
                                        SmallHomeCard(
                                            title: "歷史紀錄",
                                            iconName: "clock.arrow.circlepath",
                                            color: Color(red: 0.84, green: 0.57, blue: 0.24),
                                            delay: 0.08,
                                            animateCards: animateCards
                                        )
                                    }
                                    .buttonStyle(CardPressStyle())
                                    .hoverEffect(.lift)
                                    .frame(height: smallCardHeight)
                                }

                                HStack(spacing: spacing) {
                                    homeCardLink(
                                        title: "四則運算",
                                        iconName: "plus.forwardslash.minus",
                                        color: Color(red: 0.77, green: 0.28, blue: 0.24),
                                        delay: 0.14,
                                        animateCards: animateCards,
                                        destination: arithmeticCategory.map { AnyView(QuizView(category: $0)) }
                                    )

                                    homeCardLink(
                                        title: "代數",
                                        iconName: "x.squareroot",
                                        color: Color(red: 0.60, green: 0.31, blue: 0.75),
                                        delay: 0.2,
                                        animateCards: animateCards,
                                        destination: algebraCategory.map { AnyView(QuizView(category: $0)) }
                                    )
                                }
                                .frame(height: largeCardHeight)

                                HStack(spacing: spacing) {
                                    homeCardLink(
                                        title: "比例",
                                        iconName: "chart.xyaxis.line",
                                        color: Color(red: 0.30, green: 0.41, blue: 0.75),
                                        delay: 0.26,
                                        animateCards: animateCards,
                                        destination: ratioCategory.map { AnyView(QuizView(category: $0)) }
                                    )

                                    NavigationLink {
                                        QuizView(deck: mixedDeck)
                                    } label: {
                                        LargeHomeCard(
                                            title: "混合",
                                            iconName: "square.grid.2x2.fill",
                                            color: Color(red: 0.36, green: 0.67, blue: 0.46),
                                            delay: 0.32,
                                            animateCards: animateCards
                                        )
                                    }
                                    .buttonStyle(CardPressStyle())
                                    .hoverEffect(.lift)
                                }
                                .frame(height: largeCardHeight)

                                if !extraCategories.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("更多單元")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)

                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: spacing) {
                                            ForEach(Array(extraCategories.enumerated()), id: \.element.id) { index, category in
                                                NavigationLink {
                                                    QuizView(category: category)
                                                } label: {
                                                    LargeHomeCard(
                                                        title: category.name,
                                                        iconName: category.iconName,
                                                        color: category.homeCardColor,
                                                        delay: 0.38 + Double(index) * 0.05,
                                                        animateCards: animateCards
                                                    )
                                                }
                                                .buttonStyle(CardPressStyle())
                                                .hoverEffect(.lift)
                                                .frame(height: largeCardHeight)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.bottom, max(18, proxy.safeAreaInsets.bottom + 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }
            .sheet(isPresented: $showAdmin) {
                NavigationStack {
                    AdminView()
                }
            }
            .task {
                SeedData.insertIfNeeded(context: modelContext)
            }
            .onAppear {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    animateCards = true
                }
            }
        }
    }

    @ViewBuilder
    private func homeCardLink(
        title: String,
        iconName: String,
        color: Color,
        delay: Double,
        animateCards: Bool,
        destination: AnyView?
    ) -> some View {
        if let destination {
            NavigationLink {
                destination
            } label: {
                LargeHomeCard(
                    title: title,
                    iconName: iconName,
                    color: color,
                    delay: delay,
                    animateCards: animateCards
                )
            }
            .buttonStyle(CardPressStyle())
            .hoverEffect(.lift)
        } else {
            LargeHomeCard(
                title: title,
                iconName: iconName,
                color: color,
                delay: delay,
                animateCards: animateCards
            )
            .opacity(0.45)
        }
    }
}

private struct HomeBrandBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                Text("Mathorizon")
                    .font(.system(size: proxy.size.width * 0.38, weight: .black, design: .rounded))
                    .tracking(-3.1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.14, green: 0.14, blue: 0.16),
                                Color(red: 0.30, green: 0.32, blue: 0.36)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: proxy.size.width, alignment: .leading)
            }
            .frame(height: 68)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.77, blue: 0.30),
                            Color(red: 0.42, green: 0.60, blue: 0.92)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 14)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )

            Text("Pick a lane. Start a round.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HomeBackgroundGlow: View {
    let isAnimated: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 260, height: 260)
                .blur(radius: 18)
                .offset(x: isAnimated ? 120 : 90, y: -260)

            Circle()
                .fill(Color(red: 0.89, green: 0.94, blue: 1.0).opacity(0.7))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: -130, y: 240)

            RoundedRectangle(cornerRadius: 54, style: .continuous)
                .fill(Color.white.opacity(0.26))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(isAnimated ? 16 : 10))
                .offset(x: 150, y: 260)
        }
        .animation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true), value: isAnimated)
        .ignoresSafeArea()
    }
}

private struct SmallHomeCard: View {
    let title: String
    let iconName: String
    let color: Color
    let delay: Double
    let animateCards: Bool

    var body: some View {
        cardBase
            .offset(y: animateCards ? 0 : 18)
            .opacity(animateCards ? 1 : 0.01)
            .animation(.spring(response: 0.58, dampingFraction: 0.82).delay(delay), value: animateCards)
    }

    private var cardBase: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color.opacity(0.88))
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.52))
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)

            HStack(spacing: 10) {
                CategoryIconView(iconName: iconName, size: 18)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.55), in: Circle())

                Text(title)
                    .font(AppFontRegistry.Home.compactCardTitle(size: 21))
                    .foregroundStyle(Color(red: 0.16, green: 0.15, blue: 0.17))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 12)
    }
}

private struct LargeHomeCard: View {
    let title: String
    let iconName: String
    let color: Color
    let delay: Double
    let animateCards: Bool

    var body: some View {
        cardBase
            .offset(y: animateCards ? 0 : 26)
            .scaleEffect(animateCards ? 1 : 0.96)
            .opacity(animateCards ? 1 : 0.01)
            .animation(.spring(response: 0.72, dampingFraction: 0.84).delay(delay), value: animateCards)
    }

    private var cardBase: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(color.opacity(0.9))

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.28), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.36))

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 1.15)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.52))
                            .frame(width: 46, height: 46)
                        CategoryIconView(iconName: iconName, size: 22)
                            }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer()

                Text(title)
                    .font(AppFontRegistry.Home.largeCardTitle(size: 30))
                    .tracking(-0.8)
                    .foregroundStyle(Color(red: 0.13, green: 0.12, blue: 0.14))
                    .multilineTextAlignment(.leading)
            }
            .padding(18)
        }
        .shadow(color: Color.black.opacity(0.13), radius: 22, y: 14)
    }
}


#Preview {
    HomeView()
        .modelContainer(for: [QuestionCategory.self, Question.self, TestSession.self], inMemory: true)
}
