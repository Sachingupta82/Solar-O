import axios from 'axios';

const API_KEY = "42f60209c20e49d39c514da626ad61c9"; 


export const getWeatherData = async (latitude, longitude) => {
    try { 
        
        const today = new Date();
        const startDate = new Date();
        startDate.setDate(today.getDate() - 10);
        
        // const formattedStartDate = startDate.toISOString().split('T')[0]; // YYYY-MM-DD
        // const formattedEndDate = today.toISOString().split('T')[0]; // YYYY-MM-DD
        const formattedStartDate = "2024-12-15";
        const formattedEndDate = "2024-12-30";
        

        const historyUrl = `https://api.weatherbit.io/v2.0/history/daily?lat=${latitude}&lon=${longitude}&start_date=${formattedStartDate}&end_date=${formattedEndDate}&key=${API_KEY}`;
        
        
        // const historyUrl = `https://api.weatherbit.io/v2.0/history/daily?city=${LOCATION}&start_date=${formattedStartDate}&end_date=${formattedEndDate}&key=${API_KEY}`;
        // const forecastUrl = `https://api.weatherbit.io/v2.0/forecast/energy?city=${LOCATION}&key=${API_KEY}`;

        
        const [historyRes] = await Promise.all([
            axios.get(historyUrl),
            // axios.get(forecastUrl)
        ]);

        
        const historyData = historyRes.data.data;
        const avgHistoryData = calculateAverages(historyData);

        
        console.log(avgHistoryData);
        

        
        // const forecastData = forecastRes.data.data;
        // const avgForecastData = calculateAverages(forecastData);

      
        return { avgHistoryData};
    } catch (error) {
        console.error('Error fetching solar weather data:', error.message);
        return null;
    }
};


const calculateAverages = (data) => {
    let avgTemperature = 0;
    let avgSolarRadiation = 0;
    let avgGHI = 0;
    let avgDNI = 0;
    let avgDHI = 0;
    let avgCloudCover = 0;
    let avgWindSpeed = 0;
    let avgHumidity = 0;
    let avgSunhours = 0;
   

   
    data.forEach(day => {
        avgTemperature += day.temp;
        avgSolarRadiation += day.t_solar_rad;
        avgGHI += day.t_ghi;
        avgDNI += day.t_dni;
        avgDHI += day.t_dhi;
        avgCloudCover += day.clouds;
        avgWindSpeed += day.wind_spd;
        avgHumidity += day.rh;
        avgSunhours += day.sun_hours;
    });

    
    const totalDays = data.length;
    
    return {
        avgTemperature: avgTemperature / totalDays,
        avgSolarRadiation: avgSolarRadiation / totalDays,
        avgGHI: avgGHI / totalDays,
        avgDNI: avgDNI / totalDays,
        avgDHI: avgDHI / totalDays,
        avgCloudCover: avgCloudCover / totalDays,
        avgWindSpeed: avgWindSpeed / totalDays,
        avgHumidity: avgHumidity / totalDays,
        avgSunhours: avgSunhours / totalDays,
        
    };
};