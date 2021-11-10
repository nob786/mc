const bcrypt = require("bcryptjs");
const crypto = require("crypto");
//const nodemailer = require("nodemailer");
const jwt = require("jsonwebtoken");

const { Customer } = require("../models/customer");
const { Account } = require("../models/account");
const { Restaurant } = require("../models/restaurant");
const {
  validateUser,
  validateRestaurant,
  validateLogin,
} = require("../middleware/validation");

exports.check = async (req, res) => {
  console.log("Auth Check API is running good Yolo.");
  return res.json({
    messgae: "Auth Check API is running good indeed with speed",
  });
};

exports.login = async (req, res) => {
  const { error } = validateLogin(req.body);

  if (error) return res.status(400).send("Enter data in correct form.");

  const { email, password } = req.body;

  let loadedAccount = await Account.findOne({
    email: email,
  });

  if (!loadedAccount) return res.status(404).send("Account not found");

  let hashedPassword = await bcrypt.compare(password, loadedAccount.password);

  if (!hashedPassword) return res.status(404).send("Invalid Email or password");

  const token = jwt.sign({ accountId: loadedAccount._id.toString() }, "myKey");

  const loadedCustomer = await Customer.findOne({
    account: loadedAccount._id,
  });

  const loadedRestaurant = await Restaurant.findOne({
    account: loadedAccount._id,
  });

  if (!token)
    return res.status(400).json({
      message: "Token is empty",
      data: token,
    });
  else {
    if (loadedAccount.role === "restaurant") {
      return res.status(200).json({
        token: token,
        role: loadedAccount.role,
        id: loadedAccount._id,
        restaurant: loadedRestaurant,
      });
    } else if (loadedAccount.role === "customer") {
      return res.status(200).json({
        token: token,
        role: loadedAccount.role,
        id: loadedAccount._id,
        customer: loadedCustomer,
      });
    }
  }
};
/*exports.login = async (req, res) => {
  const { error } = validateLogin(req.body);

  if (error) return res.status(400).send("Enter data in correct form.");

  const { email, password } = req.body;

  let loadedAccount = await Account.findOne({
    email: email,
  });

  if (!loadedAccount) return res.status(404).send("Account not found");

  let hashedPassword = await bcrypt.compare(password, loadedAccount.password);

  if (!hashedPassword) return res.status(404).send("Invalid Email or password");

  const token = jwt.sign({ accountId: loadedAccount._id.toString() }, "myKey");

  if (!token)
    return res.status(400).json({
      message: "Token is empty",
      data: token,
    });
  else {
    return res.status(200).json({
      token: token,
      role: loadedAccount.role,
      id: loadedAccount._id,
    });
  }
};*/

exports.signupRestaurant = async (req, res) => {
  const { error } = validateRestaurant(req.body);

  if (error) return res.status(400).send("Enter data correctly");

  const {
    ownerName,
    restaurantName,
    contact,
    category,
    address,
    email,
    password,
    role,
  } = req.body;

  const user = await Account.findOne({ email: email });

  if (user) {
    return res.status(400).send("User already exists.");
  }

  const salt = await bcrypt.genSalt(12);
  const hashedPassword = await bcrypt.hash(password, salt);

  const verificationToken = crypto.randomBytes(32).toString("hex");

  let newAccount = new Account({
    email: email,
    password: hashedPassword,
    role: role,
    accountVerifyToken: verificationToken,
  });

  await newAccount
    .save()
    .then((savedAccount) => {
      console.log("Account has been registered", savedAccount);
    })
    .catch((err) => {
      console.log("Account not saved", err);
    });

  const newRestaurant = new Restaurant({
    ownerName: ownerName,
    restaurantName: restaurantName,
    contact: contact,
    category: category,
    address: address,
    account: newAccount._id,
  });

  console.log("New Restaurant created", newRestaurant);

  await newRestaurant
    .save()
    .then((savedRestaurant) => {
      console.log("Saved Your new restaurant");
      res.status(200).json({
        message: "Saved Restaurant",
        data: savedRestaurant,
      });
    })
    .catch((err) => {
      console.log("Customer could not be saved.", err);
      return res.status(500).json({
        message: "Could not save Restaurant.",
      });
    });
};

exports.signupCustomer = async (req, res) => {
  const { error } = validateUser(req.body);

  if (error) return res.status(400).send("Enter data correctly");

  const { firstName, lastName, contact, email, password, role } = req.body;

  const user = await Account.findOne({ email: email });

  if (user) {
    return res.status(404).send("User already exists.");
  }

  const salt = await bcrypt.genSalt(12);
  const hashedPassword = await bcrypt.hash(password, salt);

  const verificationToken = crypto.randomBytes(32).toString("hex");

  let newAccount = new Account({
    email: email,
    password: hashedPassword,
    role: role,
    accountVerifyToken: verificationToken,
  });

  await newAccount
    .save()
    .then((savedAccount) => {
      console.log("Account has been registered", savedAccount);
    })
    .catch((err) => {
      console.log("Account not saved", err);
    });

  const newCustomer = new Customer({
    firstName: firstName,
    lastName: lastName,
    contact: contact,
    account: newAccount._id,
  });

  console.log("New Customer object created", newCustomer);

  await newCustomer
    .save()
    .then((savedCustomer) => {
      console.log("Customer Saved Successfully");
      res.status(200).json({
        message: "Saved Customer",
        data: savedCustomer,
      });
    })
    .catch((err) => {
      console.log("Customer could not be saved.", err);
      return res.status(500).json({
        message: "Could not save customer.",
        error: err,
      });
    });
};
