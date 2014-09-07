local b1 = [];
local b2 = [];
local readings = 0;
local report_thresh = 8;  // need at least this many to report
local L = 30.0;  // hard code length of room

http.onrequest(function(req, res) {
   device.send("getWlans", null);
   res.send(200, "OK");
})

device.on("baecon", function(arg) {
    b1.push(arg[0]);
    b2.push(arg[1]);
    update();
    imp.wakeup(0.1, function() {
        device.send("getWlans", null);
    });
});

function update() {
    if (readings >= report_thresh) {  // ready to publish, check data quality
        //server.log("calculating and publishing");
        publish();
        readings = 0;
        b1 = [];
        b2 = [];
        device.send("pulse", null);
    } else {
        //server.log("not yet publishing");
        readings++;
    }
}

function publish() {   // get last three non-zero elements and average them
    // use -50 as a dummy value in place of 0s
    local b1_avg = 0.0;
    local b2_avg = 0.0;
    for (local i=0; i< b1.len(); ++i)
    {
        if ((b1[i]) == "0") {
            b1_avg = b1_avg - (70.0 / b1.len());
            //server.log("0 value found for b1");
        } else {
            b1_avg = b1_avg + ( b1[i] / b1.len());   // avg contribution
            //server.log("nonzero value found for b1");
        }
    }
    for (local i=0; i<b2.len(); ++i)
    {
        if ((b2[i]) == "0") {
            b2_avg = b2_avg - (70.0 / b2.len());
            //server.log("0 value found for b2");
        } else {
            b2_avg = b2_avg + (b2[i]  / b2.len());
            //server.log("nonzero value found for b2");
        }
    }
    //server.log("done searching through b1, computed " + b1_avg);
    //server.log("done searching through b2, computed " + b2_avg);
    //server.log("b1 distance is " + distance(b1_avg, L));
    //server.log("b2 distance is " + distance(b2_avg, L));
    local results = triangulate(distance(b1_avg, L), distance(b2_avg, L), L.tofloat());
    server.log("x and y are " + results[0] + " " + results[1]);
}

function distance(rssi, L) {  // if rssi is greater
    local rssi_f = rssi.tofloat();
    if (rssi_f > -48.0) {  // too close to make a call
        return 0.0;
    } else if ((rssi_f <= -48.0) && (rssi_f > -56.0)) {
        return 0.25 * L;
    } else if ((rssi_f <= -56.0) && (rssi_f > -58.0)) {
        return 0.5 * L;
    } else if ((rssi_f <= 58.0) && (rssi_f > -68)) {
        return 0.75 * L;
    } else {
        return 1.0 * L;
    }
}

function triangulate(b1, b2, L) {
    // map raw rssi values to triangulation in discrete values
    local x = 0.0;
    local y = 0.0;
    x = (math.pow(L.tofloat(), 2.0) + math.pow(b1.tofloat(), 2.0) - math.pow(b2.tofloat(), 2.0)) / (2 * L);
    server.log("x is " + x);
    y = (L, math.sqrt((b1.tofloat() * b1.tofloat()) - (x.tofloat() * x.tofloat())));
    y = 0.0;
    local results = [];
    results.push(x);
    results.push(y);
    
    const PUBKEY = "pub-c-c0f78210-168a-429f-bc4e-2fa1ee64b5c0";
    const SUBKEY = "sub-c-afbab9e2-2a1b-11e4-b5f4-02ee2ddab7fe";                // set your subscribe key
    const SECRETKEY = "sec-c-OTc2ZWMxMjYtNjA2Ny00NTE1LWJhNzYtYjY1Y2MwZmNkNjI3";
// create channels with our agentID in them
    channelBase <- split(http.agenturl(), "/").pop();
// initialize the pubnub object
    pubnub <- PubNub(PUBKEY, SUBKEY, SECRETKEY);
    local response = { "x" : x.tostring(), "y" : y.tostring(), "id": "mike" }
    pubnub.publish("baecon", response);
    return results;
}


class PubNub {
    _pubNubBase = "https://pubsub.pubnub.com";
    _presenceBase = "https://pubsub.pubnub.com/v2/presence";
    
    _publishKey = null;
    _subscribeKey = null;
    _secretKey = null;
    _uuid = null
    
