const mongoose = require("mongoose");
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
require("dotenv").config();
const app = express();

// Importing auth route
const auth = require("./routes/auth");

// Process env variables
PORT = process.env.PORT;
//const dbUrl = process.env.DB_URL || "mongodb://localhost/vidly";

mongoose
  .connect(
    `mongodb+srv://${process.env.DB_USER_NAME}:${process.env.DB_USER_PASS}@cluster0.mj1ib.mongodb.net/${process.env.DB_NAME}?retryWrites=true&w=majority`,
    { useNewUrlParser: true },
    { useUnifiedTopology: true }
  )
  .then(() => console.log("Monogo is running"))
  .catch((error) => console.log("Error while connecting to atlas", error));

app.use(express.json());
app.use(cors());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.use("/auth", auth);

app.get("/", (req, res) => {
  return res.status(200).send("Auth is running.");
});

app.listen(PORT, () => {
  console.log(`Auth service running on PORT, ${PORT}`);
  // console.log(process.env.DB_USER_NAME);
});
