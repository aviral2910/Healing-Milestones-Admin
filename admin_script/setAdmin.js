const admin = require('firebase-admin');

// IMPORTANT: Replace this with your email
const ADMIN_EMAIL = 'admin@healingmilestones.com';

// IMPORTANT: You need to download your service account key from the Firebase Console:
// Project Settings -> Service Accounts -> Generate New Private Key
// Save it as 'serviceAccountKey.json' in this directory.
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function setAdmin() {
  try {
    const user = await admin.auth().getUserByEmail(ADMIN_EMAIL);

    // Set admin privilege on the user corresponding to uid.
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });

    console.log(`Success! ${ADMIN_EMAIL} has been made an admin.`);
    console.log('If you are already logged in to the app, you will need to log out and log back in for the changes to take effect.');
    process.exit(0);
  } catch (error) {
    console.error('Error making user admin:', error);
    process.exit(1);
  }
}

setAdmin();
