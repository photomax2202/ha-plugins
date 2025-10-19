#!/command/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Community Add-on: Solarprognose.de to MQTT
#
# Solarprognose.de add-on for Home Assistant.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Global Variabeles
# ------------------------------------------------------------------------------
forecastData=""
forecastStartTimeDaily=0
forecastStartTimeHourly=0
publishedSensorsFile="/data/publishedSensors.txt"
debugMode=0

# ------------------------------------------------------------------------------
# TestFunction offline usage
# ------------------------------------------------------------------------------
get_sampleData(){
    local type
    type=$(bashio::config 'type')
    
    if [[ "$type" == "daily" ]]; then
        echo '{"preferredNextApiRequestAt":{"secondOfHour":1252,"epochTimeUtc":1760775652},"status":0,"iLastPredictionGenerationEpochTime":1760773541,"weather_source_text":"Kurzfristig (3 Tage): Powered by <a href=\"https://www.weatherapi.com/\" title=\"Free Weather API\">WeatherAPI.com</a> und Langfristig (10 Tage): Powered by <a href=\"https://www.visualcrossing.com/weather-data\" target=\"_blank\">Visual Crossing Weather</a>","datalinename":"Germany > Niederwiesa","data":{"20251018":15.314,"20251019":13.659,"20251020":10.827,"20251021":11.744,"20251022":6.723}}'
    elif [[ "$type" == "hourly" ]]; then
        echo '{"preferredNextApiRequestAt":{"secondOfHour":1252,"epochTimeUtc":1760775652},"status":0,"iLastPredictionGenerationEpochTime":1760773541,"weather_source_text":"Kurzfristig (3 Tage): Powered by <a href=\"https://www.weatherapi.com/\" title=\"Free Weather API\">WeatherAPI.com</a> und Langfristig (10 Tage): Powered by <a href=\"https://www.visualcrossing.com/weather-data\" target=\"_blank\">Visual Crossing Weather</a>","datalinename":"Germany > Niederwiesa","data":{"1760763600":[0,0],"1760767200":[0.316,0.316],"1760770800":[0.714,1.03],"1760774400":[1.98,3.01],"1760778000":[1.646,4.656],"1760781600":[3.439,8.095],"1760785200":[2.659,10.754],"1760788800":[2.209,12.963],"1760792400":[1.622,14.585],"1760796000":[0.531,15.116],"1760799600":[0.198,15.314],"1760803200":[0,15.314],"1760850000":[0,0],"1760853600":[0.104,0.104],"1760857200":[0.307,0.411],"1760860800":[3.308,3.719],"1760864400":[3.039,6.758],"1760868000":[2.249,9.007],"1760871600":[2.109,11.116],"1760875200":[1.323,12.439],"1760878800":[0.74,13.179],"1760882400":[0.297,13.476],"1760886000":[0.183,13.659],"1760889600":[0,13.659],"1760932800":[0,0],"1760936400":[0.033,0.033],"1760940000":[0.525,0.558],"1760943600":[1.065,1.623],"1760947200":[2.168,3.791],"1760950800":[1.68,5.471],"1760954400":[0.981,6.452],"1760958000":[1.697,8.149],"1760961600":[1.199,9.348],"1760965200":[0.93,10.278],"1760968800":[0.359,10.637],"1760972400":[0.19,10.827],"1760976000":[0,10.827],"1761019200":[0,0],"1761022800":[0.006,0.006],"1761026400":[0.126,0.132],"1761030000":[0.548,0.68],"1761033600":[1.806,2.486],"1761037200":[2.403,4.889],"1761040800":[2.158,7.047],"1761044400":[1.789,8.836],"1761048000":[1.38,10.216],"1761051600":[0.996,11.212],"1761055200":[0.349,11.561],"1761058800":[0.183,11.744],"1761062400":[0,11.744],"1761105600":[0,0],"1761109200":[0.005,0.005],"1761112800":[0.19,0.195],"1761116400":[0.397,0.592],"1761120000":[0.901,1.493],"1761123600":[0.909,2.402],"1761127200":[0.983,3.385],"1761130800":[0.937,4.322],"1761134400":[0.867,5.189],"1761138000":[0.949,6.138],"1761141600":[0.395,6.533],"1761145200":[0.19,6.723],"1761148800":[0,6.723]}}'
    fi
}

