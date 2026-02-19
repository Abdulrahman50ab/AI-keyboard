# 🧠 AI Keyboard Assistant

A powerful, modern Flutter custom keyboard enhanced with cutting-edge AI features, multilingual support, and seamless multimedia integration.

---

## ✨ Key Features

### 🤖 AI-Powered Writing Assistant
Leverages the **Groq AI (Llama 3)** to transform your typing experience:
- **Grammar Fix**: Automatically correct spelling and syntax errors.
- **Smart Rephrase**: Rewrite your text in multiple styles (Formal, Casual, Professional, etc.).
- **AI Assist**: Get suggestions to expand your ideas or generate content from a simple prompt.
- **Magic Actions**: Select text in any app and use the keyboard to **Summarize**, **Translate**, or **Rephrase** instantly.
- **Smart Translation**: Real-time translation between English, Urdu, Arabic, and French.

### 🌍 Multilingual Support
Built-in high-quality layouts for:
- **English** (QWERTY)
- **Urdu**
- **Arabic**
- *Easy cycling between languages with a single tap.*

### 🎨 Multimedia & Rich Content
- **Giphy Integration**: Search and share trending GIFs and stickers directly from the keyboard.
- **Emoji Picker**: Quick access to all your favorite emojis.
- **Clipboard History**: Access your last 4 copied items for rapid pasting.

### 🎙️ Advanced Input
- **Voice Typing**: Integrated voice input with real-time transcription.
- **Haptic Feedback**: Premium tactile feel on every keypress.
- **Sleek UI**: Modern dark-themed design with smooth animations.

---

## 🛠️ Tech Stack
- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **AI Backend**: [Groq AI API](https://groq.com)
- **Multimedia**: [Giphy SDK/API](https://developers.giphy.com)
- **Platform**: Android (Custom Input Method Service)

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / VS Code
- Groq API Key
- Giphy API Key

### Setup
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Abdulrahman50ab/AI-keyboard.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure API Keys**:
   - Copy `config.json.example` to `config.json`.
   - Add your API keys to the `config.json` file.
   - *Note: Ensure `config.json` is in your `.gitignore` to keep your keys private.*

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## ⚠️ Security Warning
> [!WARNING]
> Never hardcode your API keys in `constants.dart` or any file tracked by Git. Use the provided `config.json` approach or environment variables to keep your secrets safe and avoid repository blocks.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
