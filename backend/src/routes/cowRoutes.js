const express = require("express");
const router = express.Router();
const cowController = require("../controllers/cowController");

// Route: /api/cows
router.post("/", cowController.createCow);

router.delete("/:id", cowController.deleteCow);

router.put("/:id", cowController.updateCow);

module.exports = router;