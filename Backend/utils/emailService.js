const nodemailer = require('nodemailer');
require('dotenv').config();

// Initialize Transporter with Gmail (Configured for Port 587 STARTTLS)
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false, // Use STARTTLS (Port 587)
  auth: {
    user: process.env.GMAIL_USER || process.env.EMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
  // Increased timeouts for Render environment
  connectionTimeout: 20000,
  greetingTimeout: 20000,
  socketTimeout: 30000,
  // Detailed logging for debugging
  debug: true,
  logger: true,
});

console.log('🔧 Email Service: Using Nodemailer (Gmail STARTTLS 587 + Debug)');

const wrapEmail = (title, content) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
</head>
<body style="font-family: 'Segoe UI', Arial, sans-serif; background-color: #fdf9f4; margin: 0; padding: 20px;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 40px 20px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
    <div style="text-align: center; margin-bottom: 30px;">
      <h2 style="color: #A67B5B; font-size: 26px; margin: 0;">${title}</h2>
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
</body>
</html>
`;

const sendEmail = async (to, subject, html) => {
  console.log(`📧 Attempting to send email to: ${to}`);

  try {
    const info = await transporter.sendMail({
      from: `"WisdomWalk" <${process.env.GMAIL_USER || process.env.EMAIL_USER}>`,
      to: to,
      subject: subject,
      html: html,
    });

    console.log('✅ Email sent successfully via Gmail!');
    console.log('   Message ID:', info.messageId);
    return info;
  } catch (error) {
    console.error('❌ Email Error:', error.message);
    throw error;
  }
};

const sendVerificationEmail = async (email, firstName, code) => {
  console.log(`🎯 Sending verification code [${code}] to ${email}`);

  try {
    const content = `
      <p>Hi <strong>${firstName}</strong>,</p>
      <p>Welcome to WisdomWalk! Please verify your email address by using the following verification code:</p>
      <div style="text-align: center; margin: 30px 0;">
        <div style="font-size: 32px; font-weight: bold; color: #A67B5B; letter-spacing: 8px; padding: 20px; background: #f9f3ee; border-radius: 8px; display: inline-block;">
          ${code}
        </div>
      </div>
      <p style="text-align: center; color: #777; font-size: 14px;">
        This verification code will expire in 24 hours.
      </p>
      <p>If you didn't create an account with WisdomWalk, please ignore this email.</p>
    `;

    return await sendEmail(email, 'Verify Your WisdomWalk Account', wrapEmail('Email Verification', content));
  } catch (error) {
    console.error('❌ Failed to send verification email:', error.message);
    throw error;
  }
};

const sendPasswordResetEmail = async (email, code, firstName) => {
  console.log(`🎯 Sending password reset to ${email}`);

  try {
    const content = `
      <p>Hello <strong>${firstName}</strong>,</p>
      <p>We received a request to reset your password for your WisdomWalk account.</p>
      <p>Please use the following code to reset your password:</p>
      <div style="text-align: center; margin: 30px 0;">
        <div style="font-size: 28px; font-weight: bold; color: #A67B5B; padding: 20px; background: #f9f3ee; border-radius: 8px; display: inline-block;">
          ${code}
        </div>
      </div>
      <p style="text-align: center; color: #d32f2f; font-size: 14px;">
        ⚠️ This code will expire in 15 minutes for security reasons.
      </p>
      <p>If you didn't request a password reset, please ignore this email and your password will remain unchanged.</p>
    `;

    await sendEmail(email, '🔐 Reset Your Password - WisdomWalk', wrapEmail('Password Reset', content));
    console.log('✅ Password reset email sent successfully!');
  } catch (error) {
    console.error('❌ Failed to send password reset email:', error.message);
    throw error;
  }
};

const sendAdminNotificationEmail = async (adminEmail, subject, message, user) => {
  try {
    const content = `
      <p>${message}</p>
      <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h4 style="color: #A67B5B; margin-top: 0;">User Registration Details:</h4>
        <ul style="list-style: none; padding: 0;">
          <li style="margin-bottom: 8px;"><strong>Name:</strong> ${user.firstName} ${user.lastName}</li>
          <li style="margin-bottom: 8px;"><strong>Email:</strong> ${user.email}</li>
          <li style="margin-bottom: 8px;"><strong>Date of Birth:</strong> ${user.dateOfBirth}</li>
          <li style="margin-bottom: 8px;"><strong>Phone:</strong> ${user.phoneNumber || 'Not provided'}</li>
          <li style="margin-bottom: 8px;"><strong>Location:</strong> ${user.location || 'Not provided'}</li>
        </ul>
      </div>
      <p>Please review this registration in the admin dashboard.</p>
    `;

    await sendEmail(adminEmail, subject, wrapEmail('Admin Notification', content));
    console.log('✅ Admin notification sent successfully!');
  } catch (error) {
    console.error('❌ Failed to send admin notification:', error.message);
    throw error;
  }
};

const sendUserNotificationEmail = async (userEmail, subject, message, firstName) => {
  try {
    const content = `
      <p>Hi <strong>${firstName}</strong>,</p>
      <p>${message}</p>
      <p>Thank you for being part of our WisdomWalk community!</p>
    `;

    await sendEmail(userEmail, subject, wrapEmail('Notification', content));
  } catch (error) {
    console.error('Failed to send user notification:', error.message);
    throw error;
  }
};

const sendReportEmailToAdmin = async (adminEmail, post, reportedBy) => {
  try {
    const content = `
      <p>A new content report has been submitted that requires your attention.</p>
      <div style="background: #fff3cd; padding: 20px; border-radius: 8px; border-left: 4px solid #ffc107;">
        <h4 style="color: #856404; margin-top: 0;">Report Details:</h4>
        <p><strong>Reported By:</strong> ${reportedBy}</p>
        <p><strong>Post ID:</strong> ${post.id}</p>
        <p><strong>Reason:</strong> ${post.reason}</p>
        <p><strong>Report Date:</strong> ${new Date().toLocaleString()}</p>
      </div>
      <p>Please review this report in the admin dashboard and take appropriate action.</p>
    `;

    await sendEmail(adminEmail, '🚨 New Post Report - WisdomWalk', wrapEmail('Content Report Alert', content));
  } catch (error) {
    console.error('Failed to send report email:', error.message);
    throw error;
  }
};

const sendNewPostEmailToAdmin = async (adminEmail, post) => {
  try {
    const content = `
      <p>A new post has been published and is now live on WisdomWalk.</p>
      <div style="background: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h4 style="color: #0d6efd; margin-top: 0;">Post Details:</h4>
        <p><strong>Author:</strong> ${post.author}</p>
        <p><strong>Title:</strong> ${post.title}</p>
        <p><strong>Category:</strong> ${post.category}</p>
        <p><strong>Content Preview:</strong> ${post.content.substring(0, 150)}${post.content.length > 150 ? '...' : ''}</p>
        <p><strong>Published:</strong> ${new Date().toLocaleString()}</p>
      </div>
    `;

    await sendEmail(adminEmail, '📝 New Post Published - WisdomWalk', wrapEmail('New Community Post', content));
  } catch (error) {
    console.error('Failed to send new post email:', error.message);
    throw error;
  }
};

const sendBlockedEmailToUser = async (userEmail, reason, firstName) => {
  try {
    const content = `
      <p>Hi <strong>${firstName}</strong>,</p>
      <p>We're writing to inform you that your WisdomWalk account has been temporarily blocked.</p>
      <div style="background: #f8d7da; padding: 20px; border-radius: 8px; border-left: 4px solid #dc3545;">
        <h4 style="color: #721c24; margin-top: 0;">Block Reason:</h4>
        <p>${reason}</p>
      </div>
      <p>During this time, you won't be able to access your account or use WisdomWalk services.</p>
      <p>If you believe this action was taken in error, please contact our support team for assistance.</p>
    `;

    await sendEmail(userEmail, '🚫 Account Temporarily Blocked - WisdomWalk', wrapEmail('Account Status Update', content));
  } catch (error) {
    console.error('Failed to send blocked email:', error.message);
    throw error;
  }
};

const sendUnblockedEmailToUser = async (userEmail, firstName) => {
  try {
    const content = `
      <p>Hi <strong>${firstName}</strong>,</p>
      <p>Great news! Your WisdomWalk account has been unblocked and is now fully active again.</p>
      <div style="background: #d1edff; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
        <h3 style="color: #0d6efd; margin: 0;">Welcome Back! 🌼</h3>
      </div>
      <p>You can now log in and continue your journey with WisdomWalk. We're glad to have you back in our community!</p>
      <p>If you have any questions, please don't hesitate to contact our support team.</p>
    `;

    await sendEmail(userEmail, '✅ Account Unblocked - WisdomWalk', wrapEmail('Welcome Back!', content));
  } catch (error) {
    console.error('Failed to send unblocked email:', error.message);
    throw error;
  }
};

const sendBannedEmailToUser = async (userEmail, reason, firstName) => {
  try {
    const content = `
      <p>Hi <strong>${firstName}</strong>,</p>
      <p>We're writing to inform you that your WisdomWalk account has been permanently banned.</p>
      <div style="background: #f8d7da; padding: 20px; border-radius: 8px; border-left: 4px solid #dc3545;">
        <h4 style="color: #721c24; margin-top: 0;">Ban Reason:</h4>
        <p>${reason}</p>
      </div>
      <p>This decision was made due to a serious violation of our community guidelines.</p>
      <p>If you would like more information about this action, you may contact our admin team for further details.</p>
    `;

    await sendEmail(userEmail, '❌ Account Permanently Banned - WisdomWalk', wrapEmail('Account Termination Notice', content));
  } catch (error) {
    console.error('Failed to send banned email:', error.message);
    throw error;
  }
};

const sendLikeNotificationEmail = async (userEmail, likerName, postTitle) => {
  try {
    const content = `
      <p>Great news! Your post is resonating with the community. 💖</p>
      <div style="background: #fff0f6; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
        <p style="margin: 0; font-size: 18px;"><strong>${likerName}</strong> liked your post:</p>
        <p style="margin: 10px 0 0 0; font-style: italic; color: #A67B5B;">"${postTitle}"</p>
      </div>
      <p>Keep sharing your wisdom and inspiring others in our community!</p>
    `;

    await sendEmail(userEmail, '❤️ New Like on Your Post - WisdomWalk', wrapEmail('Your Post Got Liked!', content));
  } catch (error) {
    console.error('Failed to send like notification:', error.message);
    throw error;
  }
};

const sendCommentNotificationEmail = async (userEmail, commenterName, comment, postTitle) => {
  try {
    const content = `
      <p>Someone engaged with your post! Here's what they said:</p>
      <div style="background: #f0f8ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <p style="margin: 0 0 10px 0;"><strong>${commenterName}</strong> commented on your post <strong>"${postTitle}"</strong>:</p>
        <blockquote style="margin: 0; padding: 15px; background: white; border-left: 4px solid #A67B5B; font-style: italic;">
          ${comment}
        </blockquote>
      </div>
      <p>Join the conversation and continue building connections in our WisdomWalk community!</p>
    `;

    await sendEmail(userEmail, '💬 New Comment on Your Post - WisdomWalk', wrapEmail('New Comment Received', content));
  } catch (error) {
    console.error('Failed to send comment notification:', error.message);
    throw error;
  }
};

// Test email function
const testEmailService = async (testEmail = 'test@example.com') => {
  console.log('🧪 TESTING EMAIL SERVICE...');
  try {
    await sendVerificationEmail(testEmail, 'Test User', '123456');
    console.log('✅ Email service test PASSED');
    return true;
  } catch (error) {
    console.error('❌ Email service test FAILED:', error.message);
    return false;
  }
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
  testEmailService
};