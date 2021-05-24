exports.movie = app => {

  // GET MOVIES
  app.post('/mubidibi/movies/', async (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)
      var query = `SELECT * FROM movie `;

      // if user is not admin, show only the movies that are not soft-deleted
      if (req.body.is_admin == "0") {
        query = query.concat(` WHERE is_deleted = false `);
      }

      query = query.concat(`order by id`);

      client.query(
        query,
        function onResult(err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows));
          else res.send(err);
        }
      )
    }
  });

  // GET ONE MOVIE
  app.get('/mubidibi/movie/:id', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        'SELECT * FROM movie where id = $1', [parseInt(req.params.id)],
        function onResult(err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows[0]));
          else res.send(err);
        }
      )
    }
  });

  // ADD MOVIE
  app.post('/mubidibi/add-movie/', async (req, res) => {

    // call function add_movie with params: String title, Array genre, Date release_date, String synopsis, String poster, String added_by 

    // upload image to cloudinary 
    // TO DO: create centralized cloudinary (for both mobile and web use)
    // var cloudinary = require('cloudinary');

    // cloudinary.config({
    //   cloud_name: "mubidibi-sp",
    //   api_key: '385294841727974',
    //   api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
    // });

    // MOVIE SCREENSHOTS AND POSTER UPLOAD   -- poster first element in the array

    var images = [];
    var movieData = [];    // movie data sent from the frontend
    const pics = await req.parts();

    if (pics != null) {
      for await (const pic of pics) {

        if (!pic.file && movieData.length == 0) {
          movieData = JSON.parse(pic.fields.movie.value); // movie data sent from the frontend
        } else {
          var buffer = await pic.toBuffer();
          var image = await buffer.toString('base64');
          image = image.replace(/(\r\n|\n|\r)/gm, "");

          // convert base64 to data uri
          var imageURI = `data:${pic.mimetype};base64,${image}`;

          var upload = await cloudinary.v2.uploader.upload(imageURI,
            {
              folder: "folder-name",
            },
            async function (err, result) {
              if (err) return err;
              else {
                images.push(result.url);
              }
            }
          );
        }
      }
    }

    // ADD TO DB
    app.pg.connect(onConnect); // DB connection

    // catch apostrophes to avoid errors when inserting
    var title = movieData.title.replace(/'/g, "''");
    var synopsis = movieData.synopsis.replace(/'/g, "''");

    console.log(movieData);

    var query = `select add_movie (
      '${title}',
      '${synopsis}', 
      _genre => `

    // check first if genre array is empty or not
    if (movieData.genre.length != 0 && movieData.genre != null) {
      query = query.concat(`array [`)
      movieData.genre.forEach(genre => {
        query = query.concat(`'`, genre, `'`)
        if (genre != movieData.genre[movieData.genre.length - 1]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`], 
      `)

    } else {
      query = query.concat(`null, 
      `);
    }

    // release date
    query = query.concat(`_release_date => `)

    if (movieData.release_date != "" && movieData.release_date != null) {
      query = query.concat(`'${movieData.release_date}', 
      `)
    } else {
      query = query.concat(`null, 
      `);
    }

    query = query.concat(`_runtime => `)

    if (movieData.running_time != "" && movieData.running_time != null) {
      query = query.concat(`${parseInt(movieData.running_time)}, 
      `)
    } else {
      query = query.concat(`null, 
      `);
    }

    // append poster if provided by user 
    query = query.concat(`_poster => `)

    if (movieData.poster == true && images.length != 0) {
      query = query.concat(`'${images[0]}', 
      `)
    } else {
      query = query.concat(`null, 
      `);
    }

    // append screenshot if provided by user 
    query = query.concat(`_screenshot => `)

    if (images.length > 1 && movieData.poster == true) {  // both poster and screenshots exist
      query = query.concat(`array [`)
      images.forEach(pic => {
        if (pic != images[0]) {
          query = query.concat(`'`, pic, `'`)
        }
        if (pic != images[images.length - 1] && pic != images[0]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`], 
      `)

    } else if (images.length > 0 && movieData.poster == false) {  // only screenshots were provided
      query = query.concat(`array [`)
      images.forEach(pic => {
        query = query.concat(`'`, pic, `'`)
        if (pic != images[images.length - 1]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`], 
      `)

    } else {
      query = query.concat(`null, 
      `);  // no screenshots were provided
    }

    query = query.concat(`_added_by => '${movieData.added_by}'
      );`
    );

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      console.log(query);

      // add directors
      var result = await client.query(query).then((result) => {
        const id = result.rows[0].add_movie
        if (movieData.directors.length != 0) {
          movieData.directors.forEach(director => {
            client.query(
              `call add_movie_director (
                ${id},
                ${director}
              )`
            )
          });
        }

        // add writers
        if (movieData.writers.length != 0) {
          movieData.writers.forEach(writer => {
            client.query(
              `call add_movie_writer (
                ${id},
                ${writer}
              )`
            )
          });
        }

        // add actors
        // assume that actor's name/id is required. Roles are not required.
        if (movieData.actors.length != 0) {
          movieData.actors.forEach((actor, index) => {
            var actorQuery = `call add_movie_actor (
              ${id},
              ${actor},
              `;

            if (movieData.roles[index].length) {
              actorQuery = actorQuery.concat(`array [`);
              movieData.roles[index].forEach(role => {
                actorQuery = actorQuery.concat(`'`, role, `'`)
                if (role != movieData.roles[movieData.roles.length - 1]) {
                  actorQuery = actorQuery.concat(',')
                }
              });
              actorQuery = actorQuery.concat(`]`)
            } else {
              actorQuery = actorQuery.concat(`null`);
            }

            client.query(actorQuery);
          });
        }
        return result;
      });
      release();
      res.send(err || JSON.stringify(result.rows[0].add_movie));
    }
  });


  // UPDATE MOVIE
  app.put('/mubidibi/update-movie/:id', async (req, res) => {
    // upload image to cloudinary 
    // var cloudinary = require('cloudinary');

    // cloudinary.config({
    //   cloud_name: "mubidibi-sp",
    //   api_key: '385294841727974',
    //   api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
    // });

    // MOVIE SCREENSHOTS AND POSTER UPLOAD   -- poster first element in the array

    var images = [];
    var movieData = [];    // movie data sent from the frontend
    const pics = await req.parts();

    if (pics != null) {
      for await (const pic of pics) {

        if (!pic.file && movieData.length == 0) {
          movieData = JSON.parse(pic.fields.movie.value); // movie data sent from the frontend
        } else {
          var buffer = await pic.toBuffer();
          var image = await buffer.toString('base64');
          image = image.replace(/(\r\n|\n|\r)/gm, "");

          // convert base64 to data uri
          var imageURI = `data:${pic.mimetype};base64,${image}`;

          var upload = await cloudinary.v2.uploader.upload(imageURI,
            {
              folder: "folder-name",
            },
            async function (err, result) {
              if (err) return err;
              else {
                images.push(result.url);
              }
            }
          );
        }
      }
    }

    // update movie 
    app.pg.connect(onConnect);

    // catch apostrophes to avoid errors when inserting
    var title = movieData.title.replace(/'/g, "''");
    var synopsis = movieData.synopsis.replace(/'/g, "''");

    // construct query 
    var query = `UPDATE movie 
    SET title = '${title}', 
    synopsis = '${synopsis}', 
    release_date = `

    if (movieData.release_date != "" || movieData.release_date != null) {
      query = query.concat(`'${movieData.release_date}', 
      `)
    } else {
      query = query.concat(`null, 
      `);
    }

    query = query.concat(`runtime = `);

    if (movieData.running_time != "" || movieData.running_time != null) {
      query = query.concat(`${parseInt(movieData.running_time)}, 
      `)
    } else {
      query = query.concat(`null, 
      `);
    }

    query = query.concat(`poster = `);

    if (movieData.poster == true && images.length != 0) { // user changed poster on update
      query = query.concat(`'${images[0]}', 
      `)
    } else if (movieData.posterURI != "" || movieData.posterURI != null) {  // poster exists in DB and hasn't been changed on update
      query = query.concat(`'${movieData.posterURI}', 
      `);
    } else {
      query = query.concat(`null, 
      `);
    }

    query = query.concat(`genre = `);

    // check first if genre array is empty or not
    if (movieData.genre.length != 0 || movieData.genre != null) {
      query = query.concat(`array [`)
      movieData.genre.forEach(genre => {
        query = query.concat(`'`, genre, `'`)
        if (genre != movieData.genre[movieData.genre.length - 1]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`], 
      `)

    } else {
      query = query.concat(`null, 
      `);
    }

    query = query.concat(`screenshot = `);

    // TO DO: provide condition for when screenshots already exist before edit

    if (images.length > 1 && movieData.poster == true) {  // both poster and screenshots exist
      query = query.concat(`array [`)
      images.forEach(pic => {
        if (pic != images[0]) {
          query = query.concat(`'`, pic, `'`)
        }
        if (pic != images[images.length - 1] && pic != images[0]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`]
      `)

    } else if (images.length > 0 && movieData.poster == false) {  // only screenshots were provided
      query = query.concat(`array [`)
      images.forEach(pic => {
        query = query.concat(`'`, pic, `'`)
        if (pic != images[images.length - 1]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`]
      `)

    } else {
      query = query.concat(`null 
      `);  // no screenshots were provided
    }

    // WHERE CONDITION
    query = query.concat(` WHERE id = $1 RETURNING id`)

    console.log(query)

    function onConnect(err, client, release) {
      if (err) return res.send(err);

      client.query(query, [parseInt(req.params.id)],
        function onResult(err, result) {
          console.log(result);

          release()
          res.send(err || JSON.stringify(result.rows[0].id));
        }
      );
    }

  });

  // DELETE MOVIE
  app.delete('/mubidibi/movies/:id', (req, res) => {
    app.pg.connect(onConnect);

    function onConnect(err, client, release) {
      if (err) return res.send(err);

      // initial delete
      // client.query('DELETE FROM movie where id = $1 RETURNING id', [parseInt(req.params.id)],
      //   function onResult(err, result) {
      //     console.log(result);

      //     release()
      //     res.send(err || JSON.stringify(result.rows[0].id));
      //   }
      // );

      // updated delete: soft-delete only, sets the is_deleted field to true
      client.query('UPDATE movie SET is_deleted = true where id = $1 RETURNING id', [parseInt(req.params.id)],
        function onResult(err, result) {
          release();
          res.send(err || JSON.stringify(result.rows[0].id));
        }
      );
    }
  });

  // RESTORE MOVIE
  app.post('/mubidibi/movies/restore/', (req, res) => {
    app.pg.connect(onConnect);

    function onConnect(err, client, release) {
      if (err) return res.send(err);

      // restore movie: sets the is_deleted field to false;
      client.query('UPDATE movie SET is_deleted = false where id = $1 RETURNING id', [parseInt(req.body.id)],
        function onResult(err, result) {
          release();
          res.send(err || JSON.stringify(result.rows[0].id));
        }
      );
    }
  });

  // GET GENRES
  app.get('/mubidibi/genres/', async (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        'select distinct unnest(genre) as genre from movie',
        function onResult(err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows));
          else res.send(err);
        }
      )
    }
  })
}



