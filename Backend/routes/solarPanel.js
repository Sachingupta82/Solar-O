import express from 'express';
import { Budget , formData, Solardata, electricityCalculation, quotation, calculateRecoveryGraph, getVendors, sendQuotation , roofimages, getLeadJson , sendRequest, dashboard , vendorSub, apigot, finalApi} from '../controllers/details.js';

import multer from'multer';
import { storage } from '../cloudConfig.js';

const upload = multer({storage});
const router = express.Router();

router.route('/form').get(formData);

router.route('/dashboard/:vid/:id').get(dashboard);

router.post('/budget', upload.single('image'), Budget);

router.route('/vendor/subscribe').put(vendorSub);

router.put('/:id/upload', upload.array('images', 10), roofimages);

router.route('/:id/solardata').put(Solardata);

router.route('/:id/electricityCalculation').put(electricityCalculation);

router.route('/:id/calculateGraph').post(calculateRecoveryGraph);

router.route('/:id/quotation').put(quotation);

router.route('/:id/getVendors').get(getVendors);


export default router;