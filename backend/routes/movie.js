exports.movie = app => {

  // GET MOVIES
  app.get('/mubidibi/movies/', async (req, res) => {
    app.pg.connect(onConnect)
  
    function onConnect (err, client, release) {
      if (err) return res.send(err)
  
      client.query(
        'SELECT * FROM movie',
        function onResult (err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows));
          else res.send(err);
        }
      )
      
    }
  });

  // GET ONE MOVIE
  
  // ADD MOVIE
  app.post('/mubidibi/add-movie/', (req, res) => {
    app.pg.connect(onConnect);
    
    // call function add_movie with params: String title, Array genre, Date release_date, String synopsis, String poster, String added_by 
    // TO DO: make sure the added by field is not hardcoded'

    // catch apostrophes to avoid errors when inserting
    var title = req.body.title.replace(/'/g,"''");
    var synopsis = req.body.synopsis.replace(/'/g, "''");

    var query = `call add_movie (
      '${title}',
      array [`

      req.body.genre.forEach(genre => {
        query = query.concat(`'`, genre, `'`)
        if (genre != req.body.genre[req.body.genre.length-1]) {
          query = query.concat(',')
        }        
      });

      query = query.concat(
        `], 
        '${req.body.releaseDate}', 
        '${synopsis}', 
        '${req.body.poster}', 
        '2015-09301'
        )`
      );

      function onConnect (err, client, release) {
        if (err) return res.send(err);

        var result = client.query(query).then((result) => {
          req.body.directors.forEach(director => {
            client.query(
              `call add_movie_director_with_director_arg(
                ${director}
              )`
            )
          });

          req.body.writers.forEach(writer => {
            client.query(
              `call add_movie_writer_with_writer_arg(
                ${writer}
              )`
            )
          });

        })
        release();
        res.send(err || JSON.stringify(result));
      }
      });

}


