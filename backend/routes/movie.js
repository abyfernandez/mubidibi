exports.movie = app => {

  // GET MOVIES
  app.get('/mubidibi/movies/', (req, reply) => {
    app.pg.connect(onConnect)
  
    function onConnect (err, client, release) {
      if (err) return reply.send(err)
  
      client.query(
        'SELECT * FROM movie',
        function onResult (err, result) {
          if (result) console.log(result.rows);
          release()
          reply.send(err || result)
        }
      )
    }
  });

  // GET ONE MOVIE
  
  
  // UPSERT MOVIE


  // DELETE MOVIE
}


