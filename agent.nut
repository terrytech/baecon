local b1 = [];
local b2 = [];
local readings = 0;
local report_thresh = 5;  // need at least this many to report
local confidence_thresh = 3;  // need to be confident in average

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
    server.log("done searching through b1, computed " + b1_avg);
    server.log("done searching through b2, computed " + b2_avg);
    return false;
}

function triangulate(b1, b2) {
    // map raw rssi values to triangulation in discrete values
    
}
