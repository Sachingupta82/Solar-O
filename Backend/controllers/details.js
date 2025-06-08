import { SolarDetail } from "../models/solarDetail.js";
import { recommendSolarPanel } from "./solarController.js";
import { SolarInstallationCompany } from "../models/vendors.js";
import { getHtmlContent } from "./htmlcontent.js";
import puppeteer from 'puppeteer';
import nodemailer from 'nodemailer';
import axios from 'axios';

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: 'sivachatbot@gmail.com',
      pass: 'zyullbomcvdmailh' 
    }
  });

export const formData = (req,res)=>{
    res.render('form');
}

export const dashboard =async(req,res)=>{
    try {
        const {vid} = req.params; // getting {vid} from URL
        const {id}=req.params;
        const vendor = await SolarInstallationCompany.findById(vid);
    
        if (!vendor) {
          return res.status(404).send('Vendor not found');
        }
        const requests = vendor.request;

        const requestCounts = {
            Mon: 0,
            Tue: 0,
            Wed: 0,
            Thu: 0,
            Fri: 0,
            Sat: 0,
            Sun: 0
          };
      
          // Loop through the requests and group them by the day of the week
          requests.forEach(request => {
            const requestDate = new Date(request.created_at);
            const dayOfWeek = requestDate.toLocaleString('en-us', { weekday: 'short' }); // Get day abbreviation (e.g. 'Mon', 'Tue')
            if (requestCounts[dayOfWeek] !== undefined) {
              requestCounts[dayOfWeek] += 1; // Increment the count for that day
            }
          });
      
          // Convert the counts into an array that will be used in the chart
          const requestData = [
            requestCounts.Mon,
            requestCounts.Tue,
            requestCounts.Wed,
            requestCounts.Thu,
            requestCounts.Fri,
            requestCounts.Sat,
            requestCounts.Sun
          ];
      
        res.render('dashboard', { vendor,requests,requestData,id });
      } catch (error) {
        console.error(error);
        res.status(500).send('Something went wrong');
      }
}

export const Budget = async (req , res)=>{
    const { id, username, rooftopArea,powerConsumption , billPrice, sanctionload , unitprice} = req.body;
    const { latitude, longitude } = req.body.coordinates;
    console.log(id,username,rooftopArea);
    const url = req.file ? req.file.path : null;
    console.log(req.file);
    
    // const longitude = 73.4642;
    // const latitude = 17.6508;

    const url1 = `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`;

    const response = await fetch(url1);
    const data = await response.json();
    console.log(data);
    let Address;
    if( data.display_name){
        Address = data.display_name
    }else{
        res.json({message:"address is not found"});
    }
    
    try{
        const userexist = await SolarDetail.findOne({id :id});
        if(userexist){
            await SolarDetail.deleteOne({id : id});
        }
        await SolarDetail.create({id,username,rooftopArea,coordinates: { latitude: Number(latitude), longitude: Number(longitude) },url,powerConsumption , billPrice, Address,sanctionload, unitprice});
        res.status(201).send('Budget created successfully');
        console.log("Budget created successfully");
    }catch(err){
        console.error(err);
        return res.status(500).send('Server Error');
    };
}

export const roofimages = async(req,res)=>{
    const {id} = req.params;
    const userinfo = await SolarDetail.findOne({ id:id});
    if (!userinfo) {
        return res.status(404).json({ error: "User not found" });
    }
    const imageUrls = req.files ? req.files.map(file => file.path) : [];
    
    try{
        await SolarDetail.findOneAndUpdate(
            { id: id },
            { $set: { urls: imageUrls } }, 
            { new: true}
        );
        res.status(200).send('Image uploaded successfully');
        console.log("Image uploaded successfully");
    }catch(err){
        console.error(err);
        return res.status(500).send(err.message);
    }
}

export const Solardata = async (req, res) => {
    const {id} = req.params;
    const userinfo = await SolarDetail.findOne({ id:id});
    const latitude = userinfo.coordinates.latitude;
    const longitude = userinfo.coordinates.longitude;
    const {scoredPanels,bestRecommended,HighestPrice,LowestPrice, AveragePrice, Onemorebest,avgWeather} = await recommendSolarPanel(latitude,longitude);
    if (!scoredPanels) {
        return res.status(500).send({ error: "No suitable solar panel found" });
    }
    if(avgWeather) {
        console.log(avgWeather);
    }else{
        console.log("Weather data not found");
    }

    if(avgWeather){
        await SolarDetail.findOneAndUpdate(
            { id: id },
            { $set: { climate: avgWeather } }, 
            { new: true}
        );
        console.log("Climate updated successfully")
    }
    if(Onemorebest){
      return res.json({ panels: scoredPanels,bestRecommended,HighestPrice,LowestPrice, AveragePrice,Onemorebest});
    }else{
        return res.json({ panels: scoredPanels, bestRecommended,HighestPrice, LowestPrice, AveragePrice});
    }
    
}

