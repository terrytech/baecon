led <- hardware.pin2;
led.configure(PWM_OUT, 1.0/400.0, 0.0);


ledState <- 0.0;
ledChange <- 0.05;

agent.on("getWlans", function(arg) {
    getWlans(); 
});

agent.on("pulse", function(arg) {
    pulse();
});

function getWlans() {
    local wlans = imp.scanwifinetworks();
    local b1 = "0";
    local b2 = "0";
    foreach (hotspot in wlans)
    {
        if(hotspot.ssid  == "baecon") {
            server.log("observed baecon" + hotspot.rssi);
            b1 = hotspot.rssi;
            }  else if(hotspot.ssid  == "baecon2") {
            server.log("observed baecon2" + hotspot.rssi);
            b2 = hotspot.rssi;
            } else if ("pubnub-ac" in hotspot.ssid) {
            //server.log("Found the non-baecon controller"); 
            //string = format("%s of ssid %s is operating on channel %u with signal strength %f ", hotspot.bssid, hotspot.ssid, hotspot.channel, hotspot.rssi);
            //server.log(string);
            } else {
                //server.log(format("non-beacon, non-control ssid %s", hotspot.ssid));
            }
    }
    agent.send("baecon", [b1, b2]);
}

function pulse() {
    // write value to pin
        led.write(ledState);
        
        // change the value
        ledState = ledState + ledChange;
        
        // Check if we're out of bounds
        if (ledState >= 1.0 || ledState <= 0.0) {
        // flip ledChange if we are
                ledChange = ledChange * -1.0;
        }
        
        // schedule the loop to run again:
        imp.wakeup(0.05, pulse);
}

