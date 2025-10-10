const admin = require("firebase-admin");
const cron = require("node-cron");
const nodemailer = require("nodemailer");
const serviceAccount = require("./serviceAccountKey.json");

// ✅ Init Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// ✅ Nodemailer setup (ku beddel email & app password sax ah)
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 465,
  secure: true, // 465 = secure, 587 = insecure
  auth: {
    user: "sumayh735@gmail.com",
    pass: "kuqo fmer odgv awqe", // <-- Gmail app password, hubi inuu sax yahay
  },
  tls: {
    rejectUnauthorized: false, // bypass self-signed cert issue
  },
});

// ✅ Function: expire approved events
async function expireEvents() {
  const now = new Date();
  console.log(`[${now.toISOString()}] ⏳ Running expire job...`);

  const snapshot = await db
    .collection("events")
    .where("status", "==", "Approved")
    .get();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const endDateTime = data.endDateTime?.toDate
      ? data.endDateTime.toDate()
      : null;

    if (!endDateTime) {
      console.log(
        `[${now.toISOString()}] ❌ Skipping event (invalid endDateTime): ${data.title}`
      );
      continue;
    }

    if (endDateTime < now) {
      console.log(`[${now.toISOString()}] ⚠️ Expiring event: ${data.title}`);

      // Update event status
      await doc.ref.update({ status: "Expired" });

      const organizerEmail = data.organizerEmail;
      if (!organizerEmail) {
        console.log(
          `[${now.toISOString()}] 🚫 No organizer email for event: ${data.title}`
        );
        continue;
      }

      // Hel user doc
      const userQuery = await db
        .collection("users")
        .where("email", "==", organizerEmail)
        .limit(1)
        .get();

      if (userQuery.empty) {
        console.log(
          `[${now.toISOString()}] 🚫 User not found for ${organizerEmail}`
        );
        continue;
      }

      const userDoc = userQuery.docs[0];
      const expiredCount = (userDoc.data().expiredCount || 0) + 1;
      await userDoc.ref.update({ expiredCount });

      // 📧 Send email warning
      const mailOptions = {
        from: '"Jazeera Admin" <sumayh735@gmail.com>',
        to: organizerEmail,
        subject: "⚠️ Event Expired",
        text: `Dear ${data.organizerName},\n\nYour event "${data.title}" has expired.\nExpired Count: ${expiredCount}\n\nRegards,\nJazeera Admin`,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log(
          `[${now.toISOString()}] 📧 Email sent to ${organizerEmail} (expiredCount=${expiredCount})`
        );
      } catch (e) {
        console.error(
          `[${now.toISOString()}] ❌ Email error to ${organizerEmail}:`,
          e
        );
      }

      // 🚫 Blacklist after 3
      if (expiredCount >= 3) {
        await userDoc.ref.update({
  isBlacklisted: true,
  blockedAt: admin.firestore.FieldValue.serverTimestamp(),
});
        console.log(
          `[${now.toISOString()}] 🚫 User ${organizerEmail} blacklisted (3 expired events)`
        );
      }
    }
  }
}

// 🚀 Script start
console.log("🚀 Script started!");

// Run once immediately
expireEvents();

// ✅ Run every 1 minute (Africa/Nairobi timezone)
try {
  cron.schedule("*/1 * * * *", expireEvents, {
    timezone: "Africa/Nairobi",
  });
  console.log("✅ Cron job scheduled (every 1 min, Africa/Nairobi)");
} catch (e) {
  console.error("❌ Cron error:", e);
}
