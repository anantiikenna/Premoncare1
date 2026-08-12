import * as admin from 'firebase-admin';

let _app: admin.app.App | null = null;

function getFirebaseAdmin(): admin.app.App | null {
  if (_app) return _app;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    return null;
  }

  if (admin.apps.length > 0) {
    _app = admin.apps[0]!;
    return _app;
  }

  _app = admin.initializeApp({
    credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
  });
  return _app;
}

export function getMessaging(): admin.messaging.Messaging | null {
  const app = getFirebaseAdmin();
  return app ? app.messaging() : null;
}
