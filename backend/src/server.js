require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { connectDB } = require("./config/database");
const http = require('http');
const { Server } = require('ws');
const cowRoutes = require("./routes/cowRoutes");
const { initCowSockets } = require("./sockets/cowSockets");

// Optional: Keep your custom DNS settings if your hosting requires it
require("node:dns/promises").setServers(["1.1.1.1", "8.8.8.8"]);

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// 1. Wrap the Express app in an HTTP Server
const server = http.createServer(app);

const wss = new Server({ server });

// Connect to Database
connectDB().then(() => {
  initCowSockets(wss);
});

// Mount Routes
app.use("/api/cows", cowRoutes);

const PORT = process.env.PORT || 5000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});