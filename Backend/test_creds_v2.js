require('dotenv').config();
const nodemailer = require('nodemailer');

async function testCreds(user, pass, label) {
    console.log(`\n--- Testing ${label} (${user}) ---`);
    if (!user || !pass) {
        console.log(`Skipping ${label}: Missing credentials`);
        return;
    }

    const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 465,
        secure: true, // use SSL
        auth: {
            user: user,
            pass: pass,
        },
        debug: true,
        logger: true
    });

    try {
        const info = await transporter.sendMail({
            from: `"WisdomWalk Test" <${user}>`,
            to: user,
            subject: `Test from ${label}`,
            html: "<p>It works!</p>",
        });
        console.log(`✅ SUCCESS ${label}! MessageId: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error(`❌ FAILED ${label}:`);
        console.error(`Message: ${error.message}`);
        console.error(`Code: ${error.code}`);
        if (error.response) console.error(`Response: ${error.response}`);
        return false;
    }
}

async function run() {
    // Set 1: SMTP_USER
    await testCreds(process.env.SMTP_USER, process.env.SMTP_PASS, "SMTP_CREDS");

    // Set 2: GMAIL_USER
    await testCreds(process.env.GMAIL_USER || process.env.EMAIL_USER, process.env.GMAIL_APP_PASSWORD, "GMAIL_CREDS");
}

run();
