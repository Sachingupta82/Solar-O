import { getWeatherData } from './weatherController.js';
// import solarPanels from './solar.json' assert { type: "json" };

import { solarPanels } from './solar.js';


// const solarPanels = [
//     { id: 1, brand: "Luminous", model: "Polycrystalline 170W/12V", power_wattage: 170, efficiency: 15.5, price: 6500, temperature_coefficient: -0.38, warranty_years: 25, degradation_rate: 0.5, voc: 23.01, isc: 9.61, low_light_performance: 85, wind_snow_resistance: 5400, installation_type: "Flat Roof, Slanted Roof", width: 1.48, height: 0.67 },
//     { id: 2, brand: "Navitas Solar", model: "Navisol Series 320W", power_wattage: 320, efficiency: 17.1, price: 12000, temperature_coefficient: -0.45, warranty_years: 10, degradation_rate: 0.7, voc: 45.2, isc: 9.0, low_light_performance: 80, wind_snow_resistance: 5000, installation_type: "Ground-Mount, Slanted Roof", width: 1.95, height: 1.0 },
//     { id: 3, brand: "UTL Solar", model: "100W Polycrystalline", power_wattage: 100, efficiency: 15.0, price: 4738, temperature_coefficient: -0.41, warranty_years: 25, degradation_rate: 0.6, voc: 21.6, isc: 6.3, low_light_performance: 78, wind_snow_resistance: 4000, installation_type: "Flat Roof, Portable", width: 1.20, height: 0.60 },
//     { id: 4, brand: "RenewSys", model: "Deserv Series 340W", power_wattage: 340, efficiency: 18.0, price: 13000, temperature_coefficient: -0.39, warranty_years: 25, degradation_rate: 0.5, voc: 37.65, isc: 9.05, low_light_performance: 82, wind_snow_resistance: 5200, installation_type: "Slanted Roof, Ground-Mount", width: 2.00, height: 1.0 },
//     { id: 5, brand: "Solar Technology", model: "60W Crystalline", power_wattage: 60, efficiency: 14.5, price: 26735, temperature_coefficient: -0.42, warranty_years: 20, degradation_rate: 0.7, voc: 17.2, isc: 4.0, low_light_performance: 75, wind_snow_resistance: 3000, installation_type: "Portable, Flat Roof", width: 0.90, height: 0.50 },
//     { id: 6, brand: "Luminous", model: "Mono PERC 550W/24V", power_wattage: 550, efficiency: 21.0, price: 17000, temperature_coefficient: -0.30, warranty_years: 25, degradation_rate: 0.4, voc: 49.80, isc: 13.98, low_light_performance: 90, wind_snow_resistance: 6000, installation_type: "Flat Roof, Slanted Roof", width: 2.20, height: 1.10 },
//     { id: 7, brand: "UTL Solar", model: "400W Monocrystalline", power_wattage: 400, efficiency: 20.2, price: 18837, temperature_coefficient: -0.29, warranty_years: 25, degradation_rate: 0.3, voc: 49.79, isc: 10.31, low_light_performance: 88, wind_snow_resistance: 5500, installation_type: "Slanted Roof, Ground-Mount", width: 2.10, height: 1.05 },
//     { id: 8, brand: "SunPower", model: "Maxeon 3", power_wattage: 400, efficiency: 22.6, price: 35000, temperature_coefficient: -0.26, warranty_years: 25, degradation_rate: 0.25, voc: 69.5, isc: 6.2, low_light_performance: 92, wind_snow_resistance: 5400, installation_type: "Flat Roof, Slanted Roof", width: 1.80, height: 1.05 },
//     { id: 9, brand: "LG", model: "NeON R", power_wattage: 380, efficiency: 21.4, price: 32000, temperature_coefficient: -0.30, warranty_years: 25, degradation_rate: 0.3, voc: 66.8, isc: 6.1, low_light_performance: 88, wind_snow_resistance: 5000, installation_type: "Slanted Roof, Ground-Mount", width: 1.90, height: 1.00 },
//     { id: 10, brand: "Canadian Solar", model: "HiKu 365", power_wattage: 365, efficiency: 20.2, price: 28000, temperature_coefficient: -0.34, warranty_years: 20, degradation_rate: 0.35, voc: 67.5, isc: 5.8, low_light_performance: 85, wind_snow_resistance: 4500, installation_type: "Flat Roof, Ground-Mount", width: 1.95, height: 1.05 }
// ];


