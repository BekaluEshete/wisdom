require('dotenv').config();
const nodemailer = require('nodemailer');

// Gmail configuration
const GMAIL_USER = process.env.GMAIL_USER || "temesgenmarie97@gmail.com";
const GMAIL_PASS = process.env.GMAIL_PASS || "cykl seqo wbfe yugb";

// Create transporter with better timeout settings
// Note: Render may block SMTP connections. If this fails, consider using SendGrid, Mailgun, or Resend
const createTransporter = (port = 465) => {
  return nodemailer.createTransport({
    service: 'gmail',
    host: 'smtp.gmail.com',
    port: port,
    secure: port === 465, // true for 465, false for 587
    auth: {
      user: GMAIL_USER,
      pass: GMAIL_PASS,
    },
    tls: {
      rejectUnauthorized: false
    },
    connectionTimeout: 60000, // 60 seconds - increased for cloud platforms
    greetingTimeout: 30000, // 30 seconds
    socketTimeout: 60000, // 60 seconds
    // Add pool configuration for better connection handling
    pool: true,
    maxConnections: 1,
    maxMessages: 3,
  });
};

// Try port 465 first (SSL), fallback to 587 (TLS) if needed
let transporter = createTransporter(465);

// Verify transporter configuration on startup (async)
(async () => {
  try {
    await transporter.verify();
    console.log('✅ Email transporter is ready to send emails (port 465)');
    console.log('Gmail user:', GMAIL_USER);
  } catch (error) {
    console.error('❌ Email transporter verification failed on port 465:', error.code);
    console.error('Will try port 587 when sending emails...');
    // Don't fail startup if verification fails - will try both ports when sending
  }
})();

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

const sendEmail = async (to, subject, html, retries = 2) => {
  let currentTransporter = transporter;
  let triedPort465 = false;
  let triedPort587 = false;
  
  for (let attempt = 1; attempt <= retries + 1; attempt++) {
    try {
      const mailOptions = {
        from: `"WisdomWalk" <${GMAIL_USER}>`,
        to,
        subject,
        html,
        // Add text version for better compatibility
        text: html.replace(/<[^>]*>/g, ''), // Strip HTML tags for text version
      };
      
      console.log(`📧 Attempting to send email to: ${to} (Attempt ${attempt}/${retries + 1})`);
      console.log(`   Subject: ${subject}`);
      console.log(`   From: ${GMAIL_USER}`);
      console.log(`   Using port: ${currentTransporter.options.port}`);
      
      const info = await currentTransporter.sendMail(mailOptions);
      console.log(`✅ Email sent successfully to ${to}`);
      console.log(`   MessageId: ${info.messageId}`);
      console.log(`   Response: ${info.response}`);
      return info;
    } catch (error) {
      console.error(`❌ Error sending email to ${to} (Attempt ${attempt}/${retries + 1}):`);
      console.error(`   Error message: ${error.message}`);
      console.error(`   Error code: ${error.code}`);
      console.error(`   Error command: ${error.command}`);
      console.error(`   Error response: ${error.response}`);
      
      // Provide more helpful error messages
      if (error.code === 'EAUTH') {
        console.error('   ⚠️  Authentication failed. Check Gmail app password.');
        throw error; // Don't retry auth errors
      } else if (error.code === 'ETIMEDOUT' || error.code === 'ECONNECTION') {
        // Try switching ports if we haven't tried both
        if (!triedPort587 && currentTransporter.options.port === 465) {
          console.error('   ⚠️  Connection timeout on port 465. Trying port 587...');
          triedPort465 = true;
          currentTransporter = createTransporter(587);
          triedPort587 = true;
          await new Promise(resolve => setTimeout(resolve, 1000));
          continue; // Retry with different port
        } else if (!triedPort465 && currentTransporter.options.port === 587) {
          console.error('   ⚠️  Connection timeout on port 587. Trying port 465...');
          triedPort587 = true;
          currentTransporter = createTransporter(465);
          triedPort465 = true;
          await new Promise(resolve => setTimeout(resolve, 1000));
          continue; // Retry with different port
        }
        
        console.error('   ⚠️  Connection timeout on both ports. Retrying...');
        if (attempt <= retries) {
          // Wait before retrying (exponential backoff)
          await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
          continue; // Retry
        } else {
          console.error('   ❌ All retry attempts failed. Connection timeout persists.');
          console.error('   💡 TIP: Render may block SMTP connections. Consider using SendGrid, Mailgun, or Resend.');
          throw error;
        }
      } else if (error.code === 'EENVELOPE') {
        console.error('   ⚠️  Invalid email address.');
        throw error; // Don't retry invalid email errors
      } else {
        // For other errors, retry once
        if (attempt <= retries) {
          await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
          continue;
        }
        throw error;
      }
    }
  }
};

