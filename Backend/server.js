const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const path = require("path");
const cookieParser = require("cookie-parser");
const http = require("http");
const { Server } = require("socket.io");

// Load .env only in development (Render sets env vars directly)
if (process.env.NODE_ENV !== "production") {
  require("dotenv").config();
  console.log(".env file loaded (development mode)");
}

// === App & Server Setup ===
const app = express();
const server = http.createServer(app);

// CORS configuration
app.use(
  cors({
    origin: "*", // Change to your frontend URL in production
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Socket.IO with CORS
const io = new Server(server, {
  cors: {
    origin: "*",
    credentials: true,
    methods: ["GET", "POST"],
  },
});

app.use(cookieParser());
app.use(helmet());

app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Static files
app.use(express.static(path.join(__dirname, "public")));
app.use("/uploads", express.static(path.join(__dirname, "Uploads")));

// Attach io to app
app.set("io", io);
require("./socket/socket")(io);

// === Routes ===
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const postRoutes = require("./routes/postRoutes");
const chatRoutes = require("./routes/chatRoutes");
const adminRoutes = require("./routes/adminRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const reportRoutes = require("./routes/reportRoutes");
const movementRoutes = require("./routes/movementRoute");
const bookingRoutes = require("./routes/bookingRoute");
const eventRoutes = require("./routes/eventRoutes");
const groupRoutes = require("./routes/group");

app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/posts", postRoutes);
app.use("/api/chats", chatRoutes);
app.use("/api/groups", groupRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/reports", reportRoutes);
app.use("/api/movements", movementRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/events", eventRoutes);

// Health check
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "WisdomWalk API is running",
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || "unknown",
  });
});

// Email test endpoint (for debugging - remove in production or add auth)
app.post("/api/test-email", async (req, res) => {
  try {
    const { sendVerificationEmail } = require("./utils/emailService");
    const { email, firstName, code } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const testCode = code || Math.floor(1000 + Math.random() * 9000).toString();
    await sendVerificationEmail(email, firstName || "Test User", testCode);
    
    res.json({
      success: true,
      message: "Test email sent successfully",
      code: testCode,
    });
  } catch (error) {
    console.error("Test email error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to send test email",
      error: {
        message: error.message,
        code: error.code,
        response: error.response,
      },
    });
  }
});

// === Error Handling ===
app.use((err, req, res, next) => {
  console.error("Server Error:", err.stack);
  res.status(500).json({
    success: false,
    message: "Something went wrong!",
    error: process.env.NODE_ENV === "development" ? err.message : undefined,
  });
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

// === MongoDB Connection ===
const mongoUri = process.env.MONGO_URI;

if (!mongoUri) {
  console.error("FATAL ERROR: MONGO_URI is not set in environment variables!");
  console.error("Set it in Render Dashboard → Environment");
  process.exit(1);
}

console.log("Connecting to MongoDB...");

mongoose
  .connect(mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => {
    console.log("MongoDB connected successfully!");

    const PORT = process.env.PORT || 5000;
    server.listen(PORT, "0.0.0.0", () => {
      console.log(`Server running on port ${PORT}`);
      console.log(`Public folder: ${path.join(__dirname, "public")}`);
      console.log(`Uploads folder: ${path.join(__dirname, "Uploads")}`);
    });
  })
  .catch((err) => {
    console.error("MongoDB connection failed:", err.message);
    process.exit(1);
  });

// Export for testing
module.exports = app;