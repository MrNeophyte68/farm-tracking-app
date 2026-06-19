const { getDB } = require("../config/database");
const { ObjectId } = require("mongodb");

// @desc    Create a new cow record
// @route   POST /api/cows
exports.createCow = async (req, res) => {
  try {
    const {
      tagNumber,
      birthDate,
      sex,
      breed,
      sireLine,
      damLine,
      status,
      lastCalvingDate,
    } = req.body;

    // 1. Structure the plain JavaScript object
    const newCow = {
      tagNumber,
      birthDate: birthDate ? new Date(birthDate) : null,
      sex,
      breed,
      sireLine,
      damLine,
      status,
      lastCalvingDate: lastCalvingDate ? new Date(lastCalvingDate) : null,
      createdAt: new Date() // Good practice to track creation time
    };

    // 2. Get the DB instance and target the "cows" collection
    const db = getDB();
    const result = await db.collection("cows").insertOne(newCow);

    // 3. Return the response containing the inserted ID
    res.status(201).json({
      success: true,
      message: "Cow created successfully",
      cowId: result.insertedId,
      cow: { _id: result.insertedId, ...newCow },
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

exports.deleteCow = async (req, res) => {
  try {
    const { id } = req.params;
    const db = getDB();
    const result = await db.collection("cows").deleteOne({ _id: new ObjectId(id) });

    if (result.deletedCount === 0) {
      return res.status(404).json({ success: false, message: "Cow not found" });
    }

    res.json({ success: true, message: "Cow deleted successfully" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};

exports.updateCow = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const db = getDB();
    const result = await db.collection("cows").updateOne({ _id: new ObjectId(id) }, { $set: updateData });

    if (result.matchedCount === 0) {
      return res.status(404).json({ success: false, message: "Cow not found" });
    }

    res.json({ success: true, message: "Cow updated successfully" });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
};
