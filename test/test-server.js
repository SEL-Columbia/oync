// simple test server to mock serving changesets from a directory
var express = require('express');
var app = express();

// read config
var config = require('./env.json');
var DATA_DIR = config['data_dir'];

// all changesets (ignore query params for now)
app.get('/api/0.6/changesets*', function(req, res) {
    res.sendFile('changesets.all', {root: DATA_DIR});
});

// changeset summary
app.get('/api/0.6/changeset/:id', function(req, res) {
    res.sendFile(req.params.id + '.cs', {root: DATA_DIR});
});

// changeset details 
app.get('/api/0.6/changeset/:id/download', function(req, res) {
    res.sendFile(req.params.id + '.osc', {root: DATA_DIR});
});
    
var server = app.listen(3000, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('Test server listening at http://%s:%s', host, port);
});
