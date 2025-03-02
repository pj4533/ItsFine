Here's the initial spec for **ItsFine**, your AI-powered satirical RSS reader.  

---

### **ItsFine – MVP Specification**  

#### **Overview**  
ItsFine is an RSS reader that pulls in article headlines and allows users to transform them into progressively more optimistic and satirical versions using a simple gesture. The app uses OpenAI’s Chat Completions API to modify headlines in a structured, iterative way.  

---

### **Core Features**  

#### **1. RSS Feed Handling**  
- Fetches **headlines on app launch** (no periodic updates yet).  
- Uses **Foundation’s XMLParser** to parse RSS data (no third-party dependencies).  
- **Loads the first 10 headlines** initially (lazy loading).  
- Extracts and stores:  
  - **Title (headline)**  
  - **Article URL**  
  - **Publish date** (ignored in the UI for now).  
- Errors:  
  - **OSLog error messages** if parsing fails.  
  - Shows a **simple error dialog** if the feed cannot be loaded.  
  - **No user-facing message** if the feed is empty, but logs an error.  
- **Hardcoded single RSS feed** for now.  

---

#### **2. Headline Transformation**  
- User performs a **gesture** (flip phone over and back) to trigger headline transformation.  
- Headlines are sent to OpenAI’s **Chat Completions API** in a **single batch** request.  
- **Thread-based conversation approach**:  
  - OpenAI gets the previous versions of the headline for context.  
  - Uses structured **JSON response** to return transformed headlines.  
  - The transformation process progresses through **5 levels**:  
    1. Initial convert  
    2. More optimistic  
    3. Even more optimistic  
    4. MORE OPTIMISM  
    5. Totally unhinged absolutely satirical level of optimism  
- If the API request **fails**, the app:  
  - **Reverts to the previous version of headlines.**  
  - **Shows an error dialog.**  
  - **Logs an error with OSLog.**  

---

#### **3. Gesture & Interaction**  
- Uses **accelerometer** to detect the flip motion.  
- Gesture **triggers animation and API request immediately**.  
- No extra visual feedback before transformation.  
- If **flipping is not easy to test in the iPhone simulator**, we’ll pick a different gesture.  
- No debounce or rate limiting for now.  

---

#### **4. Animation & UI**  
- **Custom animation** runs while OpenAI is processing:  
  - Gradual, **ever-evolving distortion effect** applied to all visible headlines.  
  - Effect continuously shifts while waiting for the response.  
  - Smooth transition to clear text when transformation completes.  
- **Headlines always allow multiple lines** (no truncation).  
- UI starts with **default styling**, but we may experiment with “headline-like” fonts later.  
- **Light mode only for now** (default appearance).  

---

#### **5. API Key Handling**  
- Uses a **git-ignored Swift file (`APIKeys.swift`)**:  
  ```swift
  struct APIKeys {
      static let openAIKey: String = "YOUR_KEY_HERE"
  }
  ```  
- If the key is missing or invalid:  
  - **Shows an error dialog.**  
  - **Logs an OSLog error.**  

---

#### **6. App Lifecycle**  
- **Resets headlines and transformations on app restart** (no persistence).  
- **Spinner loading indicator** while fetching RSS feed.  
- **No user interactions while API request is in flight.**  

---

### **Next Steps & Future Enhancements (Post-MVP)**  
✅ Handle user-added RSS feeds.  
✅ Improve gesture sensitivity & detectability.  
✅ Allow users to “undo” transformations.  
✅ Support tap-to-open article links.  
✅ Enhance UI with better fonts and styling.  
✅ Support dark mode.  

---

This covers the **full MVP spec** for **ItsFine**. You can now hand this off to a developer, or we can refine details as needed. 🚀 Let me know what you think!