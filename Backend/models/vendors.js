import mongoose from "mongoose";

const SolarInstallationCompanySchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true
    },
    city:{
        type: String,
    },
    district:{
        type: String,
        
    },
    state: {
        type: String,
       
    },
    
    contact_number: {
        type: String,
        
    },
    email: {
        type: String,
        
    },
    website: {
        type: String,
        
    },
    min_installation_cost: {
        type: Number, 
        
    },
    image_url: {
        type: String, 
        
    },
    services: {
        type: [String], 
        
    },
    supported_brands: {
        type: [String],  
    },

    request:[{
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
  },
  downloaded: {
    type: Boolean,
    default: false,
},
    }],
    emailCredits: {
        type: Number,
        default: 0, // Start with 0 until subscription
    },
    isSubscribed: {
        type: Boolean,
        default: false,
    },
    created_at: {
        type: Date,
        default: Date.now
    },
    shortLink:{
        type:String,
    },
    subscriptionType:{
       type:String,
    },
    EndDate:{
       type:String,
    }
});

export const SolarInstallationCompany = mongoose.model("SolarInstallationCompany", SolarInstallationCompanySchema);

