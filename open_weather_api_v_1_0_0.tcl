package require http
package require tls
package require json


::http::register https 443 ::tls::socket;


oo::class create ZipCodeAPI {
    constructor {zipCodeAPIKey} {
        my variable apiKey;
        my variable baseURL;
        
        set apiKey $zipCodeAPIKey;
        set baseURL "https://www.zipcodeapi.com/rest";
    }
    
    method getLatLng {zipCode} {
        my variable apiKey;
        my variable baseURL;
        
        set endpoint "${baseURL}/${apiKey}/info.json/${zipCode}/degrees";
        set token [::http::geturl $endpoint];
        set json [::http::data $token];
        set parsed [::json::json2dict $json];
        set lat [dict get $parsed lat];
        set lng [dict get $parsed lng];

        return [dict create lat $lat lng $lng];
    }
}


oo::class create OpenWeatherAPI {
    constructor {openWeatherAPIKey zipCodeAPIKey} {
        my variable apiKey;
        my variable baseURL;
        my variable zipCodeAPI;
        my variable zipCodeData;
        my variable zipCodeSubs;
        
        ZipCodeAPI create zipAPI $zipCodeAPIKey;
        
        set zipCodeAPI zipAPI;
        set zipCodeSubs [dict create];
        set zipCodeData [dict create];
        set apiKey $openWeatherAPIKey;
        set baseURL "https://api.openweathermap.org/data/2.5";
    }
    
    method getHourForecast {zipCode} {
        my variable zipCodeAPI;
        my variable baseURL;
        my variable apiKey;
        
        set coords [$zipCodeAPI getLatLng $zipCode];
        set lat [dict get $coords lat];
        set lng [dict get $coords lng];
        set endpoint "${baseURL}/weather?lat=${lat}&lon=${lng}&appid=${apiKey}";
        
        set token [::http::geturl $endpoint];
        set json [::http::data $token];
        set parsed [::json::json2dict $json];
        
        my parseForecastData $parsed $zipCode;
    }
    
    method parseForecastData {jsonPayload zipCode} {
        my variable zipCodeData;
        
        set weather [lindex [dict get $jsonPayload weather] 0];
        set icon [dict get $weather icon];
        set dataDict [my createParamatersDict [dict get $jsonPayload main]];

        if {[dict exists $zipCodeData $zipCode]} {
            dict replace $zipCodeData $zipCode $dataDict;
        } else {
            dict append zipCodeData $zipCode $dataDict;
        }
    }
    
    method removeUnderscore {value} {
        set replaced "";
        set capitalize 0;
        foreach {char} [split $value ""] {
            if {$char != "_"} {
                if {$capitalize} {
                    lappend replaced [string toupper $char];
                    set capitalize 0;
                } else {
                    lappend replaced $char;
                }
            } else {
                set capitalize 1;
            }
        }
        return [string toupper [join $replaced ""] 0 0];
    }
    
    method createParamatersDict {mainPayload} {
        set dataDict [dict create];
        dict for {keyVar valueVar} $mainPayload {
            set modifiedKeyValue [my removeUnderscore $keyVar];
            dict append dataDict $modifiedKeyValue $valueVar;
        }
        return $dataDict;
    }
    
    method getZipCodeData {} {
        my variable zipCodeData;
        return $zipCodeData;
    }
    
    method put {value {params {}}} {
        my getHourForecast $value;
    }
    
    method status {{params {}}} {
        my variable zipCodeData;
        
        set code [catch {

            set zipCode [dict get $params ZipCode];
            set parameterValue [dict get $params Parameter];
            set weatherData [dict get $zipCodeData $zipCode];
            
            if {[dict exists $weatherData $parameterValue]} {
                set result [dict get $weatherData $parameterValue];
            } else {
                set result "No such value: ${parameterValue}";
            }
            
        } result];
        
        if {$code == 1} {
            puts "Error: ${result}";
            return;
        } else {
            return $result;
        }   
    }
    
    method subscribe {callback {params {}}} {
        set code [catch {
            my variable zipCodeSubs;
            
            set zipCode [dict get $params ZipCode];
            set paramValue [dict get $params Parameter];
            
            if {![dict exists $zipCodeSubs $zipCode]} {
                dict append zipCodeSubs $zipCode [dict create];
            }
            
            dict set zipCodeSubs $zipCode $paramValue $callback;
        } result]
        
        if {$code == 1} {
            puts "Error: ${result}";
            return;
        }
    }
    
    method sync {params} {
        set code [catch {
            my variable zipCodeData;
            my variable zipCodeSubs;
            
            set zipCode [dict get $params ZipCode];
            set currentSubs [dict get $zipCodeSubs $zipCode];
            
            foreach {key value} [dict get $zipCodeData $zipCode] {
                if {[dict exists $currentSubs $key]} {
                    [dict get $currentSubs $key] $value [dict create ZipCode $zipCode Parameter $key];
                }
            }
                
            
        } result]
        
        if {$code == 1} {
            puts "Error: ${result}";
            return;
        }
    }
}

proc myCallback {val params} {
    puts $val;
    puts $params;
}

OpenWeatherAPI create openWeatherAPI $env(OPEN_WEATHER_API_KEY) $env(ZIP_CODE_API_KEY);

openWeatherAPI put 93306;
openWeatherAPI subscribe myCallback [dict create ZipCode 93306 Parameter Temp];
openWeatherAPI subscribe myCallback [dict create ZipCode 93306 Parameter TempMax];

openWeatherAPI sync [dict create ZipCode 93306];