# ------------------------------------------------------------------------------
# Function to Set start values of variables for forcast 
# ------------------------------------------------------------------------------
set_forcastStartInit(){
    bashio::log.trace "${FUNCNAME[0]}"

    # Aktuelles Datum im Format JJJJMMDD
    forecastStartTimeDaily=$(date +%Y%m%d)
    # Aktuelles Datum um 00:00 Uhr
    forecastStartTimeHourly=$(date -d "$(date +%Y-%m-%d) 00:00:00" +%s)

    bashio::log.debug "forecastStartTimeDaily: ${forecastStartTimeDaily}"
    bashio::log.debug "forecastStartTimeHourly: ${forecastStartTimeHourly}"
}

# ------------------------------------------------------------------------------
# Function to calc new date from start values
#
# Arguments
#   Offset
# ------------------------------------------------------------------------------
get_forecastStartRelative() {
    bashio::log.trace "${FUNCNAME[0]}"

    local type
    local Offset=$1
    local BaseValue
    local Result

    type=$(bashio::config 'type')

    if [[ "$type" == "daily" ]]; then
        BaseValue=$forecastStartTimeDaily
    elif [[ "$type" == "hourly" ]]; then
        BaseValue=$forecastStartTimeHourly
        Offset=$((Offset * 3600))
    fi
    Result=$((BaseValue + Offset))
    bashio::log.debug "Time-Calculation: ${BaseValue} + ${Offset} = ${Result}"
    echo $Result
}

# ------------------------------------------------------------------------------
# Build Request URL for Solarprognose.de
#
# Arguments:
#   None
# Returns:
#   String with the url
# ------------------------------------------------------------------------------
get_requestUrl() {
    
    bashio::log.trace "${FUNCNAME[0]}"

    declare url
    declare requestUrl
    declare accesstoken
    declare project
    declare item
    declare id
    declare token
    declare type
    declare algorithm
    declare day
    declare start_day
    declare end_day

    url="https://www.solarprognose.de/web/solarprediction/api/v1?"
    accesstoken=$(bashio::config 'accesstoken')
    project=$(bashio::config 'project')
    item=$(bashio::config 'item')
    id=$(bashio::config 'id')
    token=$(bashio::config 'token')
    type=$(bashio::config 'type')
    algorithm=$(bashio::config 'algorithm')
    day=$(bashio::config 'day')
    start_day=$(bashio::config 'start_day')
    end_day=$(bashio::config 'end_day')

    bashio::log.debug "URL: ${url}"
    bashio::log.debug "Access-Token: ${accesstoken:="<<No Accesstoken configured>>"}"
    bashio::log.debug "Project: ${project:="<<No Project configured>>"}"
    bashio::log.debug "ITEM: ${item:="<<No Item configured>>"}"
    bashio::log.debug "ID: ${id:="<<No Id configured>>"}"
    bashio::log.debug "TOKEN: ${token:="<<No Token configured>>"}"
    bashio::log.debug "Type: ${type:="<<No Type configured>>"}"
    bashio::log.debug "Algorithm: ${algorithm:="<<No Algorithm configured>>"}"
    bashio::log.debug "DAY: ${day:="<<No Day configured>>"}"
    bashio::log.debug "START_DAY: ${start_day:="<<No Start Day configured>>"}"
    bashio::log.debug "END_DAY: ${end_day:="<<No End Day configured>>"}"

    ## Build request url
    ## Basic url and minimal properties
    requestUrl="${url}access-token=${accesstoken}&project=${project}"

    ## Options for Item/Id/Token
    if [ -n "$item" ] && [ "$item" != "null" ] && [ -n "$id" ] && [ "$id" != "null" ];
    then
        requestUrl="${requestUrl}&item=${item}&id=${id}"
    elif [ -n "$item" ] && [ "$item" != "null" ] && [ -n "$token" ] && [ "$token" != "null" ];
    then
        requestUrl="${requestUrl}&item=${item}&token=${token}"
    fi

    ## Regular minimal url
    requestUrl="${requestUrl}&type=${type}&algorithm=${algorithm}&_format=json"

    ## Options for Day parameters
    if [ -n "$day" ] && [ "$day" != "null" ]
    then
        requestUrl="${requestUrl}&day=${day}"
    fi

    if [ -n "$start_day" ] && [ "$start_day" != "null" ];
    then
        requestUrl="${requestUrl}&start_day=${start_day}"
    fi

    if [ -n "$end_day" ] && [ "$end_day" != "null" ];
    then
        requestUrl="${requestUrl}&end_day=${end_day}"
    fi

    bashio::log.debug "Request-URL: ${requestUrl}"
    echo "${requestUrl}"

}

