local b1 = [];
local b2 = [];
local readings = 0;
local report_thresh = 5;  // need at least this many to report
local confidence_thresh = 3;  // need to be confident in average
local L = 30.0;  // hard code length of room

http.onrequest(function(req, res) {
   device.send("getWlans", null);
   res.send(200, "OK");
})

device.on("baecon", function(arg) {
    b1.push(arg[0]);
    b2.push(arg[1]);
    update();
    imp.wakeup(0.25, function() {
        device.send("getWlans", null);
    });
});

function update() {
    if (readings >= report_thresh) {  // ready to publish, check data quality
        server.log("calculating and publishing");
        publish();
        readings = 0;
        b1 = [];
        b2 = [];
    } else {
        server.log("not yet publishing");
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
    server.log("b1 distance is " + distance(b1_avg, L));
    server.log("b2 distance is " + distance(b2_avg, L));
    local results = triangulate(distance(b1_avg, L), distance(b2_avg, L), L.tofloat());
    server.log("x and y are " + results[0] + " " + results[1]);
}

function distance(rssi, L) {  // if rssi is greater
    local rssi_f = rssi.tofloat();
    if (rssi_f > -52.0) {  // too close to make a call
        return 0.0;
    } else if ((rssi_f <= -52.0) && (rssi_f > -58.0)) {
        return 0.25 * L;
    } else if ((rssi_f <= -58.0) && (rssi_f > -62.0)) {
        return 0.5 * L;
    } else if ((rssi_f <= 62.0) && (rssi_f > -68)) {
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
    x = (math.pow(L.tofloat(), 2.0) + math.pow(b1.tofloat(), 2.0) - math.pow(b2.tofloat(), 2.0)) / (2 * L);
    server.log("x is " + x);
    y = math.sqrt((b1.tofloat() * b1.tofloat()) - (x.tofloat() * x.tofloat()));
    local results = [];
    results.push(x);
    results.push(y);
    return results;
}
