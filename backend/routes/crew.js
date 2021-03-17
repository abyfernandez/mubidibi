exports.crew = app => {

  // GET CREW
  app.get('/mubidibi/crew/', (req, res) => {
    app.pg.connect(onConnect)
  
    function onConnect (err, client, release) {
      if (err) return res.send(err)
  
      client.query(
        'SELECT * FROM crew',
        function onResult (err, result) {
          // if (result) console.log(JSON.stringify(result.rows));
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      )
    }
  });
}


