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

  // GET CREW BY MOVIE ID
  // app.get('mubidibi/crew/:id', (req, res) => {
  //   app.pg.connect(onConnect);

  //   function onConnect (err, client, release) {
  //     if (err) return res.send(err)

  //     // DIRECTORS
  //     client.query(
  //       "SELECT * FROM movie_director WHERE movie_id == $1", [req.params.id],
  //     ).then((result) => {
        
  //       // WRITERS

  //     })
  //   }
  // });
}


