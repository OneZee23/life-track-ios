import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // Внешний вид
                Section {
                    DayNightSceneView(isDark: store.isDark)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    Toggle(isOn: Binding(
                        get: { store.isDark },
                        set: { _ in
                            withAnimation(.easeInOut(duration: 0.4)) {
                                store.toggleDark()
                            }
                        }
                    )) {
                        Label {
                            Text("Тёмная тема")
                        } icon: {
                            ZStack {
                                if store.isDark {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(.indigo)
                                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                                } else {
                                    Image(systemName: "sun.max.fill")
                                        .foregroundColor(.orange)
                                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: store.isDark)
                        }
                    }
                    .tint(Color(UIColor.systemGreen))
                } header: {
                    Text("Внешний вид")
                }

                // О проекте
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LifeTrack — минималистичный трекер привычек. Отмечай вчерашний день за 5 секунд, смотри прогресс на тепловой карте. Без оценок, без стресса — просто делал или не делал.")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .lineSpacing(3)

                        Text("Это MVP — приложение создаётся открыто, вместе с сообществом. Весь процесс в Telegram-канале.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)

                        Text("Автор — OneZee, инди-разработчик.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("О проекте")
                }

                // Обратная связь
                Section {
                    linkRow(
                        icon: "paperplane.fill",
                        iconColor: .blue,
                        title: "Написать автору",
                        subtitle: "Баги, идеи, предложения",
                        url: "https://t.me/onezee"
                    )
                } header: {
                    Text("Обратная связь")
                }

                // Ссылки
                Section {
                    linkRow(
                        icon: "paperplane.fill",
                        iconColor: .blue,
                        title: "Telegram-канал",
                        subtitle: "Разработка LifeTrack в реальном времени",
                        url: "https://t.me/onezee"
                    )
                    linkRow(
                        icon: "play.rectangle.fill",
                        iconColor: .red,
                        title: "YouTube",
                        subtitle: "Канал автора",
                        url: "https://youtube.com"
                    )
                } header: {
                    Text("Ссылки")
                }

                // Версия
                Section {
                    HStack {
                        Text("Версия")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("0.1.0 (native)")
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("LifeTrack Native MVP — сделано с душой ♥")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(Color(UIColor.systemGreen))
                }
            }
        }
        .preferredColorScheme(store.isDark ? .dark : .light)
    }

    @ViewBuilder
    func linkRow(icon: String, iconColor: Color, title: String, subtitle: String, url: String) -> some View {
        Button {
            if let u = URL(string: url) {
                UIApplication.shared.open(u)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Day/Night Scene

struct DayNightSceneView: View {
    let isDark: Bool

    private let stars: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        (0.07, 0.14, 1.5), (0.20, 0.07, 1.2), (0.35, 0.22, 1.8),
        (0.52, 0.10, 1.4), (0.68, 0.20, 1.6), (0.80, 0.07, 1.2),
        (0.45, 0.32, 1.5), (0.13, 0.38, 1.3), (0.88, 0.28, 1.4),
        (0.28, 0.17, 1.2), (0.60, 0.35, 1.6), (0.76, 0.40, 1.3)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Sky gradient
                LinearGradient(
                    colors: isDark
                        ? [Color(red: 0.04, green: 0.04, blue: 0.16), Color(red: 0.07, green: 0.07, blue: 0.26)]
                        : [Color(red: 0.36, green: 0.62, blue: 0.98), Color(red: 0.62, green: 0.86, blue: 1.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Stars (fade in at night)
                ForEach(Array(stars.enumerated()), id: \.offset) { _, s in
                    Circle()
                        .fill(Color.white)
                        .frame(width: s.r * 2, height: s.r * 2)
                        .position(x: s.x * geo.size.width, y: s.y * geo.size.height)
                        .opacity(isDark ? 1.0 : 0)
                }

                // Sun (slides in from left for day, exits left for night)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1.0, green: 0.96, blue: 0.52), Color(red: 1.0, green: 0.76, blue: 0.10)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.55), radius: 18)
                    .position(x: isDark ? -44 : geo.size.width * 0.22, y: geo.size.height * 0.42)
                    .opacity(isDark ? 0 : 1)

                // Moon (slides in from right for night)
                ZStack {
                    Circle()
                        .fill(Color(red: 0.90, green: 0.90, blue: 0.94))
                        .frame(width: 32, height: 32)
                        .shadow(color: Color.white.opacity(0.45), radius: 12)
                    Circle()
                        .fill(Color(red: 0.74, green: 0.74, blue: 0.79))
                        .frame(width: 8, height: 8)
                        .offset(x: 5, y: -4)
                    Circle()
                        .fill(Color(red: 0.77, green: 0.77, blue: 0.82))
                        .frame(width: 5, height: 5)
                        .offset(x: -6, y: 6)
                }
                .position(x: isDark ? geo.size.width * 0.72 : geo.size.width + 44, y: geo.size.height * 0.38)
                .opacity(isDark ? 1 : 0)

                // Cloud (slides in for day, exits right for night)
                cloudShape
                    .position(x: isDark ? geo.size.width + 80 : geo.size.width * 0.66, y: geo.size.height * 0.28)
                    .opacity(isDark ? 0 : 1)

                // Ground strip
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: isDark
                                ? [Color(red: 0.10, green: 0.12, blue: 0.22), Color(red: 0.07, green: 0.09, blue: 0.17)]
                                : [Color(red: 0.24, green: 0.68, blue: 0.28), Color(red: 0.17, green: 0.56, blue: 0.22)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.65), value: isDark)
    }

    private var cloudShape: some View {
        ZStack {
            Capsule().fill(Color.white.opacity(0.90)).frame(width: 52, height: 20)
            Capsule().fill(Color.white.opacity(0.95)).frame(width: 34, height: 16).offset(x: 13, y: -9)
            Capsule().fill(Color.white.opacity(0.85)).frame(width: 28, height: 14).offset(x: -13, y: -8)
        }
    }
}
