agent.on("getWlans", function(arg) {
    getWlans(); 
});

function getWlans() {
    local wlans = imp.scanwifinetworks();
    local string = "";
    foreach (hotspot in wlans)
    {
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
                server.log(format("non-beacon, non-control ssid %s", hotspot.ssid));
            }
    }   
}
