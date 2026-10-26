<h1 align="center">🏋️ WorkoutApp</h1>
<p align="center"><b>An AI-powered Flutter fitness app with AI weekly plans, guided workouts and progress tracking.</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/AI-Google%20Gemini-8E75B2?logo=googlegemini" alt="Gemini" />
  <img src="https://img.shields.io/badge/Storage-SQLite-003B57?logo=sqlite" alt="SQLite" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen" alt="Platform" />
</p>

---

## 📖 Overview

FitForge builds a weekly workout plan around your body, goals and equipment using the **Google Gemini API**, then guides you through each session with exercise demonstrations and rest timers. Your profile, plans and workout history are saved on the device, so saved plans and past workouts are available offline.


---

## ✨ Features

### 1. AI-Generated Weekly Plans
Generates a seven-day plan with the **Gemini API** from your profile, goal, experience level, available equipment, session length, injuries and focus area.

<p align="center"><img width="1080" height="2400" alt="Screenshot_1793023596" src="https://github.com/user-attachments/assets/4cccdc03-706d-4d48-b070-25e40442a602" /></p>

---

### 2. Guided Workouts
Follow sessions with GIF demonstrations, rest periods and progress indicators. An interrupted workout can be saved and resumed.

<p align="center"> <img width="1080" height="2400" alt="Screenshot_1793024791" src="https://github.com/user-attachments/assets/d5aa3145-36a4-46b1-8d3c-3081e6f6b7a5" /></p>

---

### 3. Exercise Discovery
Search and browse the bundled exercise catalog, filter by category and open exercise details.

<p align="center"> <img width="1080" height="2400" alt="Screenshot_1793024439" src="https://github.com/user-attachments/assets/cf96fb40-d607-4da4-91c0-822dbaf3d37f" />
</p>

---

### 4. Progress Reports
Review recorded workouts, duration and estimated calories burned.

<p align="center"> <img width="1080" height="2400" alt="Screenshot_1793024905" src="https://github.com/user-attachments/assets/78460801-846b-42d1-8887-71bbf4cc15fa" />
</p>

---

### 5. Local Profile, Plans and Settings
Manage your profile and preferences. Saved plans and workout history are stored locally on the device.

<p align="center"> <img width="1080" height="2400" alt="Screenshot_1793024989" src="https://github.com/user-attachments/assets/137b19f3-8f4a-45ed-8c27-f364141f8fb9" />
</p>

---

## 🤖 How AI Plan Generation Works


<p align="center"><img width="1672" height="941" alt="AI Workout Plan Generation Flow" src="https://github.com/user-attachments/assets/0a4e742a-2683-49fb-9b62-88db143b3082" /></p>

---

## 🛠 Tech Stack

| Area | Technology |
|:---|:---|
| Framework | Flutter, Dart 3.0+ |
| AI | Google Gemini API (`google_generative_ai`) |
| Local database | SQLite (`sqflite`) |
| Preferences | `shared_preferences` |
| Assets | Bundled exercise catalog (`exercises.json`), GIFs and images |

## 🏗 Architecture

The app separates responsibilities into layers:

- **Models:** exercise and user profile data classes
- **Repositories:** local profile and workout-history persistence
- **Services:** Gemini plan generation, exercise data and local storage
- **Screens:** training, discovery, report, settings and planner views

---

## 🚀 Getting Started

**Requirements:** Flutter SDK (Dart 3.0+), Android Studio or Xcode, and a Gemini API key from [Google AI Studio](https://aistudio.google.com/).

```bash
git clone https://github.com/SachinMugade8797/WorkoutApp.git
cd WorkoutApp
flutter pub get
flutter run
```

Add your own Gemini API key where the app reads it (never commit a real key to the repository).

Build a release APK:

```bash
flutter build apk
```

## 📂 Project Structure

```text
lib/
  models/        Exercise and user profile models
  repositories/  Local profile and workout-history persistence
  screens/       Training, discovery, report, settings and planner views
  services/      Gemini plan generation, exercise data and local storage
assets/
  exercises.json Bundled exercise catalog
  gifs/          Exercise demonstrations
  images/        App imagery
```

## 🔒 Data and Privacy

Profile data, saved plans and workout history are stored locally using SQLite and `shared_preferences`. Profile inputs are sent to the Gemini API only when a plan is generated.

---

## 👤 Author

**Sachin Mugade**
[GitHub](https://github.com/SachinMugade8797) · [LinkedIn](https://linkedin.com/in/sachin-mugade-7a3545306)
