http.onrequest(function(req, res) {
   device.send("getWlans", null);
   res.send(200, "OK");
})
