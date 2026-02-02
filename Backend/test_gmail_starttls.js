require('dotenv').config();
const nodemailer = require('nodemailer');

async function testGmail() {
    const user = 'temesgenmarie97@gmail.com';
    const pass = 'cykl seqo wbfe yugb';

    console.log(`\n--- Testing Gmail STARTTLS (${user}) ---`);

    const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false, // true for 465, false for other ports
        auth: {
            user: user,
            pass: pass,
        },
    });

    try {
        const info = await transporter.sendMail({
            from: `"WisdomWalk Test" <${user}>`,
            to: user,
            subject: `Test with STARTTLS`,
            html: "<p>It works!</p>",
        });
        console.log(`✅ SUCCESS! MessageId: ${info.messageId}`);
    } catch (error) {
        console.error(`❌ FAILED:`);
        console.error(error);
    }
}

testGmail();
