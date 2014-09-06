led1 <- hardware.pin1;
led2 <- hardware.pin2;
led1.configure(PWM_OUT, 1.0/400.0, 0.0);
led2.configure(PWM_OUT, 1.0/400.0, 0.0);
 
ledState <- 0.0;
ledChange <- 0.05;

agent.on("reportRSSI", function(lednum) {
    //local rssi = imp.rssi();
    reportRSSI(rssi, lednum);
});

function pulse(ledVal) {
    // write value to pin
        led1.write(ledVal);
        led2.write(ledVal);
        // schedule the loop to run again:
        //imp.wakeup(0.05, pulse(ledVal));
}


function reportRSSI(rssi, lednum) 
{
    rssi = 0;
    if (rssi < -87)
    {
        server.log("Signal Strength: " + rssi + "dBm (0 bars)");
    }
    else if (rssi < -82) 
    {
        server.log("Signal Strength: " + rssi + "dBm (1 bar)");
        pulse(0.2);
    }
    else if (rssi < -77) 
    {
        server.log("Signal Strength: " + rssi + "dBm (2 bars)");
        pulse(0.4);
    }
    else if (rssi < -72) 
    {
        server.log("Signal Strength: " + rssi + "dBm (3 bars)");
        pulse(0.6);
    }
    else if (rssi < -67) 
    {
        server.log("Signal Strength: " + rssi + "dBm (4 bars)");
        pulse(0.8);
    }
    else 
    {
        server.log("Signal Strength: " + rssi + "dBm (5 bars)");
        pulse(1.0);
    }
    getWlans();
}


function getWlans() {
    local wlans = imp.scanwifinetworks();
    local string = "";
    
    foreach (hotspot in wlans)
    {
        //server.log("Looking at wifi " + hotspot.ssid);
        if(hotspot.ssid  == "baecon") {
            server.log("Found baecon");
            string = format("%s of ssid %s is operating on channel %u with signal strength %f ", hotspot.bssid, hotspot.ssid, hotspot.channel, hotspot.rssi);
            server.log(string);
            }  else if(hotspot.ssid  == "baecon2") {
            server.log("Found baecon2");
            string = format("%s of ssid %s is operating on channel %u with signal strength %f ", hotspot.bssid, hotspot.ssid, hotspot.channel, hotspot.rssi);
            server.log(string);
            } else if ("pubnub-ac" in hotspot.ssid) {
            //server.log("Found the non-baecon controller");
            string = format("%s of ssid %s is operating on channel %u with signal strength %f ", hotspot.bssid, hotspot.ssid, hotspot.channel, hotspot.rssi);
            //server.log(string);
            } else {
                //server.log(format("non-beacon, non-control ssid %s", hotspot.ssid));
            }
    }   
}
