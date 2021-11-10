const mongoose = require("mongoose");
const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
require("dotenv").config();
const app = express();

const user = require("./routes/user");

mongoose
  .connect(
    `mongodb+srv://${process.env.DB_USER_NAME}:${process.env.DB_USER_PASS}@cluster0.mj1ib.mongodb.net/${process.env.DB_NAME}?retryWrites=true&w=majority`,
    { useNewUrlParser: true },
    { useUnifiedTopology: true }
  )
  .then(() => console.log("Monogo is running"))
  .catch((error) => console.log("Error while connecting to atlas", error));

app.use(express.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(cors());

app.use("/user", user);

PORT = process.env.PORT;

// if (process.env.NODE_ENV == "production") {
//   app.use(express.static("client/build"));
// }

app.listen(PORT, () => {
  console.log(`Listening to port ${PORT}...`);
});
