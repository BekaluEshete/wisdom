require('dotenv').config();
const nodemailer = require('nodemailer');

// Email service configuration
// Using Resend API (recommended for cloud platforms like Render)
// Fallback to Gmail SMTP if Resend is not configured
const RESEND_API_KEY = process.env.RESEND_API_KEY;
const GMAIL_USER = process.env.GMAIL_USER || "temesgenmarie97@gmail.com";
const GMAIL_PASS = process.env.GMAIL_PASS || "cykl seqo wbfe yugb";

// Use Resend if API key is available, otherwise use Gmail SMTP
const USE_RESEND = !!RESEND_API_KEY;

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

// Verify email service configuration on startup
(async () => {
  if (USE_RESEND) {
    console.log('✅ Using Resend API for email sending');
    console.log('   This is recommended for cloud platforms like Render');
  } else {
    console.log('⚠️  Using Gmail SMTP (may have connection issues on Render)');
    console.log('   To use Resend API, set RESEND_API_KEY environment variable');
    console.log('   Get free API key at: https://resend.com/api-keys');
    try {
      await transporter.verify();
      console.log('✅ Gmail SMTP transporter verified (port 465)');
    } catch (error) {
      console.error('❌ Gmail SMTP verification failed:', error.code);
      console.error('   Will try both ports when sending emails...');
    }
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

// Send email using Resend API (recommended for cloud platforms)
const sendEmailViaResend = async (to, subject, html) => {
  const https = require('https');
  const text = html.replace(/<[^>]*>/g, ''); // Strip HTML tags for text version
  
  const data = JSON.stringify({
    from: 'WisdomWalk <onboarding@resend.dev>', // You can verify your domain later
    to: [to],
    subject: subject,
    html: html,
    text: text,
  });

  const options = {
    hostname: 'api.resend.com',
    port: 443,
    path: '/emails',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Length': data.length,
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const result = JSON.parse(responseData);
          console.log(`✅ Email sent via Resend to ${to}`);
          console.log(`   Email ID: ${result.id}`);
          resolve(result);
        } else {
          const error = JSON.parse(responseData);
          reject(new Error(error.message || `Resend API error: ${res.statusCode}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
};

// Send email using Gmail SMTP (fallback)
const sendEmailViaSMTP = async (to, subject, html, retries = 2) => {
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
        text: html.replace(/<[^>]*>/g, ''),
      };
      
      console.log(`📧 Attempting to send email via SMTP to: ${to} (Attempt ${attempt}/${retries + 1})`);
      console.log(`   Using port: ${currentTransporter.options.port}`);
      
      const info = await currentTransporter.sendMail(mailOptions);
      console.log(`✅ Email sent successfully via SMTP to ${to}`);
      return info;
    } catch (error) {
      console.error(`❌ SMTP error (Attempt ${attempt}/${retries + 1}): ${error.code} - ${error.message}`);
      
      if (error.code === 'EAUTH') {
        throw error;
      } else if (error.code === 'ETIMEDOUT' || error.code === 'ECONNECTION') {
        if (!triedPort587 && currentTransporter.options.port === 465) {
          currentTransporter = createTransporter(587);
          triedPort587 = true;
          await new Promise(resolve => setTimeout(resolve, 1000));
          continue;
        } else if (!triedPort465 && currentTransporter.options.port === 587) {
          currentTransporter = createTransporter(465);
          triedPort465 = true;
          await new Promise(resolve => setTimeout(resolve, 1000));
          continue;
        }
        
        if (attempt <= retries) {
          await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
          continue;
        }
        throw error;
      } else {
        if (attempt <= retries) {
          await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
          continue;
        }
        throw error;
      }
    }
  }
};

// Main sendEmail function - uses Resend if available, otherwise SMTP
const sendEmail = async (to, subject, html) => {
  try {
    if (USE_RESEND) {
      console.log(`📧 Sending email via Resend API to: ${to}`);
      console.log(`   Subject: ${subject}`);
      return await sendEmailViaResend(to, subject, html);
    } else {
      console.log(`📧 Sending email via Gmail SMTP to: ${to}`);
      console.log(`   Subject: ${subject}`);
      console.log(`   ⚠️  Note: Using SMTP. For better reliability on Render, set RESEND_API_KEY`);
      return await sendEmailViaSMTP(to, subject, html);
    }
  } catch (error) {
    // If Resend fails and we have SMTP as backup, try SMTP
    if (USE_RESEND && !error.message.includes('Resend')) {
      console.error(`❌ Resend failed, trying SMTP fallback...`);
      try {
        return await sendEmailViaSMTP(to, subject, html);
      } catch (smtpError) {
        throw new Error(`Both Resend and SMTP failed. Resend: ${error.message}, SMTP: ${smtpError.message}`);
      }
    }
    throw error;
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
