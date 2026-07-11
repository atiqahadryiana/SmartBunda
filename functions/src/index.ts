/**
 * SmartBunda — admin user-management Cloud Functions.
 *
 * `adminSetUserPassword` lets an authenticated ADMIN set another user's
 * password directly (the client SDK cannot do this — it requires the Admin
 * SDK's privileged access). The caller's admin role is verified server-side
 * against their Users/{uid}.role document, mirroring the Firestore security
 * rules, so a non-admin cannot invoke it even if they call it directly.
 */
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();

/** MOH/admin role values stored on Users/{uid}.role (case-insensitive). */
const ADMIN_ROLES = new Set(["admin"]);

/** Minimum password length — keep in sync with the app's password policy. */
const MIN_PASSWORD_LENGTH = 6;

/** Throws unless the caller is signed in AND has the admin role. */
async function assertCallerIsAdmin(uid: string | undefined): Promise<void> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  const snap = await db.collection("Users").doc(uid).get();
  const role = String(snap.get("role") ?? "").toLowerCase();
  if (!ADMIN_ROLES.has(role)) {
    throw new HttpsError(
      "permission-denied",
      "Only administrators can set another user's password."
    );
  }
}

export const adminSetUserPassword = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  await assertCallerIsAdmin(callerUid);

  const targetUid = String(request.data?.uid ?? "").trim();
  const targetEmail = String(request.data?.email ?? "").trim();
  const newPassword = String(request.data?.newPassword ?? "");

  if (!targetUid && !targetEmail) {
    throw new HttpsError(
      "invalid-argument",
      "Provide the target user's uid or email."
    );
  }
  if (newPassword.length < MIN_PASSWORD_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `Password must be at least ${MIN_PASSWORD_LENGTH} characters.`
    );
  }

  // Resolve the target user (by uid when given, else by email).
  const auth = getAuth();
  const targetUser = targetUid
    ? await auth.getUser(targetUid).catch(() => null)
    : await auth.getUserByEmail(targetEmail).catch(() => null);

  if (!targetUser) {
    throw new HttpsError("not-found", "No matching user account was found.");
  }

  // An admin should not reset their own password this way (use the normal
  // change-password flow) — prevents accidental self-lockout patterns.
  if (targetUser.uid === callerUid) {
    throw new HttpsError(
      "failed-precondition",
      "Use Change Password to update your own account."
    );
  }

  await auth.updateUser(targetUser.uid, { password: newPassword });

  // Append-only audit entry (same collection the app reads for activity logs).
  await db.collection("AuditLogs").add({
    type: "passwordSetAdmin",
    actorId: callerUid,
    subjectId: targetUser.uid,
    description: `Admin set a new password for ${
      targetUser.email ?? targetUser.uid
    }`,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { ok: true, uid: targetUser.uid, email: targetUser.email ?? null };
});
