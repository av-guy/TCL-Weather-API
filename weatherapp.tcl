package require Tk
source "C:\\Users\\Jonathan Chaidez\\Documents\\TCL\\OpenWeatherAPI\\weatherapi.tcl";

proc myCallback {value params} {
    puts $value;
    puts $params;
}

OpenWeatherAPI create openWeatherAPI $env(OPEN_WEATHER_API_KEY) $env(ZIP_CODE_API_KEY);

openWeatherAPI put 93306;
openWeatherAPI subscribe myCallback [dict create ZipCode 93306 Parameter Temp];
openWeatherAPI subscribe myCallback [dict create ZipCode 93306 Parameter TempMax];

openWeatherAPI sync [dict create ZipCode 93306];

