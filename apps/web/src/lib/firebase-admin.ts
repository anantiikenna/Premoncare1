import * as admin from 'firebase-admin';

/**
 * Initialize Firebase Admin SDK
 * Uses environment variables for security.
 * Singleton pattern for Next.js development.
 */

const getFirebaseAdmin = () => {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  // Handle escaped newlines in private key if they were pasted as literals
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    console.warn('Firebase Admin credentials missing. FCM will be disabled.');
    return null;
  }

  if (admin.apps.length > 0) {
    return admin.app();
  }

  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });
};

export const firebaseAdmin = getFirebaseAdmin();
export const messaging = firebaseAdmin ? firebaseAdmin.messaging() : null;
