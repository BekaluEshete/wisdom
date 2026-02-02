const { sendVerificationEmail } = require('./utils/emailService');

async function verifyFix() {
    console.log('🧪 Verifying Email Service Fix...');
    try {
        const email = 'temesgenmarie97@gmail.com'; // Testing to yourself is safest for verification
        const result = await sendVerificationEmail(email, 'Verified User', '9999');
        console.log('✅ Final Verification Successful! MessageId:', result.messageId);
    } catch (error) {
        console.error('❌ Final Verification Failed:', error.message);
    }
}

verifyFix();
