// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyD4IKPU04aT--qppe59hXPtd7GdhmrsbzY",
  authDomain: "smartbunda-d7761.firebaseapp.com",
  projectId: "smartbunda-d7761",
  storageBucket: "smartbunda-d7761.firebasestorage.app",
  messagingSenderId: "762965727838",
  appId: "1:762965727838:web:869adac9bbae1977c072cf",
  measurementId: "G-Y2LER6DEQ8",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { analytics };
export default app;
