const { verify } = require("jsonwebtoken")
const User = require("../models/User")
const Chat = require("../models/Chat")
const Message = require("../models/Message")
const Notification = require("../models/Notification")
const { saveMultipleFiles } = require("../utils/localStorageService")

// Track connected users
const connectedUsers = new Map()

module.exports = (io) => {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token // Fixed: Get token from auth object
      if (!token) return next(new Error("Authentication required"))

      const decoded = verify(token, process.env.JWT_SECRET)
      const user = await User.findById(decoded.userId)
      if (!user) return next(new Error("User not found"))

      socket.user = user
      next()
    } catch (error) {
      next(new Error("Invalid token"))
    }
  })

  io.on("connection", (socket) => {
    console.log(`[Socket] User connected: ${socket.user._id}`)
    connectedUsers.set(socket.user._id.toString(), socket.id)
    
    // Update user online status and broadcast to all their chat partners
    User.findByIdAndUpdate(socket.user._id, { 
      isOnline: true,
      lastActive: new Date()
    }).then(async () => {
      // Broadcast online status to all users who have direct chats with this user
      const userChats = await Chat.find({
        type: "direct",
        participants: socket.user._id,
        isActive: true
      }).select('participants').lean()
      
      // Get all unique chat partner IDs
      const chatPartnerIds = new Set()
      userChats.forEach(chat => {
        chat.participants.forEach(participantId => {
          const pid = participantId.toString()
          if (pid !== socket.user._id.toString()) {
            chatPartnerIds.add(pid)
          }
        })
      })
      
      // Emit online status to all chat partners
      chatPartnerIds.forEach(partnerId => {
        io.to(connectedUsers.get(partnerId) || '').emit('userOnlineStatus', {
          userId: socket.user._id.toString(),
          isOnline: true,
          lastActive: new Date()
        })
      })
    }).catch(err => console.error('[Socket] Error updating user status:', err))

    // Join user to all their DIRECT chats only (not group/circle chats)
    // Circles have their own messaging system
    Chat.find({ 
      type: "direct", // Only direct one-to-one chats
      participants: socket.user._id,
      isActive: true
    }).then((chats) => {
      chats.forEach((chat) => {
        const chatRoomId = chat._id.toString()
        socket.join(chatRoomId)
        console.log(`[Socket] User ${socket.user._id} joined direct chat ${chatRoomId}`)
      })
      console.log(`[Socket] User ${socket.user._id} joined ${chats.length} direct chat(s)`)
    }).catch(err => {
      console.error('[Socket] Error fetching user chats:', err)
    })

    // Handle joining specific direct chat
    socket.on("joinChat", async (chatId) => {
      try {
        // Verify this is a direct chat
        const chat = await Chat.findById(chatId)
        if (chat && chat.type === "direct" && chat.participants.includes(socket.user._id)) {
          socket.join(chatId)
          console.log(`[Socket] User ${socket.user._id} joined direct chat ${chatId}`)
        } else {
          console.log(`[Socket] User ${socket.user._id} attempted to join invalid/non-direct chat ${chatId}`)
        }
      } catch (err) {
        console.error(`[Socket] Error joining chat ${chatId}:`, err)
      }
    })

    // Handle leaving specific chat
    socket.on("leaveChat", (chatId) => {
      socket.leave(chatId)
      console.log(`[Socket] User ${socket.user._id} left chat ${chatId}`)
    })

    // Message handlers - only for direct chats
    socket.on("sendMessage", async ({ chatId, content, messageType = "text", replyToId, files = [] }, callback) => {
      try {
        const userId = socket.user._id
        const chat = await Chat.findOne({ 
          _id: chatId, 
          type: "direct", // Only allow direct chats
          participants: userId 
        })
        if (!chat) throw new Error("Chat not found or access denied. Only direct chats are supported.")
        if (chat.type !== "direct") throw new Error("This endpoint is only for direct one-to-one chats.")

        const user = await User.findById(userId)
        const otherParticipants = chat.participants.filter((p) => p.toString() !== userId.toString())

        // Check for blocked users
        if (otherParticipants.some((p) => user.blockedUsers.includes(p))) {
          throw new Error("Cannot send message to a blocked user")
        }

        // Create message
        const messageData = {
          chat: chatId,
          sender: userId,
          content,
          messageType,
          replyTo: replyToId,
        }

        // Handle file attachments
        if (files.length > 0) {
          const uploadResults = await saveMultipleFiles(files, "messages")
          messageData.attachments = uploadResults.map((result) => ({
            type: result.url,
            fileType: result.fileType || "image",
            fileName: result.fileName,
          }))
        }

        const message = new Message(messageData)
        await message.save()

        // Update chat last message
        chat.lastMessage = message._id
        chat.lastActivity = new Date()
        await chat.save()

        // Populate sender info
        await message.populate("sender", "firstName lastName profilePicture")
        if (message.replyTo) {
          await message.populate("replyTo", "content sender")
        }

        // Send notifications to offline users
        const notifications = []
        for (const participantId of otherParticipants) {
          const settings = chat.participantSettings.find((s) => s.user.toString() === participantId.toString())

          // Only notify if not muted and user is offline
          if (!settings?.isMuted && !connectedUsers.has(participantId.toString())) {
            notifications.push({
              recipient: participantId,
              sender: userId,
              type: "message",
              title: "New message",
              message: `${user.firstName} sent you a message`,
              relatedChat: chatId,
            })
          }
        }

        if (notifications.length > 0) {
          await Notification.insertMany(notifications)
        }

        // Emit to all in chat room
        io.to(chatId).emit("newMessage", message)
        callback({ success: true, data: message })
      } catch (error) {
        console.error("Send message error:", error)
        callback({ success: false, message: error.message })
      }
    })

    // Message editing
    socket.on("messageEdited", async ({ chatId, messageId, content }) => {
      try {
        const userId = socket.user._id
        const message = await Message.findById(messageId)

        if (!message || message.sender.toString() !== userId.toString()) {
          return
        }

        message.content = content
        message.isEdited = true
        message.editedAt = new Date()
        await message.save()

        await message.populate("sender", "firstName lastName profilePicture")

        io.to(chatId).emit("messageEdited", message)
      } catch (error) {
        console.error("Edit message error:", error)
      }
    })

    // Message deletion
    socket.on("messageDeleted", async ({ chatId, messageId }) => {
      try {
        const userId = socket.user._id
        const message = await Message.findById(messageId)

        if (!message || message.sender.toString() !== userId.toString()) {
          return
        }

        message.isDeleted = true
        message.deletedAt = new Date()
        await message.save()

        io.to(chatId).emit("messageDeleted", { messageId })
      } catch (error) {
        console.error("Delete message error:", error)
      }
    })

    // Message pinning - only for direct chats
    socket.on("pinMessage", async ({ chatId, messageId }) => {
      try {
        const userId = socket.user._id
        const chat = await Chat.findOne({ 
          _id: chatId, 
          type: "direct", // Only allow direct chats
          participants: userId 
        })
        if (!chat || chat.type !== "direct") return

        const message = await Message.findById(messageId)
        if (!message || message.chat.toString() !== chatId) return

        // Update message pin status
        message.isPinned = true
        await message.save()

        // Update chat pinned messages
        await Chat.findByIdAndUpdate(chatId, {
          $addToSet: { pinnedMessages: messageId },
        })

        io.to(chatId).emit("messagePinned", {
          messageId,
          chatId,
          pinnedBy: {
            _id: userId,
            firstName: socket.user.firstName,
            lastName: socket.user.lastName,
          },
        })
      } catch (error) {
        console.error("Pin message error:", error)
      }
    })

    // Message unpinning - only for direct chats
    socket.on("unpinMessage", async ({ chatId, messageId }) => {
      try {
        const userId = socket.user._id
        const chat = await Chat.findOne({ 
          _id: chatId, 
          type: "direct", // Only allow direct chats
          participants: userId 
        })
        if (!chat || chat.type !== "direct") return

        const message = await Message.findById(messageId)
        if (!message || message.chat.toString() !== chatId) return

        // Update message pin status
        message.isPinned = false
        await message.save()

        // Update chat pinned messages
        await Chat.findByIdAndUpdate(chatId, {
          $pull: { pinnedMessages: messageId },
        })

        io.to(chatId).emit("messageUnpinned", {
          messageId,
          chatId,
          unpinnedBy: {
            _id: userId,
            firstName: socket.user.firstName,
            lastName: socket.user.lastName,
          },
        })
      } catch (error) {
        console.error("Unpin message error:", error)
      }
    })

    // Message reactions - only for direct chats
    socket.on("addReaction", async ({ chatId, messageId, emoji }) => {
      try {
        const userId = socket.user._id
        const message = await Message.findById(messageId)
        if (!message) return

        const chat = await Chat.findOne({ 
          _id: message.chat, 
          type: "direct", // Only allow direct chats
          participants: userId 
        })
        if (!chat || chat.type !== "direct") return

        const existingReactionIndex = message.reactions.findIndex(
          (reaction) => reaction.user.toString() === userId.toString() && reaction.emoji === emoji,
        )

        let isAdding = false
        if (existingReactionIndex >= 0) {
          // Remove existing reaction
          message.reactions.splice(existingReactionIndex, 1)
          isAdding = false
        } else {
          // Add new reaction
          message.reactions.push({ user: userId, emoji })
          isAdding = true
        }

        await message.save()

        // Populate user info for the reaction
        await message.populate("reactions.user", "firstName lastName profilePicture")

        // Emit the reaction with proper structure
        const reactionData = {
          messageId,
          chatId,
          reaction: {
            emoji,
            userId: userId.toString(),
            user: {
              _id: userId,
              firstName: socket.user.firstName,
              lastName: socket.user.lastName,
              profilePicture: socket.user.profilePicture,
            },
            isAdding, // true if added, false if removed
          },
        }

        io.to(chatId).emit("messageReaction", reactionData)
      } catch (error) {
        console.error("Add reaction error:", error)
      }
    })

    // Typing indicators - only for direct chats
    socket.on("typing", async ({ chatId }) => {
      try {
        // Verify this is a direct chat
        const chat = await Chat.findById(chatId)
        if (chat && chat.type === "direct" && chat.participants.includes(socket.user._id)) {
          socket.to(chatId).emit("typing", {
            userId: socket.user._id,
            firstName: socket.user.firstName,
            chatId: chatId,
          })
        }
      } catch (err) {
        console.error(`[Socket] Error in typing indicator:`, err)
      }
    })

    socket.on("stopTyping", async ({ chatId }) => {
      try {
        // Verify this is a direct chat
        const chat = await Chat.findById(chatId)
        if (chat && chat.type === "direct" && chat.participants.includes(socket.user._id)) {
          socket.to(chatId).emit("stopTyping", {
            userId: socket.user._id,
            chatId: chatId,
          })
        }
      } catch (err) {
        console.error(`[Socket] Error in stop typing indicator:`, err)
      }
    })

    // Ping/Pong for connection health
    socket.on("ping", () => {
      socket.emit("pong")
    })

    // Handle disconnection
    socket.on("disconnect", async () => {
      console.log(`[Socket] User disconnected: ${socket.user._id}`)
      
      // Clear the lastActive interval if it exists
      if (socket.lastActiveInterval) {
        clearInterval(socket.lastActiveInterval)
      }
      
      connectedUsers.delete(socket.user._id.toString())
      
      // Update user offline status
      await User.findByIdAndUpdate(socket.user._id, { 
        isOnline: false,
        lastActive: new Date()
      }).catch(err => console.error('[Socket] Error updating user status:', err))
      
      // Broadcast offline status to all users who have direct chats with this user
      try {
        const userChats = await Chat.find({
          type: "direct",
          participants: socket.user._id,
          isActive: true
        }).select('participants').lean()
        
        // Get all unique chat partner IDs
        const chatPartnerIds = new Set()
        userChats.forEach(chat => {
          chat.participants.forEach(participantId => {
            const pid = participantId.toString()
            if (pid !== socket.user._id.toString()) {
              chatPartnerIds.add(pid)
            }
          })
        })
        
        // Emit offline status to all chat partners
        chatPartnerIds.forEach(partnerId => {
          const partnerSocketId = connectedUsers.get(partnerId)
          if (partnerSocketId) {
            io.to(partnerSocketId).emit('userOnlineStatus', {
              userId: socket.user._id.toString(),
              isOnline: false,
              lastActive: new Date()
            })
          }
        })
      } catch (err) {
        console.error('[Socket] Error broadcasting offline status:', err)
      }
    })
    
    // Handle periodic lastActive updates (every 30 seconds while connected)
    const lastActiveInterval = setInterval(async () => {
      try {
        await User.findByIdAndUpdate(socket.user._id, { 
          lastActive: new Date()
        })
      } catch (err) {
        console.error('[Socket] Error updating lastActive:', err)
      }
    }, 30000) // Update every 30 seconds
    
    // Store interval ID on socket for cleanup in disconnect handler
    socket.lastActiveInterval = lastActiveInterval

    // Error handling
    socket.on("error", (err) => {
      console.error(`Socket error for user ${socket.user._id}:`, err)
    })
  })
}
