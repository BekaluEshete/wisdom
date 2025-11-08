// require('dotenv').config();
// const nodemailer = require('nodemailer');

// // Email service configuration
// // Using Resend API (recommended for cloud platforms like Render)
// // Fallback to Gmail SMTP if Resend is not configured
// const RESEND_API_KEY = process.env.RESEND_API_KEY;
// const GMAIL_USER = process.env.GMAIL_USER || "temesgenmarie97@gmail.com";
// const GMAIL_PASS = process.env.GMAIL_PASS || "cykl seqo wbfe yugb";

// // Use Resend if API key is available, otherwise use Gmail SMTP
// const USE_RESEND = !!RESEND_API_KEY;

// // Create transporter with better timeout settings
// const createTransporter = (port = 587) => {
//   return nodemailer.createTransport({
//     service: 'gmail',
//     host: 'smtp.gmail.com',
//     port: port,
//     secure: port === 465, // true for 465, false for 587
//     auth: {
//       user: GMAIL_USER,
//       pass: GMAIL_PASS,
//     },
//     tls: {
//       rejectUnauthorized: false,
//       ciphers: 'SSLv3'
//     },
//     connectionTimeout: 15000, // 15 seconds - reduced for faster failover
//     greetingTimeout: 10000,   // 10 seconds
//     socketTimeout: 15000,     // 15 seconds
//   });
// };

// // Try port 587 first (TLS), fallback to 465 (SSL) if needed
// let transporter = createTransporter(587);

// // Log email service configuration
// if (USE_RESEND) {
//   console.log('✅ Email service: Resend API configured');
//   console.log('   This is recommended for cloud platforms like Render');
// } else {
//   console.log('⚠️  Email service: Gmail SMTP configured');
//   console.log('   Note: May have connection issues on Render');
//   console.log('   To use Resend API, set RESEND_API_KEY environment variable');
//   console.log('   Get free API key at: https://resend.com/api-keys');
// }

// const wrapEmail = (title, content) => `
//   <div style="font-family: 'Segoe UI', sans-serif; background-color: #fdf9f4; padding: 40px 20px; border-radius: 12px; max-width: 600px; margin: auto; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
//     <div style="text-align: center;">
//       <h2 style="color: #A67B5B; font-size: 26px;">${title}</h2>
//     </div>
//     <div style="font-size: 16px; color: #555; line-height: 1.6;">
//       ${content}
//     </div>
//     <hr style="border: none; border-top: 1px solid #e8ddd3; margin: 30px 0;" />
//     <div style="font-size: 14px; color: #777; text-align: center;">
//       <p>"She is clothed with strength and dignity, and she laughs without fear of the future."<br><strong>– Proverbs 31:25</strong></p>
//       <p>Blessings,<br><strong>The WisdomWalk Team</strong></p>
//     </div>
//   </div>
// `;

// // Send email using Resend API (recommended for cloud platforms)
// const sendEmailViaResend = async (to, subject, html) => {
//   const https = require('https');
  
//   // Clean the HTML content and ensure it's valid
//   const text = html.replace(/<[^>]*>/g, '').substring(0, 500); // Limit text length
  
//   const payload = {
//     from: 'WisdomWalk <onboarding@resend.dev>',
//     to: Array.isArray(to) ? to : [to], // Ensure to is an array
//     subject: subject.substring(0, 998), // Limit subject length
//     html: html,
//     text: text,
//   };

//   // Validate payload before sending
//   try {
//     JSON.stringify(payload);
//   } catch (error) {
//     throw new Error(`Invalid email payload: ${error.message}`);
//   }

//   const data = JSON.stringify(payload);
  
//   const options = {
//     hostname: 'api.resend.com',
//     port: 443,
//     path: '/emails',
//     method: 'POST',
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': `Bearer ${RESEND_API_KEY}`,
//       'Content-Length': Buffer.byteLength(data),
//     },
//     timeout: 30000,
//   };

