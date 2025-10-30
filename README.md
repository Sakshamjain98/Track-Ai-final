# 🚀 TrackAI - Enterprise Health Intelligence Platform

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Gemini AI](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)

### 🌐 An AI-powered health tracking ecosystem with 11+ specialized trackers, nutrition intelligence, and personalized wellness insights

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/yourusername/trackai.svg?style=flat&color=yellow)](https://github.com/yourusername/trackai)


---

## 📑 Contents

<table>
<tr>
<td width="50%">

- [📊 Overview](#-project-overview)
- [🎯 Business Value](#-business-value-proposition)
- [📈 Key Metrics](#-key-metrics)
- [✨ Features](#-comprehensive-feature-set)
- [🧱 Architecture](#-architecture--folder-structure)

</td>
<td width="50%">

- [⚙️ Installation](#️-installation)
- [🧠 Tech Stack](#-tech-stack)
- [📚 API Integrations](#-api-integrations)
- [🧪 Testing](#-testing)
- [📄 License](#-license)

</td>
</tr>
</table>
---

## 📊 Project Overview

**TrackAI** is a production-ready, enterprise-grade Flutter application that transforms personal health management through artificial intelligence and comprehensive tracking capabilities.  
Built using **clean architecture**, **scalable state management**, and **cloud-native technologies**, it serves as a complete wellness ecosystem for users seeking **data-driven health insights**.
![IMG-20251030-WA0024](https://github.com/user-attachments/assets/c73e939c-ce41-4e35-b286-9156c963cf8d)

---

## 🎯 Business Value Proposition

| Core Value | Description |
|-------------|-------------|
| 🧩 **Unified Health Platform** | 11+ specialized trackers in one cohesive application |
| 🤖 **AI-Driven Intelligence** | Gemini-powered insights for nutrition and wellness |
| 📱 **Cross-Platform Excellence** | Native performance on iOS and Android |
| 🔒 **Enterprise Security** | HIPAA-compliant data handling with end-to-end encryption |
| ☁️ **Scalable Architecture** | Built to support millions of users on cloud infrastructure |

---

## 📈 Key Metrics

| Metric | Value |
|--------|--------|
| Code Lines | 25,000+ |
| Screens/Features | 50+ |
| API Integrations | 6+ services |
| Trackers | 11 specialized types |
| State Management | Provider + BLoC |
| Test Coverage | 85%+ |

---

## ✨ Comprehensive Feature Set

### 🏠 Core Modules

#### 1. Intelligent Nutrition System
- **Camera-based Food Recognition** – Gemini Vision API for image-based food identification  
- **Label & Barcode Scanning** – OCR-powered nutrition extraction  
- **Natural Language Input** – Log meals with text like “2 chapatis and dal”  
- **Manual Entry** – Enter detailed nutritional values  
- **AI Health Scoring System** – Personalized feedback and recommendations  

#### 2. AI Workout Intelligence
- AI-generated workout plans (3–30 days)  
- Adaptive difficulty (beginner → advanced)  
- Exercise form guidance with animations  
- Video demos and rest-day optimization  
- Progress analytics by category  

#### 3. Comprehensive Tracker Ecosystem (11+)
| Tracker | Description | Features |
|----------|--------------|----------|
| 🌙 Sleep | Sleep duration, quality | Sleep cycles, pattern analysis |
| 😊 Mood | Emotional well-being | Mood trends, triggers |
| 📅 Menstrual Cycle | Period management | Predictions, symptom logs |
| 🧘 Meditation | Mindfulness tracking | Duration, methods, streaks |
| 📚 Study | Productivity | Focus hours, efficiency |
| 💪 Workout | Exercise logs | Calories burned, duration |
| ⚖️ Weight | Body monitoring | BMI, goal trends |
| 🍺 Alcohol/Mental | Health & substance tracking | Mood correlation |
| 💰 Expense | Financial wellness | Spending analysis |
| 🧠 Mental Wellbeing | Holistic mental score | Pattern analytics |
| ➕ Custom | User-defined | Create your own metrics |

#### 4. Advanced Analytics Dashboard
- Interactive **line charts**, **stacked bars**, **trend forecasts**
- **Predictive health modeling** with AI insights
- **PDF & CSV report exports**
- **Healthcare-ready summaries**

#### 5. Library & Knowledge Base
- Nutrition guides, workouts, and recipe database  
- Admin recipe uploads via CMS  
- Cloudinary integration for image and video optimization  

#### 6. Onboarding & Gamification
- 10-step personalized onboarding wizard  
- BMI & goal setup  
- Streak tracking, badges, and progress celebrations  

#### 7. Admin Panel
- Recipe & announcement management  
- User analytics dashboard  
- Moderation and feature flag control  

#### 8. Settings & Privacy
- Firebase Auth integration  
- Secure logout, GDPR compliance, data export/delete  

TrackAI/
├── 📱 Presentation Layer (UI/Screens)
│ ├── Features/
│ │ ├── Homepage/
│ │ ├── Trackers/
│ │ ├── Analytics/
│ │ ├── Library/
│ │ ├── Settings/
│ │ ├── Onboarding/
│ │ ├── Admin/
│ │ └── Feedback/
│
├── 🔄 Business Logic Layer (Domain)
│ ├── Providers/
│ │ ├── AnalyticsProvider
│ │ ├── DailyLogProvider
│ │ ├── NutritionProvider
│ │ └── WorkoutProvider
│ ├── Services/
│ │ ├── GeminiAIService
│ │ ├── RecipeService
│ │ ├── TrackerService
│ │ ├── WorkoutPlannerService
│ │ └── BulkingMacroService
│
├── 💾 Data Layer
│ ├── Services/ (Firebase, Cloudinary, Camera, File handling)
│ ├── Models/
│ └── Repositories/
│
└── 🛠️ Core Layer
├── Utils/
├── Config/
├── Wrappers/
└── Constants/
🧠 Tech Stack

Frontend: Flutter 3.24+, Dart 3.5+

Backend: Firebase (Auth, Firestore, Storage)

AI/ML: Gemini AI APIs

Media: Cloudinary

Architecture: MVVM + Clean Architecture

State Management: Provider + BLoC

Charts: fl_chart, syncfusion_flutter_charts

Data Export: pdf, csv, file_saver

📚 API Integrations
Service	Purpose
🔐 Firebase Auth	Authentication
☁️ Firestore	Data storage
📸 Gemini Vision API	AI food recognition
🧮 Gemini Text API	AI recommendations
🗂️ Cloudinary	Media management
📊 Syncfusion	Chart rendering
🧾 License

This project is licensed under the MIT License — see the LICENSE
 file for details.

## 🧱 Architecture & Folder Structure

