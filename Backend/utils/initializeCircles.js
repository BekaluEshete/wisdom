const Group = require("../models/group");
const Chat = require("../models/Chat");
const User = require("../models/User");

// Default circles configuration
const DEFAULT_CIRCLES = [
  {
    name: "Single & Purposeful",
    description: "A community for single individuals to share experiences, support each other, and grow in purpose and faith together.",
    type: "public",
    topicType: "single",
    avatar: "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&h=300&fit=crop",
  },
  {
    name: "Marriage & Ministry",
    description: "A supportive community for married couples to share experiences, strengthen their relationships, and serve in ministry together.",
    type: "public",
    topicType: "marriage",
    avatar: "https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=400&h=300&fit=crop",
  },
  {
    name: "Motherhood in Christ",
    description: "A loving community for mothers to share experiences, seek advice, and support each other in raising children with faith and wisdom.",
    type: "public",
    topicType: "motherhood",
    avatar: "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=400&h=300&fit=crop",
  },
  {
    name: "Healing & Forgiveness",
    description: "A safe and supportive community for individuals seeking healing, offering forgiveness, and finding peace through faith and community support.",
    type: "public",
    topicType: "healing",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=300&fit=crop",
  },
];

/**
 * Initialize default circles if they don't exist
 * This function creates the four main wisdom circles
 */
const initializeDefaultCircles = async () => {
  try {
    console.log("Checking for default circles...");

    // Find an admin user to use as creator, or create a system user
    let systemUser = await User.findOne({ role: "admin" }).sort({ createdAt: 1 });
    
    if (!systemUser) {
      // If no admin exists, try to find any user (oldest first)
      systemUser = await User.findOne().sort({ createdAt: 1 });
      
      if (!systemUser) {
        console.log("⚠️  No users found in database.");
        console.log("   Default circles will be created automatically when the first user registers.");
        console.log("   Or call this function again after users are created.");
        return {
          created: 0,
          existing: 0,
          circles: [],
          message: "No users found. Circles will be created when users exist."
        };
      }
    }
    
    console.log(`Using user "${systemUser.email || systemUser._id}" as circle creator.`);

    const createdCircles = [];
    const existingCircles = [];

    for (const circleData of DEFAULT_CIRCLES) {
      // Check if circle with this name already exists
      const existingCircle = await Group.findOne({ 
        name: circleData.name,
        isActive: true,
        deletedAt: null
      });

      if (existingCircle) {
        console.log(`Circle "${circleData.name}" already exists.`);
        existingCircles.push(existingCircle);
        continue;
      }

      try {
        // Create the circle/group first
        const circle = new Group({
          name: circleData.name,
          description: circleData.description,
          type: circleData.type,
          topicType: circleData.topicType,
          creator: systemUser._id,
          admins: [systemUser._id],
          members: [{ 
            user: systemUser._id, 
            role: "admin",
            joinedAt: new Date()
          }],
          avatar: circleData.avatar,
          isActive: true,
          settings: {
            sendMessages: true,
            sendMedia: true,
            sendPolls: true,
            sendStickers: true,
            changeInfo: false,
            inviteUsers: true,
            pinMessages: false,
          },
        });

        await circle.save();

        // Create chat for the circle
        const chat = new Chat({
          type: "group",
          participants: [systemUser._id],
          group: circle._id,
          groupName: circleData.name,
          groupDescription: circleData.description,
          groupAdmin: systemUser._id,
        });
        await chat.save();

        // Update circle with chat reference
        circle.chat = chat._id;
        await circle.save();

        createdCircles.push(circle);
        console.log(`✅ Created circle: "${circleData.name}"`);
      } catch (error) {
        console.error(`Error creating circle "${circleData.name}":`, error.message);
      }
    }

    if (createdCircles.length > 0) {
      console.log(`\n✅ Successfully created ${createdCircles.length} default circle(s)`);
    }
    
    if (existingCircles.length > 0) {
      console.log(`ℹ️  ${existingCircles.length} circle(s) already exist`);
    }

    if (createdCircles.length === 0 && existingCircles.length === 0) {
      console.log("⚠️  No circles were created. Make sure there's at least one user in the database.");
    }

    return {
      created: createdCircles.length,
      existing: existingCircles.length,
      circles: [...createdCircles, ...existingCircles],
    };
  } catch (error) {
    console.error("Error initializing default circles:", error);
    throw error;
  }
};

/**
 * Ensure default circles exist (called on server startup and when needed)
 */
const ensureDefaultCircles = async () => {
  try {
    // Check if any circles exist
    const circleCount = await Group.countDocuments({ 
      isActive: true, 
      deletedAt: null 
    });

    if (circleCount === 0) {
      console.log("No circles found. Initializing default circles...");
      await initializeDefaultCircles();
    } else {
      // Check if all default circles exist
      const defaultCircleNames = DEFAULT_CIRCLES.map(c => c.name);
      const existingCircles = await Group.find({ 
        name: { $in: defaultCircleNames },
        isActive: true,
        deletedAt: null
      }).select("name");

      const existingNames = existingCircles.map(c => c.name);
      const missingNames = defaultCircleNames.filter(name => !existingNames.includes(name));

      if (missingNames.length > 0) {
        console.log(`Some default circles are missing: ${missingNames.join(", ")}`);
        console.log("Creating missing circles...");
        await initializeDefaultCircles();
      } else {
        console.log("All default circles exist.");
      }
    }
  } catch (error) {
    console.error("Error ensuring default circles:", error);
    // Don't throw - allow server to start even if circles can't be created
  }
};

module.exports = {
  initializeDefaultCircles,
  ensureDefaultCircles,
  DEFAULT_CIRCLES,
};

