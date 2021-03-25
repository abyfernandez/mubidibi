exports.movie = app => {

  // GET MOVIES
  app.get('/mubidibi/movies/', async (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        'SELECT * FROM movie',
        function onResult(err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows));
          else res.send(err);
        }
      )

    }
  });

  // GET ONE MOVIE
  // app.get('/mubidibi/movie/:id', (req,res) => {
  //   app.pg.connect(onConnect)


  // })

  // ADD MOVIE
  app.post('/mubidibi/add-movie/', (req, res) => {
    app.pg.connect(onConnect);

    // call function add_movie with params: String title, Array genre, Date release_date, String synopsis, String poster, String added_by 
    // TO DO: make sure the added by field is not hardcoded'

    // catch apostrophes to avoid errors when inserting
    var title = req.body.title.replace(/'/g, "''");
    var synopsis = req.body.synopsis.replace(/'/g, "''");

    var query = `select "add_movie" (
      '${title}',
      array [`

    req.body.genre.forEach(genre => {
      query = query.concat(`'`, genre, `'`)
      if (genre != req.body.genre[req.body.genre.length - 1]) {
        query = query.concat(',')
      }
    });

    var date = req.body.releaseDate != '' ? `'${req.body.releaseDate}'` : ''

    query = query.concat(
      `], 
        ${date}, 
        '${synopsis}', 
        '${req.body.poster}', 
        '2015-09301'
        )`
    );

    async function onConnect(err, client, release) {
      if (err) return res.send(err);


      var movie = await client.query(query).then(async (result) => {
        var id = result.rows[0].add_movie; // movie id to be returned by the called function

        // add directors
        req.body.directors.forEach(director => {
          client.query(
            `call add_movie_director_with_director_arg(
                ${director}
              )`
          )
        });

        // add writers
        req.body.writers.forEach(writer => {
          client.query(
            `call add_movie_writer_with_writer_arg(
                ${writer}
              )`
          )
        });

        // get added movie details to be displayed in the ui 
        var { rows } = await client.query('select * from movie where id=$1', [id]);
        var movie = []; // data to be returned
        movie = rows[0];
        return movie;

      });

      release();
      res.send(err || JSON.stringify(movie));
    }
  });

  // DELETE MOVIE
  app.delete('/mubidibi/movies/:id', (req, res) => {
    app.pg.connect(onConnect);

    function onConnect(err, client, release) {
      if (err) return res.send(err);

      client.query('DELETE FROM movie where id = $1', [parseInt(req.params.id)],
        function onResult(err, result) {
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      );
    }
  });
}


  // const deleteUser = (request, response) => {
  //   const id = parseInt(request.params.id)

  //   pool.query('DELETE FROM users WHERE id = $1', [id], (error, results) => {
  //     if (error) {
  //       throw error
  //     }
  //     response.status(200).send(`User deleted with ID: ${id}`)
  //   })
  // }



