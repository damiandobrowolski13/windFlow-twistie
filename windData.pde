boolean fetchWeatherData() {
  String url = "https://api.open-meteo.com/v1/forecast?latitude=42.051438&longitude=-87.674683&current=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,rain,showers,snowfall,cloud_cover&timezone=America%2FChicago&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch";
  JSONObject weatherData = loadJSONObject(url);
  
  if (weatherData != null){
    JSONObject currentWeather = weatherData.getJSONObject("current");
    
    temp = currentWeather.getFloat("temperature_2m");
    appTemp = currentWeather.getFloat("apparent_temperature");
    windSpeed = currentWeather.getFloat("wind_speed_10m");
    windGusts = currentWeather.getFloat("wind_gusts_10m");
    windDirFrom = currentWeather.getFloat("wind_direction_10m");
    // Core direction math
    windDirTo = (windDirFrom + 180) % 360;
    windDirToCard = degreesToCard(windDirTo);
    
    if (windDirTo >= 0 && windDirTo < 90) {         
      legendTargetCorner = 2; // Bottom-Left 
    } else if (windDirTo >= 90 && windDirTo < 180) { 
      legendTargetCorner = 3; // Top-Left
    } else if (windDirTo >= 180 && windDirTo < 270) { 
      legendTargetCorner = 0; // Top-Right
    } else { 
      legendTargetCorner = 1; // Bottom-Right
    }
    
    relHum = currentWeather.getFloat("relative_humidity_2m");
    precip = currentWeather.getFloat("precipitation");
    rain = currentWeather.getFloat("rain");
    showers = currentWeather.getFloat("showers");
    snow = currentWeather.getFloat("snowfall");
    clouds = currentWeather.getFloat("cloud_cover");
    
    // Apply special Pi rotation + the 180 degree alignment flip
    angleOff = radians(windDirTo + procRot + 180); 

    if (dvd != null) {
      float updatedLogoSpeed = map(windSpeed, 0, 30, 0.5, 5);
      dvd.updateSpeed(updatedLogoSpeed);
    }
    
    return true;
  } else {
    println("Error fetching weather data.");
    return false;
  }
}
