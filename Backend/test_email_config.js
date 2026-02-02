require('dotenv').config(); // Valid since we will run from inside Backend/
const { Resend } = require('resend');
const nodemailer = require('nodemailer');

async function testResend() {
    console.log('--- Testing Resend ---');
    if (!process.env.RESEND_API_KEY) {
        console.log('Skipping Resend: No API Key');
        return;
    }

    const resend = new Resend(process.env.RESEND_API_KEY);
    try {
        const { data, error } = await resend.emails.send({
            from: 'WisdomWalk <onboarding@resend.dev>',
            to: 'bekelueshete@gmail.com', // Trying to send to the likely developer email (from .env)
            subject: 'Resend Test',
            html: '<p>Test from Resend</p>'
        });

        if (error) {
            console.error('Resend Failed:', error);
        } else {
            console.log('Resend Success:', data);
        }
    } catch (e) {
        console.error('Resend Exception:', e.message);
    }
}

async function testNodemailer() {
    console.log('\n--- Testing Nodemailer (Gmail) ---');
    const user = process.env.SMTP_USER || process.env.GMAIL_USER;
    // Use the space-separated one if available, it looks like an App Password
    const pass = process.env.SMTP_PASS || process.env.GMAIL_APP_PASSWORD;

    if (!user || !pass) {
        console.log('Skipping Nodemailer: Missing credentials');
        return;
    }

    console.log(`Using user: ${user}`);

    // Create transporter
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: user,
            pass: pass,
        },
    });

    try {
        const info = await transporter.sendMail({
            from: `"WisdomWalk Test" <${user}>`,
            to: user, // Send to self to test
            subject: "Nodemailer Test",
            html: "<p>Test from Nodemailer</p>",
        });
        console.log("Nodemailer Success. MessageId: ", info.messageId);
    } catch (error) {
        console.error("Nodemailer Failed:", error);
    }
}

async function run() {
    await testResend();
    await testNodemailer();
}

run();