//   return new Promise((resolve, reject) => {
//     const req = https.request(options, (res) => {
//       let responseData = '';

//       res.on('data', (chunk) => {
//         responseData += chunk;
//       });

//       res.on('end', () => {
//         if (res.statusCode >= 200 && res.statusCode < 300) {
//           try {
//             const result = JSON.parse(responseData);
//             console.log(`✅ Email sent via Resend to ${to}`);
//             resolve(result);
//           } catch (parseError) {
//             reject(new Error(`Failed to parse Resend response: ${parseError.message}`));
//           }
//         } else {
//           let errorMessage = `Resend API error: ${res.statusCode}`;
//           try {
//             const error = JSON.parse(responseData);
//             errorMessage = error.message || errorMessage;
//           } catch (e) {
//             // If we can't parse the error, use the raw response
//             errorMessage = responseData || errorMessage;
//           }
//           reject(new Error(errorMessage));
//         }
//       });
//     });

//     req.on('error', (error) => {
//       reject(new Error(`Resend request failed: ${error.message}`));
//     });

//     req.on('timeout', () => {
//       req.destroy();
//       reject(new Error('Resend API request timeout'));
//     });

//     try {
//       req.write(data);
//       req.end();
//     } catch (error) {
//       reject(new Error(`Failed to send request: ${error.message}`));
//     }
//   });
// };

// // Send email using Gmail SMTP (fallback)
// const sendEmailViaSMTP = async (to, subject, html, retries = 1) => {
//   let currentTransporter = transporter;
//   let triedPort465 = false;
//   let triedPort587 = false;
  
//   for (let attempt = 1; attempt <= retries + 1; attempt++) {
//     try {
//       const mailOptions = {
//         from: `"WisdomWalk" <${GMAIL_USER}>`,
//         to,
//         subject,
//         html,
//         text: html.replace(/<[^>]*>/g, ''),
//       };
      
//       console.log(`📧 Attempting to send email via SMTP to: ${to} (Attempt ${attempt}/${retries + 1})`);
//       console.log(`   Using port: ${currentTransporter.options.port}`);
      
//       const info = await currentTransporter.sendMail(mailOptions);
//       console.log(`✅ Email sent successfully via SMTP to ${to}`);
//       return info;
//     } catch (error) {
//       console.error(`❌ SMTP error (Attempt ${attempt}/${retries + 1}): ${error.code} - ${error.message}`);
      
//       if (error.code === 'EAUTH') {
//         throw new Error(`SMTP authentication failed: ${error.message}`);
//       } else if (error.code === 'ETIMEDOUT' || error.code === 'ECONNECTION') {
//         if (!triedPort587 && currentTransporter.options.port === 465) {
//           console.log('🔄 Switching to port 587 (TLS)');
//           currentTransporter = createTransporter(587);
//           triedPort587 = true;
//           await new Promise(resolve => setTimeout(resolve, 1000));
//           continue;
//         } else if (!triedPort465 && currentTransporter.options.port === 587) {
//           console.log('🔄 Switching to port 465 (SSL)');
//           currentTransporter = createTransporter(465);
//           triedPort465 = true;
//           await new Promise(resolve => setTimeout(resolve, 1000));
//           continue;
//         }
        
//         if (attempt <= retries) {
//           console.log(`🔄 Retrying SMTP in ${2000 * attempt}ms...`);
//           await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
//           continue;
//         }
//         throw new Error(`SMTP connection failed: ${error.message}`);
//       } else {
//         if (attempt <= retries) {
//           console.log(`🔄 Retrying SMTP in ${2000 * attempt}ms...`);
//           await new Promise(resolve => setTimeout(resolve, 2000 * attempt));
//           continue;
//         }
//         throw new Error(`SMTP error: ${error.message}`);
//       }
//     }
//   }
// };

