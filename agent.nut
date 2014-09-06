http.onrequest(function(req, res) {
   device.send("reportRSSI", null);
   res.send(200, "OK");
})
