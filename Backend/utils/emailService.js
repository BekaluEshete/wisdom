require('dotenv').config();
const nodemailer = require('nodemailer');

// === CONFIG: READ FROM RENDER ENV (NO FALLBACKS) ===
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;
const SMTP_HOST = process.env.SMTP_HOST || 'smtp.gmail.com';
const SMTP_PORT = Number(process.env.SMTP_PORT) || 587;

// === FORCE OFF RESEND (NO DOMAIN YET) ===
const USE_RESEND = false;

// === CREATE GMAIL TRANSPORTER (PORT 587 ONLY) ===
const createTransporter = () => {
  return nodemailer.createTransport({
    host: SMTP_HOST,
    port: SMTP_PORT,
    secure: false, // TLS
    auth: {
      user: SMTP_USER,
      pass: SMTP_PASS,
    },
    tls: { rejectUnauthorized: false },
    connectionTimeout: 10000,
    greetingTimeout: 10000,
    socketTimeout: 10000,
  });
};

let transporter = createTransporter();

// === LOG CONFIG ON STARTUP ===
console.log('Email service: Gmail SMTP (Port 587)');
if (!SMTP_USER || !SMTP_PASS) {
  console.error('SMTP_USER or SMTP_PASS missing in environment!');
} else {
  console.log(`SMTP configured: ${SMTP_USER}`);
}

// === HTML EMAIL WRAPPER ===
const wrapEmail = (title, content) => `
  <div style="font-family: 'Segoe UI', sans-serif; background-color: #fdf9f4; padding: 40px 20px; border-radius: 12px; max-width: 600px; margin: auto; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
    <div style="text-align: center;">
      <h2 style="color: #A67B5B; font-size: 26px;">${title}</h2>
    </div>
    <div style="font-size: 16px; color: #555; line-height: 1.6;">
      ${content}
    </div>
    <hr style="border: none; border-top: 1px solid #e8ddd3; margin: 30px 0;" />
    <div style="font-size: 14px; color: #777; text-align: center;">
      <p>"She is clothed with strength and dignity, and she laughs without fear of the future."<br><strong>– Proverbs 31:25</strong></p>
      <p>Blessings,<br><strong>The WisdomWalk Team</strong></p>
    </div>
  </div>
`;