// // Main sendEmail function - uses Resend if available, otherwise SMTP
// const sendEmail = async (to, subject, html) => {
//   let resendError = null;
//   let smtpError = null;

//   // Try Resend first
//   if (USE_RESEND) {
//     try {
//       console.log(`📧 Attempting Resend API to: ${to}`);
//       console.log(`   Subject: ${subject}`);
//       return await sendEmailViaResend(to, subject, html);
//     } catch (error) {
//       resendError = error;
//       console.error(`❌ Resend failed: ${error.message}`);
//     }
//   }

//   // Try SMTP as fallback
//   try {
//     console.log(`📧 Attempting SMTP to: ${to}`);
//     console.log(`   Subject: ${subject}`);
//     console.log(`   ⚠️  Note: Using SMTP. For better reliability on Render, set RESEND_API_KEY`);
//     return await sendEmailViaSMTP(to, subject, html, 1);
//   } catch (error) {
//     smtpError = error;
//     console.error(`❌ SMTP failed: ${error.message}`);
//   }

//   // Both failed
//   const errorMessage = `Both email services failed. Resend: ${resendError?.message}, SMTP: ${smtpError?.message}`;
//   throw new Error(errorMessage);
// };

// const sendVerificationEmail = async (email, firstName, code) => {
//   const content = `
//     <p>Hi ${firstName || 'there'},</p>
//     <p>Welcome to WisdomWalk! Please verify your email by using the following code:</p>
//     <div style="font-size: 32px; font-weight: bold; color: #A67B5B; letter-spacing: 8px; text-align: center; padding: 20px; background-color: #f9f5f0; border-radius: 8px; margin: 20px 0;">${code}</div>
//     <p style="color: #888; font-size: 14px;">This code will expire in 5 minutes.</p>
//     <p>If you didn't create an account with WisdomWalk, please ignore this email.</p>
//   `;
//   await sendEmail(email, '🌸 Verify Your Email - WisdomWalk', wrapEmail('Email Verification', content));
// };

// const sendPasswordResetEmail = async (email, code, firstName) => {
//   const content = `
//     <p>Hello ${firstName},</p>
//     <p>We received a request to reset your password. Use the code below:</p>
//     <div style="font-size: 24px; font-weight: bold; color: #A67B5B; text-align: center;">${code}</div>
//     <p>This code will expire in 15 minutes.</p>
//   `;
//   await sendEmail(email, '🔐 Reset Your Password - WisdomWalk', wrapEmail('Password Reset', content));
// };

// const sendAdminNotificationEmail = async (adminEmail, subject, message, user) => {
//   const content = `
//     <p>${message}</p>
//     <h4>User Details:</h4>
//     <ul>
//       <li><strong>Name:</strong> ${user.firstName} ${user.lastName}</li>
//       <li><strong>Email:</strong> ${user.email}</li>
//       <li><strong>Date of Birth:</strong> ${user.dateOfBirth}</li>
//       <li><strong>Phone:</strong> ${user.phoneNumber}</li>
//       <li><strong>Location:</strong> ${user.location}</li>
//     </ul>
//   `;
//   await sendEmail(adminEmail, subject, wrapEmail(subject, content));
// };

// const sendUserNotificationEmail = async (userEmail, subject, message, firstName) => {
//   const content = `
//     <p>Hi ${firstName},</p>
//     <p>${message}</p>
//   `;
//   await sendEmail(userEmail, subject, wrapEmail(subject, content));
// };

// const sendReportEmailToAdmin = async (adminEmail, post, reportedBy) => {
//   const content = `
//     <p>A new report has been submitted.</p>
//     <p><strong>Reported By:</strong> ${reportedBy}</p>
//     <p><strong>Post ID:</strong> ${post.id}</p>
//     <p><strong>Reason:</strong> ${post.reason}</p>
//   `;
//   await sendEmail(adminEmail, '🚨 New Post Report - WisdomWalk', wrapEmail('Reported Content Alert', content));
// };

