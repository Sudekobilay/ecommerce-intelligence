# 🛒 E-Commerce Intelligence: End-to-End Analytics & Decision Engine

[![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Render](https://img.shields.io/badge/Render-Cloud%20PaaS-black?style=flat&logo=render&logoColor=white)](https://render.com/)
[![Python](https://img.shields.io/badge/Python-3.11%2B-blue?style=flat&logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

An enterprise-grade, full-stack intelligence system combining unsupervised machine learning, production REST APIs, and a cross-platform mobile dashboard to drive data-informed customer segmentation, predictive what-if simulations, and personalized cross-sell recommendations.

---

## 🔗 Live Deployments & Demos

* 🌐 **Live API Documentation (Swagger UI):** [https://ecommerce-intelligence.onrender.com/docs](https://ecommerce-intelligence.onrender.com/docs)
* 📱 **Android Client (Pre-release APK):** [Download Latest APK (v1.5.0-beta)](https://github.com/Sudekobilay/ecommerce-intelligence/releases)

---

## 📐 System Architecture

The project follows a decoupled, three-tier architecture ensuring scalability, clean separation of concerns, and cloud-native resilience:

<pre>
[ Raw Transaction Logs ]
         │
         ▼
[ ML Pipeline: Pandas / Scikit-Learn / Mlxtend ]
   ├── RFM Feature Engineering
   ├── K-Means Clustering (Segmentation Engine)
   └── Apriori Algorithm (Market Basket Analysis)
         │
         ▼ Serialized Models (.joblib)
[ Backend Layer: FastAPI + Uvicorn ]
   ├── /api/v1/customer/{customer_id}  (Live Segmentation)
   ├── /api/v1/recommendations         (Cross-sell Rules)
   └── /api/v1/simulate                (What-If Churn & Health Projections)
         │
         ▼ Cloud PaaS Deployment (Render / TLS/HTTPS)
[ Mobile Presentation Layer: Flutter & Dart ]
   ├── Role-Based Access Control (RBAC: Executive vs. Marketing)
   ├── Dynamic Time-Filtered KPI Cockpit (All, 30D, 7D)
   ├── Interactive Customer Search & What-If Simulator
   └── Smart Basket Recommendation & Apriori Drawer
</pre>

---

## 🛠️ Key Capabilities & Core Modules

### 1. Machine Learning & Behavioral Analytics
* **RFM Feature Matrix:** Computes Recency, Frequency, and Monetary scores across transactional e-commerce histories.
* **K-Means Clustering:** Segments customers into distinct behavioral personas (*Champions*, *Loyal Customers*, *At-Risk*, *Hibernating*) using normalized logarithmic transformations.
* **Association Rule Mining:** Generates dynamic product association pairs based on support, confidence, and lift thresholds using the Apriori algorithm.
* **Predictive Churn & Health Modeling:** Evaluates Customer Health Scores (CHS) and simulates behavioral shifts.

### 2. High-Performance Cloud API
* Built with **FastAPI** leveraging asynchronous request handling.
* Deployed on **Render** cloud infrastructure with containerized buildpacks and automated SSL/TLS termination.
* Auto-generated interactive documentation via **Swagger / OpenAPI 3.0**.

### 3. Cross-Platform Mobile Dashboard & RBAC
* Developed with **Flutter** for responsive performance on Android, iOS, and Web.
* **Role-Based Access Control (RBAC):** Secure login flow distinguishing *Executives (C-Level)* with full financial cockpit visibility from *Marketing Specialists* focused on Customer 360° and cross-sell tools.
* **Dynamic Time-Filtered KPIs:** Instant recalculations across macro financial indicators based on custom temporal ranges (*All, 30 Days, 7 Days*).
* **What-If Scenario Simulator:** Interactive sliders projecting health score deltas and churn probability shifts based on anticipated marketing actions.

---

## 🚀 Local Development Setup

### 1. Clone the Repository
```bash
git clone [https://github.com/Sudekobilay/ecommerce-intelligence.git](https://github.com/Sudekobilay/ecommerce-intelligence.git)
cd ecommerce-intelligence
This project is open-source and licensed under the [MIT License](LICENSE).
