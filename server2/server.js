const express = require("express");
const bodyParser = require("body-parser");
const mongoose = require("mongoose");

const app = express();
const port = 4000;

// MongoDB connection
const mongoURI = "mongodb+srv://covailabs4:KRISHtec5747@cluster0.ny4i2.mongodb.net/BMEdb";
mongoose.connect(mongoURI, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log("MongoDB connected"))
  .catch((error) => console.error("MongoDB connection error:", error));

// Middleware
app.use(bodyParser.json());

// Define Mongoose schema and model
const hpDataSchema = new mongoose.Schema({
  time: String,
  date: String,
  hp_value: Number,
  grade: String
});

const userSchema = new mongoose.Schema({
  phone_number: { type: String, required: true, unique: true },
  dob: { type: String, required: true },
  newUser: { type: Boolean, default: true },
  userData: {
    name: String,
    gender: String,
    age: String,
    address: String,
    adhaar_number: String,
    height: String,
    weight: String,
    diagnosis: [String]
  },
  hp_data: [hpDataSchema]
});

const User = mongoose.model("User", userSchema);

// Registration Endpoint
app.post("/register", async (req, res) => {
  const { phone_number, dob } = req.body;

  if (!phone_number || !dob) {
    return res.status(400).json({ message: "Phone number and DOB are required." });
  }

  try {
    const existingUser = await User.findOne({ phone_number });
    if (existingUser) {
      return res.status(409).json({ message: "User already registered." });
    }

    const newUser = new User({ phone_number, dob });
    await newUser.save();

    res.status(201).json({ message: "User registered successfully." });
  } catch (error) {
    res.status(500).json({ message: "Server error.", error });
  }
});

// Login Endpoint
app.post("/login", async (req, res) => {
  const { phone_number, dob } = req.body;

  if (!phone_number || !dob) {
    return res.status(400).json({ message: "Phone number and DOB are required." });
  }

  try {
    const user = await User.findOne({ phone_number });
    if (!user) {
      return res.status(404).json({ message: "No user found." });
    }

    if (user.dob !== dob) {
      return res.status(401).json({ message: "Invalid password." });
    }

    res.status(200).json({ message: "Login successful.", newUser: user.newUser });
  } catch (error) {
    res.status(500).json({ message: "Server error.", error });
  }
});

// New Survey Endpoint
app.post("/submit-survey", async (req, res) => {
  const { phone_number, userData } = req.body;

  if (!phone_number || !userData) {
    return res.status(400).json({ message: "Phone number and survey data are required." });
  }

  try {
    const user = await User.findOneAndUpdate(
      { phone_number },
      { userData, newUser: false },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    res.status(200).json({ message: "Survey data saved successfully." });
  } catch (error) {
    res.status(500).json({ message: "Server error.", error });
  }
});

// Endpoint to get user data
app.get("/get-data", async (req, res) => {
  let { phone_number } = req.query;
  phone_number = "+" + phone_number.trim();

  if (!phone_number) {
    return res.status(400).json({ message: "Phone number is required." });
  }

  try {
    const user = await User.findOne({ phone_number });
    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    res.status(200).json(user);
  } catch (error) {
    res.status(500).json({ message: "Server error.", error });
  }
});

// Endpoint to set user data
app.post("/set-data", async (req, res) => {
  const { phone_number, userData } = req.body;

  if (!phone_number || !userData) {
    return res.status(400).json({ message: "Phone number and user data are required." });
  }

  try {
    const user = await User.findOneAndUpdate(
      { phone_number },
      { userData, newUser: false },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    res.status(200).json({ message: "User data updated successfully." });
  } catch (error) {
    res.status(500).json({ message: "Server error.", error });
  }
});

// Endpoint to save hp_data
app.post("/save-hp", async (req, res) => {
  const { phone_number, hp_data } = req.body;

  console.log(phone_number,hp_data);
  

  if (!phone_number || !hp_data) {
    return res.status(400).json({ message: "Phone number and hp_data are required." });
  }

  try {
    const user = await User.findOne({ phone_number });
    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    user.hp_data = user.hp_data.concat(hp_data);
    await user.save();

    res.status(200).json({ message: "Health data saved successfully." });
  } catch (error) {
    res.status(500).json({ message: "Server error.", error });
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