# ------------------------------------------------------------------------------
# Request data from solarprognose.de
#
# Arguments:
#   None
# Returns:
#   String with the data
# ------------------------------------------------------------------------------
get_forecastData() {

    bashio::log.trace "${FUNCNAME[0]}"

    if [[ "$debugMode" == "1" ]]; then
        forecastData=$(get_sampleData)
    else
        forecastData=$(wget -q -O - $(get_requestUrl))
    fi
    set_forcastStartInit

    bashio::log.debug "Requested Data: ${forecastData}"

    echo "${forecastData}"
}

# ------------------------------------------------------------------------------
# 
# ------------------------------------------------------------------------------
get_actualSecondOfHour() {
    # Aktuelle Minute und Sekunde auslesen
    local minute=$(date +%M)
    local sekunde=$(date +%S)

    # Sekunden seit Stundenbeginn berechnen
    local seconds_of_hour=$((10#$minute * 60 + 10#$sekunde))
    bashio::log.debug "Actual Seconds of Hour: ${seconds_of_hour}"
    echo $seconds_of_hour
}

# ------------------------------------------------------------------------------
# Calculate Sleeptime until Request
#
# Returns:
#   Sleep Time for next Request
# ------------------------------------------------------------------------------
get_sleepTimeForRequest() {

    bashio::log.trace "${FUNCNAME[0]}"
    bashio::log.info "Calculate Sleeptime"

    local eingabe=$(get_secondsOfHour)
    bashio::log.debug "Request Seconds of Hour: ${eingabe}"

    # Berechnung: (3600 + eingabe - seconds_of_hour)
    local ergebnis=$((3600 + eingabe - $(get_actualSecondOfHour)))

    # Wenn Ergebnis > 3600, dann nochmal 3600 abziehen
    if [ "${ergebnis}" -gt 3600 ]; then
        ergebnis=$((ergebnis - 3600))
    fi

    # Rückgabe über echo
    bashio::log.debug "Calculated Sleep Time: ${ergebnis}"
    echo "${ergebnis}"

}

# ------------------------------------------------------------------------------
# Extract Value from JSON Object
#
# Arguments:
#   JSON Object
#   JSON Key
# Returns:
#   JSON Value
# ------------------------------------------------------------------------------
get_valueFromJson() {

    bashio::log.trace "${FUNCNAME[0]}"
    local value

    local object=$1
    bashio::log.debug "JSON Object: ${object}"
    local key=$2
    bashio::log.debug "JSON Key: ${key}"

    value=$(echo "${object}" | jq -r ".${key}")
    bashio::log.debug "JSON Value: ${value}"
    echo ${value}
}

# ------------------------------------------------------------------------------
# 
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Publishing Sensor for MQTT device
#
# Argumente:
#   Sensor Name
# ------------------------------------------------------------------------------
mqtt_publishSensorDevice(){
    local SensorName=$1
    bashio::log.debug "mqtt_clearSensorDevice - Input 1 SensorName: ${SensorName}"
    local DEVICE_NAME=$(bashio::addon.name)
    local TOPIC_PREFIX="homeassistant/sensor/$(bashio::config 'MQTT_TOPIC')/${SensorName}"

    local payload=$(cat <<EOF
{
  "name": "${SensorName}",
  "state_topic": "${TOPIC_PREFIX}/state",
  "unit_of_measurement": "kWh",
  "device_class": "energy",
  "unique_id": "${DEVICE_NAME}_${SensorName}",
  "device": {
    "identifiers": ["${DEVICE_NAME}"],
    "name": "${DEVICE_NAME}"
  }
}
EOF
)

bashio::log.debug "Publish MQTT Sensor: ${SensorName} - Device: ${DEVICE_NAME} - Topic: ${TOPIC_PREFIX}/config"

echo "$SensorName" >> "$publishedSensorsFile"

# Discovery-Payload senden
mosquitto_pub   -h "$(bashio::config 'MQTT_HOST')" \
                -u "$(bashio::config 'MQTT_USER')" \
                -P "$(bashio::config 'MQTT_PASSWORD')" \
                -t "${TOPIC_PREFIX}/config" \
                -m "$payload"
}

# ------------------------------------------------------------------------------
# Publish Value to MQTT Service
#
# Arguments:
#   Sensor Name
#   Value
# ------------------------------------------------------------------------------
mqtt_publishSensorValue() {
    local SensorName=$1
    local SensorValue=$2
    bashio::log.debug "mqtt_publishSensorValue - Input 1 SensorName: ${SensorName} - Input 2 SensorValue: ${SensorValue}"
    local TOPIC_PREFIX="homeassistant/sensor/$(bashio::config 'MQTT_TOPIC')/${SensorName}"

    bashio::log.debug "Push MQTT Sensor: ${SensorName} - Value: ${SensorValue} - Topic: ${TOPIC_PREFIX}/state"

    mosquitto_pub   -h "$(bashio::config 'MQTT_HOST')" \
                    -u "$(bashio::config 'MQTT_USER')" \
                    -P "$(bashio::config 'MQTT_PASSWORD')" \
                    -t "${TOPIC_PREFIX}/state" \
                    -m "${SensorValue}"
}


# ------------------------------------------------------------------------------
# Clear MQTT device
# ------------------------------------------------------------------------------
mqtt_clearSensorDevice() {
    local SensorName=$1
    bashio::log.debug "mqtt_clearSensorDevice - Input 1 SensorName: ${SensorName}"
    local TOPIC_PREFIX="homeassistant/sensor/$(bashio::config 'MQTT_TOPIC')/${SensorName}"

    bashio::log.debug "Clear MQTT Sensor: ${SensorName} - Topic: ${TOPIC_PREFIX}"

    mosquitto_pub   -h "$(bashio::config 'MQTT_HOST')" \
                    -u "$(bashio::config 'MQTT_USER')" \
                    -P "$(bashio::config 'MQTT_PASSWORD')" \
                    -t "${TOPIC_PREFIX}/config" \
                    -m ""
}

# ------------------------------------------------------------------------------
# Clean MQTT device by inactivity
# ------------------------------------------------------------------------------
mqtt_cleanup_sensors() {
    if [[ -s "$publishedSensorsFile" ]]; then
        bashio::log.info "Cleanup MQTT Sensors"
        bashio::log.debug "from ${publishedSensorsFile}"
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Überspringe leere Zeilen
            [[ -z "$line" ]] && continue
            # Sensorname in Line
            bashio::log.debug "Read Line ${line}"
            mqtt_clearSensorDevice "$line"
        done < $publishedSensorsFile

        if [[ -f "$publishedSensorsFile" ]]; then
            rm "$publishedSensorsFile"
            bashio::log.info "Datei '$publishedSensorsFile' wurde gelöscht."
        else
            bashio::log.warning "Datei '$publishedSensorsFile' existiert nicht."
        fi
    else
        bashio::log.info "No Cleanup for MQTT Sensors necessary"
    fi
}


# ------------------------------------------------------------------------------
# get secondsOfHour from forecastData
# ------------------------------------------------------------------------------
get_secondsOfHour(){
    local preferredNextApiRequest
    local requestSecondsOfHour

    preferredNextApiRequest=$(get_valueFromJson "${forecastData}" "preferredNextApiRequestAt")
    requestSecondsOfHour=$(get_valueFromJson "${preferredNextApiRequest}" "secondOfHour")

    echo $requestSecondsOfHour
}


# ------------------------------------------------------------------------------
# wait function until next update
# ------------------------------------------------------------------------------
wait_untilNextUpdate() {
    local sleepTime
    local sleepTimeExtra
    bashio::log.info "Wait for next update in $(get_sleepTimeForRequest) Seconds with Break Time of $(bashio::config 'break_time') Hours."
    if [[ "$debugMode" == "1" ]]; then
        sleepTime="60"
    else
        sleepTime=$(get_sleepTimeForRequest)
    fi
    sleepTimeExtra=$(bashio::config 'break_time')
    sleepTimeExtra=$(( (sleepTimeExtra - 1) * 3600 ))
    sleepTime=$((sleepTime + sleepTimeExtra))


    sleep "${sleepTime}"
}


# ------------------------------------------------------------------------------
# Build names for MQTT Sensors in Daily Mode 
# ------------------------------------------------------------------------------
buildSensorNameDaily() {
    local diff=$1
    local name

    if (( diff == 0 )); then
      name="DAY0"
    elif (( diff > 0 )); then
      name="DAY${diff}"
    else
      name="DAY$((-diff))past"
    fi
    echo $name
}

# ------------------------------------------------------------------------------
# function for Publish MQTT Sensors for type daily 
# ------------------------------------------------------------------------------
sub_publishMqttSensorsDaily() {
    bashio::log.debug "Publish Sensors for daily forecast"
    
    local ForcastValues=$(get_valueFromJson "${forecastData}" "data")
    bashio::log.debug "ForcastValues: ${ForcastValues}"

    local name
    local value

    # Iteriere über alle Einträge im JSON-Container
    echo "$ForcastValues" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read -r key value; do
        # Differenz in Tagen berechnen
        local diff=$(( (10#$key - 10#$forecastStartTimeDaily) ))

        # Namen erzeugen: DAY+0, DAY+1, DAY-2 usw.
        name=$(buildSensorNameDaily "${diff}")
        
        # Ausgabe
        bashio::log.debug "ForcastValues: ${name} - ${value}"
        mqtt_publishSensorDevice "${name}"
    done
}

# ------------------------------------------------------------------------------
# function for Publish MQTT Sensors for type hourly 
# ------------------------------------------------------------------------------
sub_publishMqttSensorsHourly() {
    bashio::log.debug "Publish Sensors for hourly forecast"

    local ForcastValues=$(get_valueFromJson "${forecastData}" "data")
    bashio::log.debug "ForcastValues: ${ForcastValues}"

    local name

    echo "$ForcastValues" | jq -c 'to_entries[]' | while read -r entry; do
        local ts=$(echo "$entry" | jq -r '.key')
        local erzeugung=$(echo "$entry" | jq -r '.value[0]')
        local kumuliert=$(echo "$entry" | jq -r '.value[1]')

        # Differenz in Stunden zum Startzeitpunkt
        local stunden_diff=$(( (ts - forecastStartTimeHourly) / 3600 ))
        local tag_diff=$(( stunden_diff / 24 ))
        local stunde=$(TZ="Europe/Berlin" date -d "@$ts" +%H)

        # Namen erzeugen: DAY+0, DAY+1, DAY-2 usw.
        name=$(buildSensorNameDaily "${tag_diff}")

        # Key erzeugen
        name="${name}_H${stunde}"

        # Ausgabe
        mqtt_publishSensorDevice "${name}"        
    done
}

# ------------------------------------------------------------------------------
# function for Publish MQTT Sensors 
# ------------------------------------------------------------------------------
publishMqttSensors() {
    local type
    type=$(bashio::config 'type')
    
    bashio::log.info "Publish Sensors MQTT sensors"

    if [[ "$type" == "daily" ]]; then
        sub_publishMqttSensorsDaily
    elif [[ "$type" == "hourly" ]]; then
        sub_publishMqttSensorsHourly
    fi
}

# ------------------------------------------------------------------------------
# function for Publish MQTT Sensor Values for type daily 
# ------------------------------------------------------------------------------
sub_publishMqttSensorValuesDaily() {
    bashio::log.debug "Publish Sensor Values for daily forecast"

    local ForcastValues=$(get_valueFromJson "${forecastData}" "data")
    bashio::log.debug "ForcastValues: ${ForcastValues}"


    # Iteriere über alle Einträge im JSON-Container
    echo "$ForcastValues" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read -r key value; do
        # Differenz in Tagen berechnen
        local diff=$(( (10#$key - 10#$forecastStartTimeDaily) ))

        # Namen erzeugen: DAY+0, DAY+1, DAY-2 usw.
        name=$(buildSensorNameDaily "${diff}")

        # Ausgabe
        mqtt_publishSensorValue "${name}" "${value}"
    done
}

# ------------------------------------------------------------------------------
# function for Publish MQTT Sensor Values for type hourly 
# ------------------------------------------------------------------------------
sub_publishMqttSensorValuesHourly() {
    bashio::log.debug "Publish Sensor Values for hourly forecast"

    local ForcastValues=$(get_valueFromJson "${forecastData}" "data")
    bashio::log.debug "ForcastValues: ${ForcastValues}"

    local name

    echo "$ForcastValues" | jq -c 'to_entries[]' | while read -r entry; do
        local ts=$(echo "$entry" | jq -r '.key')
        local erzeugung=$(echo "$entry" | jq -r '.value[0]')
        local kumuliert=$(echo "$entry" | jq -r '.value[1]')

        # Differenz in Stunden zum Startzeitpunkt
        local stunden_diff=$(( (ts - forecastStartTimeHourly) / 3600 ))
        local tag_diff=$(( stunden_diff / 24 ))
        local stunde=$(( stunden_diff % 24 ))

        # Stunde mit führender Null
        printf -v hstr "%02d" "$stunde"

        # Namen erzeugen: DAY+0, DAY+1, DAY-2 usw.
        name=$(buildSensorNameDaily "${tag_diff}")

        # Key erzeugen
        name="${name}_H${hstr}"

        # Ausgabe
        mqtt_publishSensorValue "${name}" "${erzeugung}"        
    done
}

# ------------------------------------------------------------------------------
# function for Publish MQTT Sensor Values
# ------------------------------------------------------------------------------
publishMqttSensorValues() {
    local type
    type=$(bashio::config 'type')

    bashio::log.info "Publish Sensors MQTT sensor values"
    
    if [[ "$type" == "daily" ]]; then
        sub_publishMqttSensorValuesDaily
    elif [[ "$type" == "hourly" ]]; then
        sub_publishMqttSensorValuesHourly
    fi
}

main() {
    bashio::log.trace "${FUNCNAME[0]}"

    # Initial Request of forecast Data
    get_forecastData

    #Cleanup old MQTT Sensors
    mqtt_cleanup_sensors

    # Publish MQTT Sensors
    publishMqttSensors

    # Publish MQTT Sensor Values
    publishMqttSensorValues

    # Sleep until next update Cycle
    wait_untilNextUpdate

    #get_forecastStartRelative "-2"
    #get_sleepTimeForRequest


    #mqtt_publishSensorDevice "day0"
    #mqtt_publishSensorValue "day0" "170"

    #mqtt_clearSensorDevice "day0"


    while true; do
        #echo "Solarprognose.de Request Data"
        # Periodic Request of forecast Data
        get_forecastData

        # Periodic Publish MQTT Sensor Values
        publishMqttSensorValues

        # Sleep until next update Cycle
        wait_untilNextUpdate
    done
}
main "$@"