// const sendNewPostEmailToAdmin = async (adminEmail, post) => {
//   const content = `
//     <p>A new post has been published by <strong>${post.author}</strong>.</p>
//     <p><strong>Title:</strong> ${post.title}</p>
//     <p><strong>Category:</strong> ${post.category}</p>
//     <p><strong>Preview:</strong> ${post.content}</p>
//   `;
//   await sendEmail(adminEmail, '📝 New Post Submitted - WisdomWalk', wrapEmail('New Community Post', content));
// };

// const sendBlockedEmailToUser = async (userEmail, reason, firstName) => {
//   const content = `
//     <p>Hi ${firstName},</p>
//     <p>Your account has been temporarily blocked for the following reason:</p>
//     <blockquote>${reason}</blockquote>
//     <p>Please contact support if you believe this was a mistake.</p>
//   `;
//   await sendEmail(userEmail, '🚫 Account Blocked - WisdomWalk', wrapEmail('Account Notice', content));
// };

// const sendUnblockedEmailToUser = async (userEmail, firstName) => {
//   const content = `
//     <p>Hi ${firstName},</p>
//     <p>Your account has been unblocked and is now active.</p>
//     <p>Welcome back to WisdomWalk 🌼</p>
//   `;
//   await sendEmail(userEmail, '✅ Account Unblocked - WisdomWalk', wrapEmail('You re Back Online!', content));
// };

// const sendBannedEmailToUser = async (userEmail, reason, firstName) => {
//   const content = `
//     <p>Hi ${firstName},</p>
//     <p>Your account has been permanently banned for the following reason:</p>
//     <blockquote>${reason}</blockquote>
//     <p>You may contact our admin team for further details.</p>
//   `;
//   await sendEmail(userEmail, '❌ Account Banned - WisdomWalk', wrapEmail('Account Termination', content));
// };

// const sendLikeNotificationEmail = async (userEmail, likerName, postTitle) => {
//   const content = `
//     <p>Your post titled <strong>"${postTitle}"</strong> received a new like from <strong>${likerName}</strong>! 💖</p>
//     <p>Keep sharing your wisdom!</p>
//   `;
//   await sendEmail(userEmail, '👍 New Like on Your Post - WisdomWalk', wrapEmail('Post Appreciation', content));
// };

// const sendCommentNotificationEmail = async (userEmail, commenterName, comment, postTitle) => {
//   const content = `
//     <p><strong>${commenterName}</strong> commented on your post <strong>"${postTitle}"</strong>:</p>
//     <blockquote>${comment}</blockquote>
//     <p>Join the conversation and connect with the community!</p>
//   `;
//   await sendEmail(userEmail, '💬 New Comment on Your Post - WisdomWalk', wrapEmail('New Comment Received', content));
// };

// module.exports = {
//   sendVerificationEmail,
//   sendPasswordResetEmail,
//   sendAdminNotificationEmail,
//   sendUserNotificationEmail,
//   sendReportEmailToAdmin,
//   sendNewPostEmailToAdmin,
//   sendBlockedEmailToUser,
//   sendUnblockedEmailToUser,
//   sendBannedEmailToUser,
//   sendLikeNotificationEmail,
//   sendCommentNotificationEmail,
// }; 

require('dotenv').config();
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: "temesgenmarie97@gmail.com",
    pass: "cykl seqo wbfe yugb",
  },
});

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

const sendEmail = async (to, subject, html) => {
  await transporter.sendMail({ from: process.env.GMAIL_USER, to, subject, html });
};

const sendVerificationEmail = async (email, firstName, code) => {
  const content = `
    <p>Hi ${firstName},</p>
    <p>Please verify your email by using the following code:</p>
    <div style="font-size: 32px; font-weight: bold; color: #A67B5B; letter-spacing: 8px; text-align: center;">${code}</div>
    <p>This code will expire in 24 hours.</p>
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

