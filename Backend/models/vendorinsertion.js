import mongoose from "mongoose";
import { SolarInstallationCompany } from "./vendors.js";

const dbUrl = 'mongodb+srv://swatikavatkar:BPNURX3eVcQeW6qn@solaro.p1ciawy.mongodb.net/?retryWrites=true&w=majority&appName=SolarO';


async function main() {
    try {
        await mongoose.connect(dbUrl);
        console.log('Connected to MongoDB');

        const solarCompanies = [
            {
                name: "Freyr Energy",
                state: "Telangana",
                city: "Hyderabad",
                contact_number: "+91 9000828333",
                email: "sales@freyrenergy.com",
                website: "https://freyrenergy.com/",
                min_installation_cost: 50000,
                imageUrl: "https://freyrenergy.com/wp-content/uploads/2024/05/freyr-energy.png",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Tata Power Solar", "Loom Solar", "Waaree Energies"]
              },
              {
                name: "SolarSquare",
                state: "Maharashtra",
                city: "Mumbai City",
                contact_number: "+91 91364 57555",
                email: "info@solarsquare.in",
                website: "https://www.solarsquare.in/",
                min_installation_cost: 45000,
                imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ2rP2rpzHaGVMqgjZvGiLuzn9jTxvUz2CAUA&s",
                services: ["Residential", "Commercial"],
                supported_brands: ["Adani Solar", "Vikram Solar", "Waaree Energies"]
              },
              {
                name: "Visol India",
                state: "Maharashtra",
                city: "Mumbai City",
                contact_number: "+91 22 4971 4971",
                email: "contact@visolindia.com",
                website: "https://visolindia.com/",
                min_installation_cost: 48000,
                imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQnoPDs1M8rHk9zgIwS4fiFrrsP6NhDD2v7uA&s",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Loom Solar", "Tata Power Solar", "Waaree Energies"]
              },
              {
                name: "Orb Energy",
                state: "Karnataka",
                city: "Bengaluru",
                contact_number: "+91 80 4166 5000",
                email: "info@orbenergy.com",
                website: "https://www.orbenergy.com/",
                min_installation_cost: 47000,
                imageUrl: "https://upload.wikimedia.org/wikipedia/en/2/26/Logo_of_OrbEnergy.png",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Vikram Solar", "Adani Solar", "Waaree Energies"]
              },
              {
                name: "S&S Energy Systems",
                state: "Uttarakhand",
                city: "Dehradun",
                contact_number: "+91 124 424 6037",
                email: "sales@snsenergy.in",
                website: "https://snsenergy.in",
                min_installation_cost: 46000,
                imageUrl: "https://mma.prnewswire.com/media/2491395/Sunsure_Energy.jpg?p=facebook",
                services: ["Commercial", "Industrial"],
                supported_brands: ["Tata Power Solar", "Adani Solar", "Vikram Solar"]
              },

              {
                name: "Aasna Urza India Private Limited",
                state: "Uttarakhand",
                city: "Dehradun",
                contact_number: "+91 40 2355 3096",
                email: "urzasol@gmail.com",
                website: "https://urzaindia.in",
                min_installation_cost: 49000,
                imageUrl: "https://media.licdn.com/dms/image/v2/C4E0BAQEFJKsAF5HIng/company-logo_200_200/company-logo_200_200/0/1651743975602/fourth_partner_energy_private_limited_logo?e=2147483647&v=beta&t=uLbmzITTns9C39BY-aiN6tQaucQ-9gDa2CPocm2waeo",
                services: ["Commercial", "Industrial"],
                supported_brands: ["Waaree Energies", "Vikram Solar", "Adani Solar"]
              },
              {
                name: "CleanMax Solar",
                state: "Maharashtra",
                city: "Mumbai City",
                contact_number: "+91 22 6605 0500",
                email: "info@cleanmax.com",
                website: "https://www.cleanmax.com/",
                min_installation_cost: 50000,
                imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcROuo5ojT3g6j73UM-DgihCs2UYKfigZi35Bw&s",
                services: ["Commercial", "Industrial"],
                supported_brands: ["Tata Power Solar", "Adani Solar", "Vikram Solar"]
              },
              {
                name: "Raysteeds Energy Private Limited",
                state: "Uttarakhand",
                city: "Dehradun",
                contact_number: "+91 124 454 6200",
                email: "info@raysteedsenergy.com",
                website: "	https://www.raysteedsenergy.com",
                min_installation_cost: 52000,
                imageUrl: "https://www.energetica-india.net/images/noticias/JDQYOfEOBRwFTOG4clu0CGKKD8NtvMj5QzRfUWuVofb8ti1LIkKKqVV.jpg",
                services: ["Commercial", "Industrial"],
                supported_brands: ["Waaree Energies", "Vikram Solar", "Adani Solar"]
              },
              {
                name: "Mahindra Susten",
                state: "Maharashtra",
                city: "Mumbai",
                contact_number: "+91 22 6177 2900",
                email: "susten@mahindra.com",
                website: "https://www.mahindrasusten.com/",
                min_installation_cost: 53000,
                imageUrl: "https://www.eprmagazine.com/wp-content/uploads/2018/10/pg-8-Mahindra-Susten.jpg",
                services: ["Commercial", "Industrial"],
                supported_brands: ["Tata Power Solar", "Adani Solar", "Vikram Solar"]
              },
              {
                name: "Jakson Group",
                state: "Uttar Pradesh",
                city: "Noida",
                contact_number: "+91 120 430 2600",
                email: "info@jakson.com",
                website: "https://www.jakson.com/",
                min_installation_cost: 54000,
                imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTchqKufRhUf2mYdm-MJYZXCllZ9qKBpm26Xw&s",
                services: ["Commercial", "Industrial"],
                supported_brands: ["Waaree Energies", "Vikram Solar", "Adani Solar"]
              },
              {
                name: "Loom Solar",
                state: "Haryana",
                city: "Faridabad",
                contact_number: "+91 87540 63555",
                email: "sales@loomsolar.com",
                website: "https://www.loomsolar.com/",
                min_installation_cost: 55000,
                imageUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQZXHy89xeGFYpcYsB-68piN95gQEG453YLFA&s",
                services: ["Residential", "Commercial"],
                supported_brands: ["Tata Power Solar", "Adani Solar", "Waaree Energies"]
              },
            {
                name: "IBC SOLAR",
                state: "Rajasthan",
                city: "Jaipur",
                contact_number: "+91 141 298 0446",
                email: "info@ibcsolar.in",
                website: "https://www.ibcsolar.in/",
                min_installation_cost: 56000,
                image_url: "https://www.ibc-solar.com/fileadmin/_processed_/c/7/csm_IBC_SOLAR_Logo_77637993a8.png",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Tata Power Solar", "Waaree Energies", "Adani Solar"]
            },
            {
                name: "SOLARSHAMPS ENGINEERS & CONSULTANTS",
                state: "Himachal Pradesh",
                city: "Parwanoo",
                contact_number: "+91 40 2720 2803",
                email: "solarshamps@gmail.com",
                website: "https://solarshamps.com",
                min_installation_cost: 50000,
                image_url: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSwO8aCUB-nMnwCVqVuxkUDQ_ik2ADmSRlPWA&s",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Vikram Solar", "Waaree Energies", "Loom Solar"]
            },
            {
                name: "BSG Solar Eco Energy Private Limited",
                state: "Himachal Pradesh",
                city: "Sujanpur",
                contact_number: "+91 90070 00792",
                email: "bsgsolarpower@gmail.com",
                website: "https://bsgsolar.in/",
                min_installation_cost: 30000,
                image_url: "https://media.licdn.com/dms/image/v2/C560BAQHj7210i5N8wQ/company-logo_200_200/company-logo_200_200/0/1631391260320?e=2147483647&v=beta&t=hdpiV61lLC5N2MNMzQT_QOUzEQw9RGY9foObho7u0vA",
                services: ["Residential", "Commercial"],
                supported_brands: ["Adani Solar", "Vikram Solar", "Tata Power Solar"]
            },
            {
                name: "Hydel Consultants Private Limited",
                state: "Himachal Pradesh",
                city: "Kangra",
                contact_number: "+91 97234 97345",
                email: "HydelConsultants@gmail.com",
                website: "https://solartrade.in/installers/hydel-consultants-pvt-ltd",
                min_installation_cost: 48000,
                image_url: "https://greenonenergy.in/wp-content/uploads/2022/03/cropped-GREENON-ICONS.png",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Waaree Energies", "Vikram Solar", "Loom Solar"]
            },
            {
                name: "Saurmandal Solar",
                state:"Maharashtra",
                district:"Ratnagiri",
                email:"appleteamcook@gmail.com",
                contact_number:"07947120005",
                website:"https://www.saurmandalsolar.com/",
                min_installation_cost:40000,
                image_url:"https://content.jdmagicbox.com/ratnagiri/r1/9999p2352.2352.190803134855.n8r1/logo/17533a0b3de5899f9ffde00b10e493d8-s.jpg",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Waaree Energies", "Vikram Solar", "Loom Solar"]
            },
            {
                name: "Jadhav Enterprises",
                state:"Maharashtra",
                district:"Ratnagiri",
                email:"appleteamcook@gmail.com",
                contact_number:"07058185666",
                website:"http://www.jadhaventerprises.co.in/",
                min_installation_cost:50000,
                image_url:"https://image1.jdomni.in/storeLogo/21052020/C3/B4/4C/B05C944FD6ADD87ADE9FA03FC3_1590041667140.png?output-format=webp",
                services: ["Residential", "Commercial", "Industrial"],
                supported_brands: ["Waaree Energies", "Vikram Solar", "Loom Solar"]
            }
        ];

        await SolarInstallationCompany.insertMany(solarCompanies);
        console.log('Data successfully uploaded!');

        mongoose.connection.close();
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
}

main();
