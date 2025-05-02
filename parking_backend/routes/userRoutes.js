const express= require('express');
const router = express.Router();
const {getUserProfile, changePassword, logoutUser}= require('../controllers/userController')

router.get('/users/me', getUserProfile);
router.put('/users/password', changePassword);
router.post('/users/logout',  logoutUser);

module.exports=router