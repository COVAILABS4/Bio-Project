const express = require("express");
const bodyParser = require("body-parser");
const fs = require("fs");
const app = express();
const port = 3000;
const DATA_FILE = "data.json";

app.use(bodyParser.json());

// Helper function to read JSON data from the file
function readData() {
  if (fs.existsSync(DATA_FILE)) {
    const data = fs.readFileSync(DATA_FILE);
    return JSON.parse(data);
  }
  return [];
}

// Helper function to write JSON data to the file
function writeData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// Registration Endpoint
app.post("/register", (req, res) => {
  const { phone_number, dob } = req.body;

  console.log(phone_number, dob);

  console.log("Register");

  // Validate input
  if (!phone_number || !dob) {
    return res
      .status(400)
      .json({ message: "Phone number and DOB are required." });
  }

  // Read existing data
  const users = readData();

  // Check if user already exists
  const userExists = users.some((user) => user.phone_number === phone_number);
  if (userExists) {
    return res.status(409).json({ message: "User already registered." });
  }

  // Save new user data
  users.push({ phone_number, dob, newUser: true, userData: {} , hp_data : []});
  writeData(users);

  res.status(201).json({ message: "User registered successfully." });
});

// Login Endpoint
app.post("/login", (req, res) => {
  const { phone_number, dob } = req.body;

  console.log(phone_number, dob);

  console.log("Login");

  // Validate input
  if (!phone_number || !dob) {
    return res
      .status(400)
      .json({ message: "Phone number and DOB are required." });
  }

  // Read existing data
  const users = readData();

  // Check if user exists and if the credentials are correct
  const user = users.find((user) => user.phone_number === phone_number);
  if (!user) {
    return res.status(404).json({ message: "No user found." });
  }

  if (user.dob !== dob) {
    return res.status(401).json({ message: "Invalid password." });
  }

  res.status(200).json({ message: "Login successful.", newUser: user.newUser });
});

// New Survey Endpoint
app.post("/submit-survey", (req, res) => {
  const { phone_number, userData } = req.body;

  console.log(phone_number, userData);

  if (!phone_number || !userData) {
    return res
      .status(400)
      .json({ message: "Phone number and survey data are required." });
  }

  // Read existing data
  const users = readData();

  // Find user by phone number
  const userIndex = users.findIndex(
    (user) => user.phone_number === phone_number
  );
  if (userIndex === -1) {
    return res.status(404).json({ message: "User not found." });
  }

  // Update user data with survey data
  users[userIndex].userData = userData;

  users[userIndex].newUser = false;

  writeData(users);

  res.status(200).json({ message: "Survey data saved successfully." });
});

// Endpoint to get user data
app.get("/get-data", (req, res) => {
  var { phone_number } = req.query;

  phone_number = "+" + phone_number.trim();
  console.log(phone_number);
  // Validate input
  if (!phone_number) {
    return res.status(400).json({ message: "Phone number is required." });
  }

  // Read existing data
  const users = readData();

  // Find user by phone number
  const user = users.find((user) => user.phone_number === phone_number);
  if (!user) {
    return res.status(404).json({ message: "User not found." });
  }

  res.status(200).json(user);
});

// Endpoint to set user data
app.post("/set-data", (req, res) => {
  const { phone_number, userData } = req.body;

  console.log(phone_number, userData);

  if (!phone_number || !userData) {
    return res
      .status(400)
      .json({ message: "Phone number and user data are required." });
  }

  // Read existing data
  const users = readData();

  // Find user by phone number
  const userIndex = users.findIndex(
    (user) => user.phone_number === phone_number
  );
  if (userIndex === -1) {
    return res.status(404).json({ message: "User not found." });
  }

  // Update user data with new data
  users[userIndex].userData = userData;
  users[userIndex].newUser = false; // Set newUser to false as the user has provided data

  writeData(users);

  res.status(200).json({ message: "User data updated successfully." });
});


// Endpoint to save hp_data
app.post("/save-hp", (req, res) => {
  console.log("Called");
  
  const { phone_number, hp_data } = req.body;

  console.log(phone_number,hp_data);
  

  console.log(phone_number, hp_data);

  if (!phone_number || !hp_data) {
    return res
      .status(400)
      .json({ message: "Phone number and hp_data are required." });
  }

  // Read existing data
  const users = readData();

  // Find user by phone number
  const userIndex = users.findIndex(
    (user) => user.phone_number === phone_number
  );
  if (userIndex === -1) {
    return res.status(404).json({ message: "User not found." });
  }

  // Append the new hp_data to the existing hp_data array
  users[userIndex].hp_data = users[userIndex].hp_data.concat(hp_data);

  writeData(users);

  res.status(200).json({ message: "Health data saved successfully." });
});


app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
