const express = require("express");
const router = express.Router();
const groupController = require("../controllers/group");
const { authenticateToken } = require("../middleware/auth");
const { uploadMultiple } = require("../middleware/upload");
const { initializeDefaultCircles } = require("../utils/initializeCircles");

// Debugging - verify controller imports
console.log("Group Controller Methods:", Object.keys(groupController));

router.use(authenticateToken);

// Initialize circles endpoint (admin only or for setup)
router.post("/initialize-circles", async (req, res) => {
  try {
    // Only allow admins or if no circles exist
    const Group = require("../models/group");
    const circleCount = await Group.countDocuments({ isActive: true, deletedAt: null });
    
    if (circleCount > 0 && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: "Only admins can reinitialize circles when they already exist"
      });
    }

    const result = await initializeDefaultCircles();
    res.status(200).json({
      success: true,
      message: "Circles initialized successfully",
      ...result
    });
  } catch (error) {
    console.error("Error initializing circles:", error);
    res.status(500).json({
      success: false,
      message: "Failed to initialize circles",
      error: error.message
    });
  }
});

// Group CRUD
router.post("/", groupController.createGroup);
router.get("/", groupController.getAllGroups);
router.get("/:groupId", groupController.getGroupDetails);
router.put("/:groupId", groupController.updateGroup);
router.delete("/:groupId", groupController.deleteGroup);

// Members
router.post("/join/:inviteLink", groupController.joinGroupViaLink);
router.post("/:groupId/join", groupController.joinGroup);
router.post("/:groupId/leave", groupController.leaveGroup);
router.post("/:groupId/members", groupController.addMember);
router.delete("/:groupId/members/:userId", groupController.removeMember);
router.get("/:groupId/members", groupController.getGroupMembers);

// Admin
router.post("/:groupId/admins/:userId", groupController.promoteToAdmin);
router.delete("/:groupId/admins/:userId", groupController.demoteAdmin);

// Chat
router.get("/:groupId/chat/messages", groupController.getChatMessages);
router.post("/:groupId/chat/messages", uploadMultiple, groupController.sendMessage);

// Pinned
router.get("/:groupId/chat/pinned", groupController.getPinnedMessages);
router.post("/:groupId/chat/messages/:messageId/pin", groupController.pinMessage);
router.delete("/:groupId/chat/messages/:messageId/pin", groupController.unpinMessage);

// Settings
router.put("/:groupId/settings", groupController.updateGroupSettings);
router.post("/:groupId/invite-link", groupController.generateInviteLink);

// Notifications
router.post("/:groupId/mute", groupController.muteGroup);
router.post("/:groupId/unmute", groupController.unmuteGroup);

module.exports = router;