const normalize = (value, min, max) => {
    return max !== min ? 10 * (value - min) / (max - min) : 0;
};


export const recommendSolarPanel = async (latitude, longitude) => {
    
    const weatherData = await getWeatherData(latitude, longitude);
    console.log(weatherData);

    const avgWeather = weatherData.avgHistoryData;
    console.log("test :",avgWeather);
    
    if (!weatherData) return null;


    
    const minMax = {
        temperature_coefficient: { min: Math.min(...solarPanels.map(p => Math.abs(p.temperature_coefficient))), max: Math.max(...solarPanels.map(p => Math.abs(p.temperature_coefficient))) },
        voc: { min: Math.min(...solarPanels.map(p => p.voc)), max: Math.max(...solarPanels.map(p => p.voc)) },
        wind_snow_resistance: { min: Math.min(...solarPanels.map(p => p.wind_snow_resistance)), max: Math.max(...solarPanels.map(p => p.wind_snow_resistance)) },
        low_light_performance: { min: Math.min(...solarPanels.map(p => p.low_light_performance)), max: Math.max(...solarPanels.map(p => p.low_light_performance)) },
        efficiency: { min: Math.min(...solarPanels.map(p => p.efficiency)), max: Math.max(...solarPanels.map(p => p.efficiency)) },
        degradation_rate: { min: Math.min(...solarPanels.map(p => p.degradation_rate)), max: Math.max(...solarPanels.map(p => p.degradation_rate)) },
        isc: { min: Math.min(...solarPanels.map(p => p.isc)), max: Math.max(...solarPanels.map(p => p.isc)) },
    };
    
    const scoredPanels = solarPanels.map(panel => {
        let score = 0;

      
        // const tempCoeff = normalize(Math.abs(panel.temperature_coefficient), minMax.temperature_coefficient.min, minMax.temperature_coefficient.max);
        const vocNorm = normalize(panel.voc, minMax.voc.min, minMax.voc.max);
        const tempCoeff = Math.abs(panel.temperature_coefficient);
        const tempFactor = Math.min(Math.abs(avgWeather.avgTemperature - 25) / 15, 1);
        score = tempCoeff * (0.2 + 0.3 * tempFactor);

        if (avgWeather.avgTemperature < 15) {
            const vocBoost = Math.min((15 - avgWeather.avgTemperature) / 10, 1); // up to 1
            score += vocNorm * 0.5 * vocBoost;
        }        
       
        const windNorm = normalize(panel.wind_snow_resistance, minMax.wind_snow_resistance.min, minMax.wind_snow_resistance.max);
        score += windNorm * Math.min(avgWeather.avgWindSpeed / 10, 1);

        
        const lowLightNorm = normalize(panel.low_light_performance, minMax.low_light_performance.min, minMax.low_light_performance.max);
        const scaledDHI = Math.min(avgWeather.avgDHI / 1000, 1);  // normalize DHI
        const DHIWeight = 0.20 + 0.30 * scaledDHI;
        score += lowLightNorm * DHIWeight;


        
        const efficiencyNorm = normalize(panel.efficiency, minMax.efficiency.min, minMax.efficiency.max);
        const scaledDNI = Math.min(avgWeather.avgDNI / 6000, 1);  // normalize to 0–1, cap at 1
        const DNIWeight = 0.20 + 0.30 * scaledDNI;  // scales from 0.20 to 0.50
        score += efficiencyNorm * DNIWeight;


       
        // const degradationNorm = normalize(panel.degradation_rate, minMax.degradation_rate.min, minMax.degradation_rate.max);
        const degradationNorm = panel.degradation_rate;
        if (avgWeather.avgTemperature > 25) {
            score -= degradationNorm * 0.50;
        } else if (avgWeather.avgTemperature < 10) {
            score -= degradationNorm * 0.30;
        } else {
            score -= degradationNorm * 0.20;
        }

       
        const iscNorm = normalize(panel.isc, minMax.isc.min, minMax.isc.max);
        const scaledGHI = Math.min(avgWeather.avgGHI / 4000, 1);  // normalize to 0–1, cap at 1
        const GHIWeight = 0.20 + 0.30 * scaledGHI;  // scales from 0.20 to 0.50
        score += iscNorm * GHIWeight;

        const isCloudy = avgWeather.avgDHI / avgWeather.avgGHI > 0.6;
        const isSunny = avgWeather.avgDNI > 6000;

        if (isCloudy && panel.material === 'Thin-Film') score += 0.5;
        if (isSunny && (panel.material === 'Monocrystalline' || panel.material === 'Polycrystalline')) score += 0.4;

        return { panel, score };
    });

    
        const minScore = Math.min(...scoredPanels.map(p => p.score));
        const maxScore = Math.max(...scoredPanels.map(p => p.score));

        
        const normalizedPanels = scoredPanels.map(({ panel, score }) => {
            const normalizedScore = ((score - minScore) / (maxScore - minScore)) * 10;
            return { panel, score: normalizedScore };
        });

        normalizedPanels.sort((a, b) => b.score - a.score);

    const top10 = normalizedPanels.slice(0,10);
    const pricesort = [...top10].sort((a, b) => b.panel.price - a.panel.price);
    const HighestPrice = pricesort[0];
    const LowestPrice = pricesort[9];
    const averagePrice = pricesort[5];
    let onemorebest = null;
    if(avgWeather.avgDHI / avgWeather.avgGHI > 0.6){
       const arryofthinflim = top10.filter((thin)=>thin.panel.material === "Thin-Film");
       if (arryofthinflim.length > 0) {
        onemorebest = arryofthinflim.reduce((max, panel) => 
            (panel.score > max.score ? panel : max), arryofthinflim[0]);
      }
    }
    // const bestRecommended = top10.slice(0,3).reduce((best ,current)=>  best.score-current.score<=1.5 && best.panel.price<current.panel.price? best : current, top10[0]);
    const bestRecommended = top10.slice(0,2).find((best)=>top10[0].score-best.score<=1.1 && best.panel.price< top10[0].panel.price* 0.85? best :top10[0]);

    console.log(bestRecommended, HighestPrice, LowestPrice, averagePrice, onemorebest);

    if( normalizedPanels){
        return {
            
            scoredPanels: normalizedPanels.map(p => ({ ...p.panel, score: p.score.toFixed(2) })) ,

            bestRecommended: { ...bestRecommended.panel,
                              score: bestRecommended.score.toFixed(2),
                              reason: "This panel is the best overall recommendation based on the weather conditions of your location, efficiency, cost, and performance." },

            HighestPrice: {...HighestPrice.panel, 
                          score: HighestPrice.score.toFixed(2),
                          reason: "This panel has the highest price among the available options, which might indicate premium quality or advanced features."},

            LowestPrice: {...LowestPrice.panel, 
                         score: LowestPrice.score.toFixed(2),
                         reason: "This panel is the most affordable option, making it a budget-friendly choice."},

            AveragePrice: {...averagePrice.panel,
                           score: averagePrice.score.toFixed(2),
                           reason: "This panel is priced around the average of all available options, balancing cost and features."},
            
            Onemorebest: onemorebest 
                           ? { 
                               ...onemorebest.panel, 
                               score: onemorebest.score.toFixed(2), 
                               reason: "The material of this panel is Thin-Film, which is suitable for high temperatures." 
                             } 
                           : null,
            avgWeather                  
        };
    }
            
    // return scoredPanels.length >= 5
    //     ? scoredPanels.slice(0, 5).map(p => ({ ...p.panel, score: p.score.toFixed(2) })) 
    //     : scoredPanels.length >= 1 
    //     ? scoredPanels.map(p => ({ ...p.panel, score: p.score.toFixed(2) })) 
    //     : null;

};

export const getAvgWeather = () => avgWeather;

