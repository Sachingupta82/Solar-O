SolarO an assesmemt and planning tool for the nation

# SolarO 🌞

**An AI-powered assessment and planning tool for solar energy adoption**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Node.js](https://img.shields.io/badge/node.js-6DA55F?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/express.js-%23404d59.svg?style=for-the-badge&logo=express&logoColor=%2361DAFB)](https://expressjs.com/)

---

## 🚀 Demo Video

<!-- Replace with your actual demo video link -->
[![SolarO Demo](https://img.shields.io/badge/Watch%20Demo-YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtu.be/NCpaxDwRMdk)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Installation & Setup](#installation--setup)
- [Market Opportunity](#market-opportunity)
- [Revenue Model](#revenue-model)

---

## 🌟 Overview

SolarO is a revolutionary platform that automates solar rooftop assessments and simplifies solar adoption for both consumers and businesses. By leveraging GPS data, Google Maps integration, and advanced weather analytics, we eliminate the need for costly manual inspections while providing instant, accurate solar solutions.

---

## 🎯 Problem Statement

The solar industry faces several critical challenges:

- **Inefficient Manual Assessments**: Time-consuming and expensive site visits
- **Inaccessible Planning Tools**: Complex software requiring technical expertise
- **Complex Financial Estimations**: Unclear ROI calculations and cost projections
- **Customer Uncertainty**: Difficulty in evaluating rooftop suitability and energy savings
- **High Vendor Costs**: Expensive customer acquisition and assessment processes

These barriers significantly hinder the scalable adoption of renewable energy solutions.

---

## 💡 Solution

**SolarO** addresses these challenges through:

### 🤖 AI-Powered Automation
- Automated rooftop assessments using GPS and satellite imagery
- Google Maps integration for precise location analysis
- Weather data integration for optimal panel placement

### 📊 Smart Analytics
- Optimized solar panel layouts
- Instant quotations and financial projections
- AI-powered panel recommendations based on:
  - Local weather patterns
  - Energy consumption (electricity bills)
  - Available rooftop area
  - Geographic location parameters

### 🏪 Integrated Marketplace
- Verified vendor connections
- Transparent cost breakdowns
- Structured platform for manufacturers to list products
- Direct customer-vendor matching system

---

## ✨ Features

### For Consumers
- 📍 **GPS-Based Assessment**: Automatic rooftop analysis without site visits
- 💰 **Instant Quotations**: Real-time pricing and financial projections
- 🎯 **Personalized Recommendations**: Perfect-fit solar panels for your specific needs
- 📈 **ROI Calculator**: Clear energy savings and payback period analysis
- 🔗 **Vendor Matching**: Connect with verified local installers

### For Vendors & Manufacturers
- 🏢 **Marketplace Access**: List products and services
- 👥 **Customer Discovery**: Find qualified leads
- 📊 **Analytics Dashboard**: Track performance and market insights
- 💼 **Business Tools**: Quotation management and customer communication

### Technical Features
- 🗺️ **Google Maps Integration**: Satellite imagery analysis
- 🌤️ **Weather Data Processing**: Climate-optimized recommendations
- 📱 **Cross-Platform Mobile App**: Flutter-based responsive design
- ⚡ **Fast Backend**: Node.js with Express.js for optimal performance

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language for Flutter

### Backend
- **Node.js** - JavaScript runtime environment
- **Express.js** - Web application framework
- **RESTful APIs** - Communication between frontend and backend

### APIs & Services
- **Google Maps API** - Satellite imagery and location services
- **Weather APIs** - Climate data integration
- **GPS Services** - Location-based assessments

---

## 📁 Project Structure

```
SolarO/
├── backend/                
│   ├── routes/             
│   ├── models/             
│   ├── controllers/       
│   ├── middleware/        
│   └── package.json        
├── frontend/               
│   ├── lib/
│   │   ├── screens/        
│   │   ├── widgets/        
│   │   └── utils/         
│   └── main.dart
|   └── pubspec.yaml        
├── README.md              
└── package-lock.json       
```

---

## 🚀 Installation & Setup

### Prerequisites

Before running this project, make sure you have the following installed:

- **Flutter SDK** (>=3.0.0)
- **Dart SDK** (>=2.17.0)
- **Node.js** (>=16.0.0)
- **npm** 
- **Android Studio** 

### Backend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/sachingupta82/Solar-O.git
   cd Solar-O
   ```

2. **Navigate to backend directory**
   ```bash
   cd backend
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Set up environment variables**
   ```bash
   # Create .env file in backend directory
   cp .env.example .env
   
   # Add your API keys and configuration
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key
   WEATHER_API_KEY=your_weather_api_key
   WEATHER_BIT_API_KEY=your_weather_api_key
   PORT=3000
   ```

5. **Start the backend server**
   ```bash
   npm start
   # or for development
   npm run dev
   ```

   The backend server will start on `http://localhost:3000`

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd ../frontend
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoints**
   ```dart

   class ApiConfig {
     static const String baseUrl = 'http://localhost:3000/api';
   }
   ```

4. **Run the Flutter app**
   ```bash
   # For Android
   flutter run
   
   # For iOS
   flutter run -d ios
   
   ```

### Testing the Application

1. **Backend API Testing**
   ```bash
   cd backend
   npm test
   ```

2. **Flutter Testing**
   ```bash
   cd frontend
   flutter test
   ```

## 📈 Market Opportunity

### Market Size & Growth
- **Current Market**: $10.4B (2023)
- **Projected Market**: $24.9B (2030)
- **Current Adoption**: Only 1.7% in India
- **Growth Rate**: 13.5% CAGR

### Target Segments
- **Residential**: Homeowners seeking solar solutions
- **Commercial**: Small to medium businesses
- **Industrial**: Manufacturing and commercial complexes
- **Vendors**: Solar installers and manufacturers

---

## 💰 Revenue Model

### Primary Revenue Streams

1. **Subscription-Based Model**
   - Monthly/Annual subscriptions for vendors
   - Premium features for enhanced analytics
   - Advanced reporting and insights

2. **Pay-Per-Quotation Model**
   - Commission on successful quotations
   - Lead generation fees
   - Transaction-based revenue

3. **Marketplace Fees**
   - Vendor listing fees
   - Featured placement charges
   - Premium vendor profiles

---

## 👥 Team

- **Frontend Developer**: [Sachinkumar Gupta]
- **Backend Developer**: [Sahil Kavatkar]

### Upcoming Features
- [ ] Real-Time Voice Assistant - Highlighted the bilingual (Hindi/English) capabilities and intelligent voice interaction
- [ ] User-Focused Smart Chatbot - Detailed the instant assistance and issue resolution capabilities
- [ ] IoT integration for real-time monitoring
- [ ] Shadow Analysis - Emphasized the advanced rooftop shadow detection for accurate energy calculations
- [ ] Vendor Subscription Access - Outlined the PDF/API quotation delivery and CRM integration features
- [ ] Manufacturer Spotlight - Described the targeted promotion and market visibility features

---

*Empowering India's transition to renewable energy, one rooftop at a time.*
