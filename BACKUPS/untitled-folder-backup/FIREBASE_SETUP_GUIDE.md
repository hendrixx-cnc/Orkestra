# Firebase Setup Guide for The Quantum Self

**Date:** October 17, 2025  
**Status:** 📋 Setup Instructions  
**Purpose:** Add Firebase for hosting, authentication, and optional real-time sync

---

## 🎯 What Firebase Can Provide

### Current Use Cases:
1. **Frontend Hosting** - Deploy React app to Firebase Hosting
2. **Backend Hosting** - Deploy Node.js backend to Firebase Functions (optional)
3. **Authentication** - Firebase Auth (alternative to current JWT system)
4. **Real-time Database** - Optional sync for reflections across devices
5. **Cloud Storage** - Photo uploads for reflections

### Recommended for This Project:
- ✅ **Firebase Hosting** - Fast, free, SSL included
- ⏸️ **Firebase Auth** - Optional (we have working JWT auth)
- ⏸️ **Firestore** - Optional (we have working PostgreSQL)

---

## 📝 Step 1: Create Firebase Project

### If You Don't Have a Firebase Account:
1. Go to https://console.firebase.google.com/
2. Click "Add project"
3. Project name: **the-quantum-self**
4. Enable Google Analytics (optional)
5. Create project

### If You Already Have Firebase Info:
**Please provide:**
- Firebase Project ID
- Web app API key
- Any existing Firebase config object

---

## 🔧 Step 2: Get Firebase Configuration

### In Firebase Console:
1. Click ⚙️ (Settings) → Project settings
2. Scroll to "Your apps" section
3. Click "Web" (</>) icon
4. Register app: "The Quantum Self Web App"
5. Copy the `firebaseConfig` object:

```javascript
// Example (your actual values will be different)
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "the-quantum-self.firebaseapp.com",
  projectId: "the-quantum-self",
  storageBucket: "the-quantum-self.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:xxxxxxxxxxxxx"
};
```

---

## 📦 Step 3: Add Firebase to Project

### Install Firebase SDK:
```bash
cd /workspaces/The-Quantum-Self-/2_The-Quantum-World
npm install firebase
npm install -D firebase-tools
```

### Create Firebase Config File:
**File:** `2_The-Quantum-World/src/services/firebase.js`

```javascript
import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

// Your Firebase configuration
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize services (only if needed)
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
```

---

## 🔐 Step 4: Add Environment Variables

### Update `.env` file:
**File:** `2_The-Quantum-World/.env`

```properties
# Existing variables...

# Firebase Configuration
VITE_FIREBASE_API_KEY=your_api_key_here
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
VITE_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=123456789012
VITE_FIREBASE_APP_ID=1:123456789012:web:xxxxx
```

### Update `.env.production.example`:
Add the same variables with placeholder values for documentation.

---

## 🚀 Step 5: Deploy to Firebase Hosting

### Initialize Firebase in Project:
```bash
cd /workspaces/The-Quantum-Self-/2_The-Quantum-World
npx firebase login
npx firebase init hosting
```

**Configuration:**
- Use existing project: Select your Firebase project
- Public directory: **dist**
- Single-page app: **Yes**
- GitHub deploys: **No** (or Yes if you want CI/CD)

### Build and Deploy:
```bash
# Build production bundle
npm run build

# Deploy to Firebase
npx firebase deploy --only hosting
```

### Your app will be live at:
`https://your-project-id.web.app`

---

## 🔄 Optional: Firebase Integration Features

### 1. Photo Uploads to Firebase Storage
```javascript
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { storage } from './firebase';

async function uploadReflectionPhoto(file, userId, reflectionId) {
  const storageRef = ref(storage, `reflections/${userId}/${reflectionId}`);
  await uploadBytes(storageRef, file);
  const url = await getDownloadURL(storageRef);
  return url;
}
```

### 2. Real-time Reflection Sync (Optional)
```javascript
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { db } from './firebase';

async function syncReflection(userId, moduleId, promptId, text) {
  const docRef = doc(db, 'reflections', `${userId}_${moduleId}_${promptId}`);
  await setDoc(docRef, {
    text,
    moduleId,
    promptId,
    userId,
    timestamp: new Date().toISOString()
  });
}
```

---

## 📋 Quick Deployment Checklist

- [ ] Create Firebase project in console
- [ ] Get Firebase config object
- [ ] Install firebase and firebase-tools packages
- [ ] Create `src/services/firebase.js` config file
- [ ] Add Firebase env variables to `.env`
- [ ] Initialize Firebase hosting
- [ ] Build production bundle (`npm run build`)
- [ ] Deploy to Firebase (`firebase deploy --only hosting`)
- [ ] Test deployed app
- [ ] Update DNS to point custom domain (optional)

---

## 🎯 Recommended Approach

### Phase 1: Hosting Only (Fastest)
✅ Use Firebase Hosting for frontend  
✅ Keep PostgreSQL backend on Railway/Render  
✅ Keep JWT authentication (already working)  
⏱️ **Time:** 30 minutes

### Phase 2: Add Storage (Optional)
✅ Enable Firebase Storage for photo uploads  
✅ Replace local file uploads with cloud storage  
⏱️ **Time:** 1-2 hours

### Phase 3: Real-time Sync (Optional)
✅ Add Firestore for cross-device sync  
✅ Keep PostgreSQL for main data, Firestore for real-time features  
⏱️ **Time:** 3-4 hours

---

## 💡 Cost Estimate

### Firebase Free Tier (Spark Plan):
- **Hosting:** 10 GB storage, 360 MB/day transfer ✅ Sufficient
- **Storage:** 5 GB, 1 GB/day download ✅ Sufficient
- **Firestore:** 1 GB storage, 50K reads/day ✅ Sufficient for start

### Upgrade only if you exceed free tier limits.

---

## 🆘 If You Have Existing Firebase Info

**Please provide any of these:**
1. Firebase Project ID
2. Firebase config object (from console)
3. Existing Firebase account email
4. Any Firebase .json key files

I can then:
- Configure the project automatically
- Add environment variables
- Set up deployment scripts
- Test hosting deployment

---

## 📞 Next Steps

To proceed, you can either:

1. **Share Firebase Config** - If you have existing Firebase project info
2. **Create New Project** - Follow Step 1-2 above and share the config
3. **Deploy Without Firebase** - Use Vercel/Netlify instead (already documented in DEPLOYMENT.md)

Let me know which approach you'd like to take! 🚀
