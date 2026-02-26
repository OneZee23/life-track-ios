# LifeTrack — iOS

> Минималистичный трекер привычек для iOS. Делал или не делал?

**Platform:** iOS (App Store)
**Stack:** SwiftUI (нативное приложение)
**Android версия:** [life-track-android](https://github.com/OneZee23/life-track-android) (React Native)

---

## TL;DR

Каждый трекер привычек спрашивает слишком много. Слайдеры, оценки, таймеры, заметки. LifeTrack спрашивает одно: **делал или нет?** Тап = сделал. Нет тапа = пропустил. Пять привычек, пять тапов, готово. Смотри, как растёт GitHub-style heatmap.

Без регистрации. Без облака. Без уведомлений. Без стресса.

---

## Структура репозитория

```
life-track-ios/
├── LifeTrackNative/     # SwiftUI приложение (14 .swift файлов)
│   ├── LifeTrack/       # Исходный код
│   └── README.md        # Инструкция по сборке в Xcode
└── mvp/                 # Прототипы и документация (JSX, PRD, tech doc)
```

Подробная инструкция по сборке: [LifeTrackNative/README.md](LifeTrackNative/README.md)

---

## Быстрый старт

```bash
git clone https://github.com/OneZee23/life-track-ios.git
cd life-track-ios/LifeTrackNative
open LifeTrack.xcodeproj   # откроет Xcode
# ⌘+R — запустить на симуляторе
```

Или используй `make`:

```bash
make run        # сборка и запуск на симуляторе
make archive    # архив для App Store
make submit     # отправка в App Store Connect (xcrun altool)
```

Подробно о build/submit скриптах: [Makefile](Makefile)

---

## Tech Stack

```
UI:           SwiftUI
State:        @StateObject + ObservableObject
Storage:      UserDefaults + JSON (Codable)
Animations:   SwiftUI .spring(), withAnimation
Haptics:      UIImpactFeedbackGenerator
Min iOS:      16.0+
Build:        Xcode → App Store Connect
```

---

## Ссылки

- **Канал:** [@onezee_co](https://t.me/onezee_co) — прогресс разработки
- **YouTube:** [OneZee](https://www.youtube.com/c/onezee)
- **Фидбек:** [@onezee123](https://t.me/onezee123)
- **Android версия:** [life-track-android](https://github.com/OneZee23/life-track-android)

---

## License

MIT
