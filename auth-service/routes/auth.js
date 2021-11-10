const app = require("express");
const router = app.Router();

const authController = require("../controller/authController");

router.get("/check", authController.check);
router.post("/signup-customer", authController.signupCustomer);
router.post("/signup-restaurant", authController.signupRestaurant);
router.post("/login", authController.login);

module.exports = router;
