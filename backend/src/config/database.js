const { MongoClient } = require("mongodb");

const client = new MongoClient(process.env.MONGO_URI);
let dbConnection;

async function connectDB() {
  try {
    await client.connect();
    console.log("Connected successfully to MongoDB");
    // Change "farm_database" to whatever you want your DB name to be
    dbConnection = client.db("farm_database"); 
  } catch (err) {
    console.error("MongoDB connection failed:", err);
    process.exit(1);
  }
}

function getDB() {
  if (!dbConnection) {
    throw new Error("Database not initialized. Call connectDB first.");
  }
  return dbConnection;
}

module.exports = { connectDB, getDB };