export const electricityCalculation = async(req,res)=>{
    
    const {panelInfo} = req.body;
    console.log(panelInfo);
    const {id} = req.params;
    const panelArea =  panelInfo.height * panelInfo.width; 
    const userinfo = await SolarDetail.findOne({ id:id});
    const avgWeather = userinfo.climate;
    console.log("Average weather data :", avgWeather);
    if (!avgWeather) {
        return res.status(500).send({ error: "Failed to fetch average weather data" });
    }
    if (userinfo.rooftopArea<panelArea){
  
      res.json({message :"Your Rooftop area is too Small"});
    }else{
        const updatedPanelInfo = await SolarDetail.findOneAndUpdate(
            { id: id },
            { $set: { solarPanel: {...panelInfo } } },
            { new: true}
        );
    
        console.log("Panel info updated successfully");
    }

    const usableArea  = userinfo.rooftopArea * 0.80;

    const panelCount = Math.floor(usableArea / panelArea);


    console.log("Panel count :", panelCount);

    const efficiency = panelInfo.efficiency / 100;  
    const tempCoeff = panelInfo.temperature_coefficient; 
    const avgTemperature = avgWeather.avgTemperature;
    const avgGHI = avgWeather.avgGHI; 
    
    const dailyIrradiance = avgGHI / 1000;
    const theoreticalDailyEnergy = panelArea * efficiency * dailyIrradiance;
    
    const deltaT = avgTemperature - 25; 
    const efficiencyLoss = tempCoeff * deltaT;
    const adjustedEfficiency = efficiency * (1 + efficiencyLoss);
    
    const adjustedDailyEnergy = panelArea * adjustedEfficiency * dailyIrradiance;
    console.log(adjustedDailyEnergy);
   
    const soilingLossFactor = 0.90; 
    const energyAfterSoiling = adjustedDailyEnergy * soilingLossFactor;

    const inverterEfficiency = 0.85; 
    const finalDailyEnergy = energyAfterSoiling * inverterEfficiency;
    
    const consumption = userinfo.powerConsumption;
    const recommendedPanelCount = Math.ceil(consumption / (finalDailyEnergy * 30));

    let maxEnergy = finalDailyEnergy * panelCount;
    let recommendedPanelCountEnergy = finalDailyEnergy * recommendedPanelCount;
    let recommendedPanelMonthEnergy = finalDailyEnergy * recommendedPanelCount *30;
    return res.json({
        
        finalDailyEnergy: finalDailyEnergy.toFixed(2) + " kWh",
        monthlyEnergy: (finalDailyEnergy * 30).toFixed(2) + " kWh",
        yearlyEnergy: (finalDailyEnergy * 365).toFixed(2) + " kWh",
        maxEnergy,
        panelCount,
        recommendedPanelCount,
        recommendedPanelCountEnergy,
        recommendedPanelMonthEnergy
    });
}

export const quotation = async(req, res)=>{
    try{
      const {panelCount,monthlyEnergyGeneration,numberofinverter,installationtype,totalQuotation} = req.body;
      const {id} = req.params;
      const userinfo = await SolarDetail.findOne({ id:id});
      const solaroutput = userinfo.solarPanel.power_wattage;
      const solarSysteminKW = (solaroutput*panelCount)/1000;
      await SolarDetail.findOneAndUpdate(
          { id: id },
          { $set: { panelCount, monthlyEnergyGeneration,solarSysteminKW,numberofinverter,installationtype,totalQuotation } },
          { new: true}
      );
      res.status(200).send('Quotation data updated successfully');
    }catch(err){
     console.error(err);
     return res.status(500).send(err.message);
    }
 }

 export const calculateRecoveryGraph = async (req, res) => {
    const { totalPrice,monthlyEnergyGeneration} = req.body;
    const {id} = req.params;
    const userinfo = await SolarDetail.findOne({ id:id});
    const unitConsumption = userinfo.powerConsumption;
    const billPrice = userinfo.billPrice;

    const yearlyBill = billPrice * 12; 
    let yearlyGeneration = monthlyEnergyGeneration * 12; 

    let yearlySavings;
    if (yearlyGeneration >= unitConsumption * 12) {
        yearlySavings = yearlyBill; 
    } else {
        let remainingUnits = (unitConsumption * 12) - yearlyGeneration;
        let costPerUnit = yearlyBill / (unitConsumption * 12); 
        let remainingCost = remainingUnits * costPerUnit;
        yearlySavings = yearlyBill - remainingCost; 
    }

    let savedMoney = 0;
    let years = 0;
    let dataPoints = [];
    let electricityInflationRate = 0.05; 
    let efficiencyLossRate = 0.03; 

    while (savedMoney < totalPrice) {
        savedMoney += yearlySavings;
        years++;

        
        yearlySavings *= (1 + electricityInflationRate);

       
        yearlyGeneration *= (1 - efficiencyLossRate);

        dataPoints.push({
            x: years,
            y: savedMoney.toFixed(2),
        });
    }

    res.json({ dataPoints, yearsToRecover: years });
};

export const getVendors = async (req, res) => {
    const { id } = req.params;

    try {
        const userinfo = await SolarDetail.findOne({ id: id });

        if (!userinfo) {
            return res.status(404).json({ error: "User not found" });
        }

        const { latitude, longitude } = userinfo.coordinates;
        // const longitude = 72.8705;
        // const latitude = 19.0216;

        const url = `https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`;

        const response = await fetch(url);
        const data = await response.json();
        console.log(data);
        let city = data.address?.city;
        let district = data.address?.state_district;
        let state = data.address?.state || "Maharashtra"; 

        let companies;

        if (district) {
            companies = await SolarInstallationCompany.find({ district });
            
            if (companies.length > 0) {
                return res.json({ companies });
            }
        }

        if (city) {
            companies = await SolarInstallationCompany.find({ city });
            
            if (companies.length > 0) {
                return res.json({ companies }); 
            }
        }

        
        companies = await SolarInstallationCompany.find({ state });
        return res.json({ companies }); // Always return a response

        
        

    } catch (error) {
        console.error("Error fetching state:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

