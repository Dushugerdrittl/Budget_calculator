# Hello Kitty Budget App 🎀

A charming and functional budget and expense tracking application with a Hello Kitty theme, built with Flutter.

**Owner:** Master Nithin sai koushik kancharla

## 🌟 Features

*   **User Authentication:** Secure login and registration using Firebase Authentication.
*   **Expense Tracking:** Add, edit, and delete expenses.
*   **Subscription Management:** Track recurring subscriptions, mark them as paid, and set reminders.
*   **Category Management:** Create and manage custom expense categories with optional monthly budgets.
*   **Savings Goals:** Set and track progress towards savings goals.
*   **Data Visualization:**
    *   Pie chart for spending by category with custom date range selection.
    *   Bar chart for spending over time (daily, weekly, monthly, yearly).
    *   Monthly and Yearly summary views.
*   **Notifications & Reminders:**
    *   Reminders for upcoming subscription payments.
    *   Alerts for category budget limits (80% warning, 100% exceeded).
    *   Notifications when savings goals are reached.
*   **Data Persistence:**
    *   Online data storage with **Firestore** (for expenses, subscriptions, categories, savings goals).
    *   Local caching with **Hive** for faster access and offline capabilities.
*   **User Profile:** View user email, UID, and edit display name.
*   **Password Reset:** Users can request a password reset email.
*   **Data Management:**
    *   Export data to CSV.
    *   Import data from CSV.
    *   Clear all user data.
*   **Theming:**
    *   Light and Dark mode support.
    *   Custom "Hello Kitty" inspired pinkish light girly color scheme.
    *   Custom icons for bottom navigation.
*   **UI Enhancements:**
    *   Welcome animation on login/registration.
    *   Animated page transitions.
    *   Animated list items for expenses and subscriptions.
*   **Currency Customization:** Select default currency (Dollars, Rupees, Yen, Euros).

## 🛠️ Technologies Used

*   **Flutter:** For building the cross-platform mobile application.
*   **Dart:** Programming language for Flutter.
*   **Firebase:**
    *   **Firebase Authentication:** For user login and registration.
    *   **Cloud Firestore:** As the primary online database.
*   **Hive:** For local data storage and caching.
*   **`flutter_local_notifications`:** For scheduling and displaying local notifications.
*   **`fl_chart`:** For creating interactive charts.
*   **`intl`:** For date formatting.
*   **`shared_preferences`:** For storing app settings like theme mode and default currency.
*   **`path_provider`:** For accessing file system paths (used in data export/import).
*   **`csv`:** For CSV data conversion.
*   **`share_plus`:** For sharing exported CSV files on mobile.
*   **`file_picker`:** For picking CSV files to import.
*   **`animations`:** For page transition animations.

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK: Install Flutter
*   An editor like VS Code or Android Studio.
*   A Firebase project set up with Authentication and Firestore enabled.

### Setup

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd expance
    ```

2.  **Set up Firebase:**
    *   Place your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files into the respective `android/app` and `ios/Runner` directories. You can get these from your Firebase project settings.
    *   Ensure you have enabled Email/Password sign-in in Firebase Authentication.
    *   Set up Firestore database rules as needed for security.

3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

4.  **Run Hive code generation (if you modify models):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

5.  **Run the app:**
    ```bash
    flutter run
    ```

## 📝 Future Enhancements (Ideas)

*   Biometric authentication.
*   More detailed reporting and filtering options.
*   Enhanced UI/UX with more custom Hello Kitty assets.
*   Recurring transaction automation.

---

*This app is a delightful way to manage your finances with a touch of cuteness!* 💖