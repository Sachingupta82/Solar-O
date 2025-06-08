import mongoose from 'mongoose';

const solarDetail =  mongoose.Schema({
  id: String,
  username: String,
  rooftopArea: Number,
  Address:String,
  contact:Number,
  coordinates: {
    latitude: Number,
    longitude: Number
},
  url:{
    type:String,
  },
  solarPanel :{
    id: String,
    brand: String,
    model: String,
    material: String,
    power_wattage: Number,
    efficiency: Number,
    price: Number,
    temperature_coefficient: Number,
    warranty_years: Number,
    degradation_rate: Number,
    voc: Number,
    isc: Number,
    low_light_performance: Number,
    wind_snow_resistance: Number,
    installation_type: String,
  },
  budget : Number,
  powerConsumption : Number,
  billPrice : Number,
  climate:{
    avgTemperature: Number,
    avgSolarRadiation: Number,
    avgGHI: Number,
    avgDNI: Number,
    avgDHI: Number,
    avgCloudCover: Number,
    avgWindSpeed : Number,
    avgHumidity : Number,
  },
  panelCount:Number,
  monthlyEnergyGeneration:Number,
  solarSysteminKW: Number,
  installationtype: String,
  scheme:{
    type:String,
    default:"PM Surya Ghar yojna"
  },
  numberofinverter: Number,
  totalQuotation:Number,
  sanctionload:Number,
  unitprice:Number,
  urls :[],
  created_at: {
    type: Date,
    default: Date.now
  }
});

export const SolarDetail = mongoose.model('SolarDetail', solarDetail);