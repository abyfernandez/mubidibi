exports.movie = app => {

  // GET MOVIES
  app.post('/mubidibi/movies/', async (req, res) => {
    app.pg.connect(onConnect)

    async function onConnect(err, client, release) {
      if (err) return res.send(err)
      var query = `SELECT * FROM movie`;

      // if user is not admin, show only the movies that are not soft-deleted
      if (req.body.user != "admin" || req.body.mode == "form") {
        query = query.concat(` WHERE is_deleted = false `);
      }

      var result = await client.query(
        query).then(async (result) => {
          var movies = result.rows;

          // get posters  
          for (var i = 0; i < movies.length; i++) {
            var { rows } = await client.query(`select * from movie_media where movie_id = ${movies[i].id} and type = 'poster'`);
            movies[i]['poster'] = rows;
          }

          // get screenshots  
          for (var i = 0; i < movies.length; i++) {
            var { rows } = await client.query(`select * from movie_media where movie_id = ${movies[i].id} and type = 'gallery'`);
            movies[i]['screenshot'] = rows;
          }
          return movies;
        });

      release();
      if (result) res.send(JSON.stringify(result));
      else res.send(err);
    }
  });

  // GET ONE MOVIE
  app.get('/mubidibi/movie/:id', (req, res) => {
    app.pg.connect(onConnect)

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      var result = await client.query(
        'SELECT * FROM movie where id = $1', [parseInt(req.params.id)]).then(async (result) => {
          var movie = result.rows[0];

          // get posters  
          var { rows } = await client.query(`select * from movie_media where movie_id = ${movie.id} and type = 'poster'`);
          movie['poster'] = rows;

          // get screenshots  
          var { rows } = await client.query(`select * from movie_media where movie_id = ${movie.id} and type = 'gallery'`);
          movie['screenshot'] = rows;

          return movie;
        });
      release();
      if (result) res.send(JSON.stringify(result));
      else res.send(err);
    }
  });

  // ADD MOVIE
  app.post('/mubidibi/add-movie/', async (req, res) => {

    // upload image to cloudinary 
    // TO DO: create centralized cloudinary (for both mobile and web use)
    var cloudinary = require('cloudinary');

    cloudinary.config({
      cloud_name: "mubidibi-sp",
      api_key: '385294841727974',
      api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
    });

    var movieData = [];    // movie data sent from the frontend
    const pics = await req.parts();
    var mediaBuffer = []; // container for all the media files buffer to be uploaded
    var mediaMimeType = [];
    var posters = []; // poster urls 
    var gallery = []; // gallery urls 
    var trailers = []; // trailers urls 
    var audios = []; // audios urls 

    // separate media from other data
    if (pics != null) {
      for await (const pic of pics) {

        if (!pic.file && movieData.length == 0) {
          movieData = JSON.parse(pic.fields.movie.value); // movie data sent from the frontend

        } else {
          var buffer = await pic.toBuffer();
          mediaBuffer.push(buffer);
          mediaMimeType.push(pic.mimetype);
        }
      }
    }

    // Upload files to Cloudinary
    for (var i = 0; i < mediaBuffer.length; i++) {

      var file = await mediaBuffer[i].toString('base64');
      file = file.replace(/(\r\n|\n|\r)/gm, "");

      // convert base64 to data uri
      var fileURI = `data:${mediaMimeType[i]};base64,${file}`;

      var upload = await cloudinary.v2.uploader.upload(fileURI,
        {
          folder: "folder-name",
          resource_type: mediaMimeType[i].split('/')[0] == "audio" ? "raw" : mediaMimeType[i].split('/')[0],
        },
        async function (err, result) {
          if (err) return err;
          else {
            if (movieData.media_type[i] == "poster") posters.push(result.url);
            else if (movieData.media_type[i] == "gallery") gallery.push(result.url);
            else if (movieData.media_type[i] == "trailer") trailers.push(result.url);
            else if (movieData.media_type[i] == "audio") audios.push(result.url);
          }
        }
      );
    }

    // ADD TO DB
    app.pg.connect(onConnect); // DB connection

    // catch apostrophes to avoid errors when inserting
    var title = movieData.title.replace(/'/g, "''");
    var synopsis = movieData.synopsis.replace(/'/g, "''");

    movieData.actors.forEach((a, i) => {
      a.role.forEach((r, ind) => {
        r = r.replace(/'/g, "''");
      });
    });

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

    query = query.concat(`_added_by => '${movieData.added_by}'
      );`
    );

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      var result = await client.query(query).then((result) => {
        const id = result.rows[0].add_movie

        // posters
        if (posters.length != 0) {
          for (var i = 0; i < posters.length; i++) {
            var desc = movieData.poster_desc[i] != null ? movieData.poster_desc[i].replace(/'/g, "''") : null;
            var query = `insert into movie_media (movie_id, url, description, type) values (${id}, '${posters[i]}', `;
            if (desc != null) query = query.concat(`'${desc}', 'poster')`);
            else query = query.concat(`null, 'poster')`);

            client.query(query);
          }
        }

        // gallery
        if (gallery.length != 0) {
          for (var i = 0; i < gallery.length; i++) {
            var desc = movieData.gallery_desc[i] != null ? movieData.gallery_desc[i].replace(/'/g, "''") : null;
            var query = `insert into movie_media (movie_id, url, description, type) values (${id}, '${gallery[i]}', `;
            if (desc != null) query = query.concat(`'${desc}', 'gallery')`);
            else query = query.concat(`null, 'gallery')`);

            client.query(query);
          }
        }

        // trailers
        if (trailers.length != 0) {
          for (var i = 0; i < trailers.length; i++) {
            var desc = movieData.trailer_desc[i] != null ? movieData.trailer_desc[i].replace(/'/g, "''") : null;
            var query = `insert into movie_media (movie_id, url, description, type) values (${id}, '${trailers[i]}', `;
            if (desc != null) query = query.concat(`'${desc}', 'trailer')`);
            else query = query.concat(`null, 'trailer')`);

            client.query(query);
          }
        }
        // audio
        if (audios.length != 0) {
          for (var i = 0; i < audios.length; i++) {
            var desc = movieData.audio_desc[i] != null ? movieData.audio_desc[i].replace(/'/g, "''") : null;
            var query = `insert into movie_media (movie_id, url, description, type) values (${id}, '${audios[i]}', `;
            if (desc != null) query = query.concat(`'${desc}', 'audio')`);
            else query = query.concat(`null, 'audio')`);

            client.query(query);
          }
        }

        // add directors
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
        if (movieData.actors.length != 0) {
          movieData.actors.forEach((actor, index) => {
            var actorQuery = `call add_movie_actor (
              ${id},
              ${actor.id},
              `;

            if (actor.role.length) {
              actorQuery = actorQuery.concat(`array [`);
              actor.role.forEach(role => {
                actorQuery = actorQuery.concat(`'`, role, `'`)
                if (role != actor.role[actor.role.length - 1]) {
                  actorQuery = actorQuery.concat(',')
                }
              });
              actorQuery = actorQuery.concat(`])`)
            } else {
              actorQuery = actorQuery.concat(`null)`);
            }

            client.query(actorQuery);
          });
        }

        // awards
        if (movieData.awards.length != 0) {
          movieData.awards.forEach((award, index) => {
            var awardQuery = `insert into movie_award (movie_id, award_id, year, type) values (${id}, ${award.id}, ${award.year}, '${award.type}')`;
            client.query(awardQuery);
          });
        }

        // famous lines
        if (movieData.lines.length != 0) {
          movieData.lines.forEach((quote, index) => {
            var line = quote.quotation.replace(/'/g, "''");
            var query = `insert into quote (movie_id, quotation, role) values (${id}, '${line}', '${quote.role}')`;
            client.query(query);
          })
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
    var cloudinary = require('cloudinary');

    cloudinary.config({
      cloud_name: "mubidibi-sp",
      api_key: '385294841727974',
      api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
    });

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
  app.get('/mubidibi/movies/:id', (req, res) => {
    app.pg.connect(onConnect);

    function onConnect(err, client, release) {
      if (err) return res.send(err);

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



