var app = require('express')();
var http = require('http').Server(app);
var lyr = require('lyrics-fetcher');
var bt = require('bing-translate').init({
    client_id: 'lyricTest',
    client_secret: 'jK8rGTi6dSSk7Hdyywfra/PkUscoI2J5AXPmi/qdt9Q='
});
var io = require("socket.io")(http);
var SpotifyWebApi = require('spotify-web-api-node');



// credentials are optional
var spotifyApi = new SpotifyWebApi({
  clientId : 'c5339edbd19441f69820b06cd5dcb3e6',
  clientSecret : '673a3ddd66fe44d390e9fbecdc3a70b7'
});

  Array.prototype.remove = function(from, to) { var rest = this.slice((to || from) + 1 || this.length); this.length = from < 0 ? this.length + from : from; return this.push.apply(this, rest); };


io.on("connection", function(socket){

  console.log("connected");
  socket.on("song", function(song, artist, language){
    var songTime = 0;

    var cL = 0;

    var timePerLine;
    var tt = "";
    //console.log(artist);
    console.log(song);

    spotifyApi.searchTracks(song)
      .then(function(data) {
        console.log('Search: ', data.body.tracks.items[0].duration_ms);
        songTime = data.body.tracks.items[0].duration_ms;

            var lineCount = 0;

        lyr.fetch(artist, song, function (err, lyrics) {
            console.log(err || lyrics);
            var lines = lyrics.split("\n");
            console.log(lines[1]);
            console.log(lines[2]);

            console.log(lines.length);
            var oL = lines.length;
            for (var t = 0; t < oL; t++){
              if (lines[t] == ""){
                console.log("blank");
                lines.remove(t);
              }
              else {
                lineCount++;
              }
            }
            console.log(lineCount);
            for (var p = 0; p < lineCount; p++){
              console.log(lines[p]);
            }

            timePerLine = songTime / lines.length;
            console.log(timePerLine);

            setInterval(function(){

              console.log(lines[cL]);
              console.log("\n");
              bt.translate(lines[cL], 'en', (language || 'es'), function(err, resp){
                //console.log(resp.translated_text);
                console.log(resp.translated_text);
                io.to(socket.id).emit("text", lines[cL], resp.translated_text);
              });
              cL++;

            }, timePerLine);
            //console.log(lines[1]);
            // bt.translate(lines[1], 'en', 'es', function(err, resp){
            //   //console.log(resp.translated_text);
            //   tt += resp.translated_text + "\n";
            // });
            // bt.translate(lines[2], 'en', 'es', function(err, resp){
            //   //console.log(resp.translated_text);
            //   tt += resp.translated_text;
            //   console.log(tt);
            // });
        });
      }, function(err) {
        console.error(err);
      });


  });
});

app.get("/", function(req, res){
  res.sendFile(__dirname + "/index.html");
});

http.listen(8080, function(){
  console.log("Listening on *:8080");
});