// === SEND EMAIL VIA SMTP ONLY ===
const sendEmailViaSMTP = async (to, subject, html) => {
  const mailOptions = {
    from: `"WisdomWalk" <${SMTP_USER}>`,
    to,
    subject,
    html,
    text: html.replace(/<[^>]*>/g, '').substring(0, 500),
  };

  console.log(`Attempting SMTP to: ${to}`);
  console.log(`   Subject: ${subject}`);
  console.log(`   Port: ${SMTP_PORT}`);

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`EMAIL SENT via Gmail: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error(`SMTP FAILED: ${error.code} - ${error.message}`);
    throw error;
  }
};

// === MAIN SEND EMAIL FUNCTION ===
const sendEmail = async (to, subject, html) => {
  if (USE_RESEND) {
    throw new Error('Resend is disabled. Set USE_RESEND = true only after domain verification.');
  }

  return await sendEmailViaSMTP(to, subject, html);
};

// === VERIFICATION EMAIL ===
const sendVerificationEmail = async (email, firstName, code) => {
  const content = `
    <p>Hi ${firstName || 'there'},</p>
    <p>Welcome to WisdomWalk! Please verify your email by using the following code:</p>
    <div style="font-size: 32px; font-weight: bold; color: #A67B5B; letter-spacing: 8px; text-align: center; padding: 20px; background-color: #f9f5f0; border-radius: 8px; margin: 20px 0;">
      ${code.match(/.{1}/g).join(' ')}
    </div>
    <p style="color: #888; font-size: 14px;">This code will expire in <strong>5 minutes</strong>.</p>
    <p>If you didn't create an account with WisdomWalk, please ignore this email.</p>
  `;
  await sendEmail(email, 'Verify Your Email - WisdomWalk', wrapEmail('Email Verification', content));
};

// === PASSWORD RESET ===
const sendPasswordResetEmail = async (email, code, firstName) => {
  const content = `
    <p>Hello ${firstName},</p>
    <p>We received a request to reset your password. Use the code below:</p>
    <div style="font-size: 28px; font-weight: bold; color: #A67B5B; text-align: center; letter-spacing: 6px;">
      ${code}
    </div>
    <p>This code will expire in 15 minutes.</p>
  `;
  await sendEmail(email, 'Reset Your Password - WisdomWalk', wrapEmail('Password Reset', content));
};

// === ADMIN NOTIFICATIONS ===
const sendAdminNotificationEmail = async (adminEmail, subject, message, user) => {
  const content = `
    <p>${message}</p>
    <h4>User Details:</h4>
    <ul>
      <li><strong>Name:</strong> ${user.firstName} ${user.lastName}</li>
      <li><strong>Email:</strong> ${user.email}</li>
      <li><strong>Date of Birth:</strong> ${user.dateOfBirth || 'N/A'}</li>
      <li><strong>Phone:</strong> ${user.phoneNumber || 'N/A'}</li>
      <li><strong>Location:</strong> ${user.location || 'N/A'}</li>
    </ul>
  `;
  await sendEmail(adminEmail, subject, wrapEmail(subject, content));
};

const sendUserNotificationEmail = async (userEmail, subject, message, firstName) => {
  const content = `<p>Hi ${firstName},</p><p>${message}</p>`;
  await sendEmail(userEmail, subject, wrapEmail(subject, content));
};

const sendReportEmailToAdmin = async (adminEmail, post, reportedBy) => {
  const content = `
    <p>A new report has been submitted.</p>
    <p><strong>Reported By:</strong> ${reportedBy}</p>
    <p><strong>Post ID:</strong> ${post.id}</p>
    <p><strong>Reason:</strong> ${post.reason}</p>
  `;
  await sendEmail(adminEmail, 'New Post Report - WisdomWalk', wrapEmail('Reported Content Alert', content));
};

const sendNewPostEmailToAdmin = async (adminEmail, post) => {
  const content = `
    <p>A new post has been published by <strong>${post.author}</strong>.</p>
    <p><strong>Title:</strong> ${post.title}</p>
    <p><strong>Category:</strong> ${post.category}</p>
    <p><strong>Preview:</strong> ${post.content.substring(0, 200)}...</p>
  `;
  await sendEmail(adminEmail, 'New Post Submitted - WisdomWalk', wrapEmail('New Community Post', content));
};

// === USER STATUS EMAILS ===
const sendBlockedEmailToUser = async (userEmail, reason, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Your account has been temporarily blocked:</p>
    <blockquote style="background:#fff4f4; padding:15px; border-left:4px solid #ff6b6b;">
      ${reason}
    </blockquote>
    <p>Contact support if you believe this was a mistake.</p>
  `;
  await sendEmail(userEmail, 'Account Blocked - WisdomWalk', wrapEmail('Account Notice', content));
};

const sendUnblockedEmailToUser = async (userEmail, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Your account has been <strong>unblocked</strong> and is now active!</p>
    <p>Welcome back to WisdomWalk</p>
  `;
  await sendEmail(userEmail, 'Account Unblocked - WisdomWalk', wrapEmail('You\'re Back Online!', content));
};

const sendBannedEmailToUser = async (userEmail, reason, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Your account has been <strong>permanently banned</strong>:</p>
    <blockquote style="background:#ffe6e6; padding:15px; border-left:4px solid #c00;">
      ${reason}
    </blockquote>
  `;
  await sendEmail(userEmail, 'Account Banned - WisdomWalk', wrapEmail('Account Termination', content));
};

// === SOCIAL NOTIFICATIONS ===
const sendLikeNotificationEmail = async (userEmail, likerName, postTitle) => {
  const content = `
    <p>Your post "<strong>${postTitle}</strong>" received a new like from <strong>${likerName}</strong>!</p>
    <p>Keep sharing your wisdom!</p>
  `;
  await sendEmail(userEmail, 'New Like on Your Post - WisdomWalk', wrapEmail('Post Appreciation', content));
};

const sendCommentNotificationEmail = async (userEmail, commenterName, comment, postTitle) => {
  const content = `
    <p><strong>${commenterName}</strong> commented on your post "<strong>${postTitle}</strong>":</p>
    <blockquote style="background:#f0f8ff; padding:15px; border-left:4px solid #1e90ff;">
      ${comment}
    </blockquote>
    <p>Join the conversation!</p>
  `;
  await sendEmail(userEmail, 'New Comment on Your Post - WisdomWalk', wrapEmail('New Comment Received', content));
};

// === EXPORT ALL FUNCTIONS ===
module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendAdminNotificationEmail,
  sendUserNotificationEmail,
  sendReportEmailToAdmin,
  sendNewPostEmailToAdmin,
  sendBlockedEmailToUser,
  sendUnblockedEmailToUser,
  sendBannedEmailToUser,
  sendLikeNotificationEmail,
  sendCommentNotificationEmail,
};