const sendVerificationEmail = async (email, firstName, code) => {
  const content = `
    <p>Hi ${firstName || 'there'},</p>
    <p>Welcome to WisdomWalk! Please verify your email by using the following code:</p>
    <div style="font-size: 32px; font-weight: bold; color: #A67B5B; letter-spacing: 8px; text-align: center; padding: 20px; background-color: #f9f5f0; border-radius: 8px; margin: 20px 0;">${code}</div>
    <p style="color: #888; font-size: 14px;">This code will expire in 5 minutes.</p>
    <p>If you didn't create an account with WisdomWalk, please ignore this email.</p>
  `;
  await sendEmail(email, '🌸 Verify Your Email - WisdomWalk', wrapEmail('Email Verification', content));
};

const sendPasswordResetEmail = async (email, code, firstName) => {
  const content = `
    <p>Hello ${firstName},</p>
    <p>We received a request to reset your password. Use the code below:</p>
    <div style="font-size: 24px; font-weight: bold; color: #A67B5B; text-align: center;">${code}</div>
    <p>This code will expire in 15 minutes.</p>
  `;
  await sendEmail(email, '🔐 Reset Your Password - WisdomWalk', wrapEmail('Password Reset', content));
};

const sendAdminNotificationEmail = async (adminEmail, subject, message, user) => {
  const content = `
    <p>${message}</p>
    <h4>User Details:</h4>
    <ul>
      <li><strong>Name:</strong> ${user.firstName} ${user.lastName}</li>
      <li><strong>Email:</strong> ${user.email}</li>
      <li><strong>Date of Birth:</strong> ${user.dateOfBirth}</li>
      <li><strong>Phone:</strong> ${user.phoneNumber}</li>
      <li><strong>Location:</strong> ${user.location}</li>
    </ul>
  `;
  await sendEmail(adminEmail, subject, wrapEmail(subject, content));
};

const sendUserNotificationEmail = async (userEmail, subject, message, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>${message}</p>
  `;
  await sendEmail(userEmail, subject, wrapEmail(subject, content));
};

const sendReportEmailToAdmin = async (adminEmail, post, reportedBy) => {
  const content = `
    <p>A new report has been submitted.</p>
    <p><strong>Reported By:</strong> ${reportedBy}</p>
    <p><strong>Post ID:</strong> ${post.id}</p>
    <p><strong>Reason:</strong> ${post.reason}</p>
  `;
  await sendEmail(adminEmail, '🚨 New Post Report - WisdomWalk', wrapEmail('Reported Content Alert', content));
};

const sendNewPostEmailToAdmin = async (adminEmail, post) => {
  const content = `
    <p>A new post has been published by <strong>${post.author}</strong>.</p>
    <p><strong>Title:</strong> ${post.title}</p>
    <p><strong>Category:</strong> ${post.category}</p>
    <p><strong>Preview:</strong> ${post.content}</p>
  `;
  await sendEmail(adminEmail, '📝 New Post Submitted - WisdomWalk', wrapEmail('New Community Post', content));
};

const sendBlockedEmailToUser = async (userEmail, reason, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Your account has been temporarily blocked for the following reason:</p>
    <blockquote>${reason}</blockquote>
    <p>Please contact support if you believe this was a mistake.</p>
  `;
  await sendEmail(userEmail, '🚫 Account Blocked - WisdomWalk', wrapEmail('Account Notice', content));
};

const sendUnblockedEmailToUser = async (userEmail, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Your account has been unblocked and is now active.</p>
    <p>Welcome back to WisdomWalk 🌼</p>
  `;
  await sendEmail(userEmail, '✅ Account Unblocked - WisdomWalk', wrapEmail('You’re Back Online!', content));
};

const sendBannedEmailToUser = async (userEmail, reason, firstName) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Your account has been permanently banned for the following reason:</p>
    <blockquote>${reason}</blockquote>
    <p>You may contact our admin team for further details.</p>
  `;
  await sendEmail(userEmail, '❌ Account Banned - WisdomWalk', wrapEmail('Account Termination', content));
};

const sendLikeNotificationEmail = async (userEmail, likerName, postTitle) => {
  const content = `
    <p>Your post titled <strong>"${postTitle}"</strong> received a new like from <strong>${likerName}</strong>! 💖</p>
    <p>Keep sharing your wisdom!</p>
  `;
  await sendEmail(userEmail, '👍 New Like on Your Post - WisdomWalk', wrapEmail('Post Appreciation', content));
};

const sendCommentNotificationEmail = async (userEmail, commenterName, comment, postTitle) => {
  const content = `
    <p><strong>${commenterName}</strong> commented on your post <strong>"${postTitle}"</strong>:</p>
    <blockquote>${comment}</blockquote>
    <p>Join the conversation and connect with the community!</p>
  `;
  await sendEmail(userEmail, '💬 New Comment on Your Post - WisdomWalk', wrapEmail('New Comment Received', content));
};

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