    _subscribe_request = null;
    
    // Class ctor. Specify your publish key, subscribe key, secret key, and optional UUID
    // If you do not provide a UUID, the Agent ID will be used
    constructor(publishKey, subscribeKey, secretKey, uuid = null) {
        this._publishKey = publishKey;
        this._subscribeKey = subscribeKey;
        this._secretKey = secretKey;
        
        if (uuid == null) uuid = split(http.agenturl(), "/").top();
        this._uuid = uuid;
    }
    
        
    /******************** PRIVATE FUNCTIONS (DO NOT CALL) *********************/
    function _defaultPublishCallback(err, data) {
        if (err) {
            server.log(err);
            return;
        }
        if (data[0] != 1) {
            server.log("Error while publishing: " + data[1]);
        } else {
            server.log("Published data at " + data[2]);
        }
    }
    
    /******************* PUBLIC MEMBER FUNCTIONS ******************************/
    
    // Publish a message to a channel
    // Input:   channel (string)
    //          data - squirrel object, will be JSON encoded 
    //          callback (optional) - to be called when publish is complete
    //      Callback takes two parameters: 
    //          err - null if successful
    //          data - squirrel object; JSON-decoded response from server
    //              Ex: [ 1, "Sent", "14067353030261382" ]
    //      If no callback is provided, _defaultPublishCallback is used
    function publish(channel, data, callback = null) {

        local msg = http.urlencode({m=http.jsonencode(data)}).slice(2);
        local url = format("%s/publish/%s/%s/%s/%s/%s/%s?uuid=%s", _pubNubBase, _publishKey, _subscribeKey, _secretKey, channel, "0", msg, _uuid);

        http.get(url).sendasync(function(resp) {
            local err = null;
            local data = null;
            
            // process data
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
            } else {
                try {        
                    data = http.jsondecode(resp.body);
                } catch (ex) {
                    err = ex;
                }
            }
            
            // callback
            if (callback != null) callback(err, data);
            else _defaultPublishCallback(err, data);
        }.bindenv(this));
    }
    
    // Subscribe to one or more channels
    // Input:
    //      channels (array) - array of channels to subscribe to
    //      callback (function) - called when new data arrives on any of the subscribed channels
    //          Callback takes three parameters:
    //              err (string) - null on success
    //              result (table) - contains (channel, value) pairs for each message received
    //              timetoken - nanoseconds since UNIX epoch, from PubNub service
    //      timetoken (optional) - callback with any new value since (timetoken)
    // Callback will be called once with result = {} and tt = 0 after first subscribing
    function subscribe(channels, callback, tt = 0) {
        local channellist = "";
        local channelidx = 1;
        foreach (channel in channels) {
            channellist += channel;
            if (channelidx < channels.len()) {
                channellist += ",";
            }
            channelidx++;
        }
        local url = format("%s/subscribe/%s/%s/0/%s?uuid=%s", _pubNubBase, _subscribeKey, channellist, tt.tostring(), _uuid);

        if (_subscribe_request) _subscribe_request.cancel();

        _subscribe_request = http.get(url);
        _subscribe_request.sendasync( function(resp) {

            _subscribe_request = null;
            local err = null;
            local data = null;
            local messages = null;
            local rxchannels = null;
            local tt = null;
            local result = {};
            
            // process data
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
            } else {
                try {        
                    data = http.jsondecode(resp.body);
                    messages = data[0];
                    tt = data[1];
                    if (data.len() > 2) {
                        rxchannels = split(data[2],",");
                        local chidx = 0;
                        foreach (ch in rxchannels) {
                            result[ch] <- messages[chidx++]
                        }
                    } else { 
                        if (messages.len() == 0) {
                            // successfully subscribed; no data yet
                        } else  {
                            // no rxchannels, so we have to fall back on the channel we called with
                            result[channels[0]] <- messages[0];
                        } 
                    }
                } catch (ex) {
                    err = ex;
                }
            }
            
            // callback
            callback(err, result, tt);            

            // re-start polling loop
            // channels and callback are still in scope because we got here with bindenv
            this.subscribe(channels,callback,tt);            
        }.bindenv(this));
    }
    
    // Get historical data from a channel
    // Input:
    //      channel (string)
    //      limit - max number of historical messages to receive
    //      callback - called on response from PubNub, takes two parameters:
    //          err - null on success
    //          data - array of historical messages
    function history(channel, limit, callback) {
        local url = format("%s/history/%s/%s/0/%d", _pubNubBase, _subscribeKey, channel, limit);
        
        http.get(url).sendasync(function(resp) {
            local err = null;
            local data = null;
            
            // process data
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
            } else {
                data = http.jsondecode(resp.body);
            }
            callback(err, data);
        }.bindenv(this));
    }
    
    // Inform Presence Server that this UUID is leaving a given channel
    // UUID will no longer be returned in results for other presence services (whereNow, hereNow, globalHereNow)
    // Input: 
    //      channel (string)
    // Return: None
    function leave(channel) {
        local url = format("%s/sub_key/%s/channel/%s/leave?uuid=%s",_presenceBase,_subscribeKey,channel,_uuid);
        http.get(url).sendasync(function(resp) {
            local err = null;
            local data = null;
            
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
                throw "Error Leaving Channel: "+err;
            }
        });
    }
    
    // Get list of channels that this UUID is currently marked "present" on
    // UUID is "present" on channels to which it is currently subscribed or publishing
    // Input:
    //      callback (function) - called when results are returned, takes two parameters
    //          err - null on success
    //          channels (array) - list of channels for which this UUID is "present"
    function whereNow(callback, uuid=null) {
        if (uuid == null) uuid=_uuid;
        local url = format("%s/sub-key/%s/uuid/%s",_presenceBase,_subscribeKey,uuid);
        http.get(url).sendasync(function(resp) {
            local err = null;
            local data = null;
        
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
                throw err;
            } else {
                try {        
                    data = http.jsondecode(resp.body);
                    if (!("channels" in data.payload)) {
                        err = "Channel list not found: "+resp.body;
                        throw err;
                    } 
                    data = data.payload.channels;
                } catch (err) {
                    callback(err,data);
                }
                callback(err,data);
            }
        });
    }
    
    // Get list of UUIds that are currently "present" on this channel
    // UUID is "present" on channels to which it is currently subscribed or publishing
    // Input:
    //      channel (string)
    //      callback (function) - called when results are returned, takes two parameters
    //          err - null on success
    //          result - table with two entries:
    //              occupancy - number of UUIDs present on channel
    //              uuids - array of UUIDs present on channel   
    function hereNow(channel, callback) {
        local url = format("%s/sub-key/%s/channel/%s",_presenceBase,_subscribeKey,channel);
        http.get(url).sendasync(function(resp) {
            //server.log(resp.body);
            local data = null;
            local err = null;
            local result = {};
        
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
                throw err;
            } else {
                try {        
                    data = http.jsondecode(resp.body);
                    if (!("uuids" in data)) {
                        err = "UUID list not found: "+resp.body;
                    } 
                    if (!("occupancy" in data)) {
                        err = "Occpancy not found"+resp.body;
                    }
                    result.uuids <- data.uuids;
                    result.occupancy <- data.occupancy;
                } catch (err) {
                    callback(err,result);
                }
                callback(err,result);
            }
        });
    }
    
    // Get list of UUIds that are currently "present" on this channel
    // UUID is "present" on channels to which it is currently subscribed or publishing
    // Input:
    //      channel (string)
    //      callback (function) - called when results are returned, takes two parameters
    //          err - null on success
    //          result - table with two entries:
    //              occupancy - number of UUIDs present on channel
    //              uuids - array of UUIDs present on channel       
    function globalHereNow(callback) {
        local url = format("%s/sub-key/%s",_presenceBase,_subscribeKey);
        http.get(url).sendasync(function(resp) {
            //server.log(resp.body);
            local err = null;
            local data = null;
            local result = {};
        
            if (resp.statuscode != 200) {
                err = format("%i - %s", resp.statuscode, resp.body);
                throw err;
            } else {
                try {        
                    data = http.jsondecode(resp.body);
                    if (!("channels" in data.payload)) {
                        err = "Channel list not found: "+resp.body.payload;
                    } 
                    result = data.payload.channels;
                } catch (err) {
                    callback(err,result);
                }
                callback(err,result);
            }
        });
    }
}

