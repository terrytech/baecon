agent.on("getWlans", function(arg) {
    getWlans(); 
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
            server.log("observed baecon2");
            b2 = hotspot.rssi;
            } else if ("pubnub-ac" in hotspot.ssid) {
            //server.log("Found the non-baecon controller"); 
            string = format("%s of ssid %s is operating on channel %u with signal strength %f ", hotspot.bssid, hotspot.ssid, hotspot.channel, hotspot.rssi);
            //server.log(string);
            } else {
                //server.log(format("non-beacon, non-control ssid %s", hotspot.ssid));
            }
    }
    agent.send("baecon", [b1, b2]);
}
