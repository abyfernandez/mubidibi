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
  app.post('/mubidibi/add-movie/', async (req, res) => {

    // call function add_movie with params: String title, Array genre, Date release_date, String synopsis, String poster, String added_by 

    // upload image to cloudinary 
    var cloudinary = require('cloudinary');

    cloudinary.config({
      cloud_name: "mubidibi-sp",
      api_key: '385294841727974',
      api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
    });

    // MOVIE POSTER
    var data = await req.file();
    var buffer = await data.toBuffer();
    var posterURL;

    var base64String = await buffer.toString('base64');
    base64String = base64String.replace(/(\r\n|\n|\r)/gm, "");

    // convert base64 to data uri
    var imageURI = `data:${data.mimetype};base64,${base64String}`;

    var upload = await cloudinary.v2.uploader.upload(imageURI,
      {
        folder: "folder-name",
      },
      async function (err, result) {
        if (err) return err;
        else {
          posterURL = result.url;
        }
      }
    );

    // // MOVIE SCREENSHOTS
    // // TO DO: UPLOAD MULTIPLE IMAGES
    // var screenshots = [];
    const pics = await req.files();
    console.log(data);

    for await (const pic of pics) {
      pic
      //   var buff = await pic.toBuffer();
      //   var picString = await buff.toString('base64');
      //   picString = picString.replace(/(\r\n|\n|\r)/gm, "");

      //   // convert base64 to data uri
      //   var picURI = `data:${pic.mimetype};base64,${picString}`;

      //   var upload = await cloudinary.v2.uploader.upload(picURI,
      //     {
      //       folder: "folder-name",
      //     },
      //     async function (err, result) {
      //       if (err) return err;
      //       else {
      //         screenshots.push(result.url);
      //       }
      //     }
      //   );
    }

    // console.log(screenshots);

    // ADD TO DB
    // TO DO: UPLOAD MULTIPLE IMAGES FOR SCREENSHOTS
    app.pg.connect(onConnect); // DB connection

    var movieData = JSON.parse(data.fields.movie.value);    // movie data sent from the frontend

    // catch apostrophes to avoid errors when inserting
    var title = movieData.title.replace(/'/g, "''");
    var synopsis = movieData.synopsis.replace(/'/g, "''");

    var query = `select "add_movie" (
      '${title}',
      array [`

    movieData.genre.forEach(genre => {
      query = query.concat(`'`, genre, `'`)
      if (genre != movieData.genre[movieData.genre.length - 1]) {
        query = query.concat(',')
      }
    });

    query = query.concat(
      `], 
        '${movieData.release_date}', 
        '${synopsis}', 
        ${parseInt(movieData.running_time)},
        '${posterURL}',
        null,
        '${movieData.added_by}')
        `);

    // var query = `select "add_movie" (
    //   '${title}',
    //   array [`

    // movieData.genre.forEach(genre => {
    //   query = query.concat(`'`, genre, `'`)
    //   if (genre != movieData.genre[movieData.genre.length - 1]) {
    //     query = query.concat(',')
    //   }
    // });

    // query = query.concat(
    //   `], 
    //     '${movieData.release_date}', 
    //     '${synopsis}', 
    //     ${movieData.running_time},
    //     '${posterURL}',`);

    // // check first if screenshot array is empty or not
    // if (movieData.screenshot.length != 0) {
    //   query = query.concat(`array [`);
    //   movieData.screenshot.forEach(pic => {
    //     query = query.concat(`'`, pic, `'`)
    //     if (pic != movieData.screenshot[movieData.screenshot.length - 1]) {
    //       query = query.concat(',')
    //     }
    //   });
    //   query = query.concat(`],`);
    // }

    // else {
    //   query = query.concat(`null,`);
    // }

    // query = query.concat(`'${movieData.added_by}'
    //     )`
    // );

    // async function onConnect(err, client, release) {
    //   if (err) return res.send(err);

    //   console.log("QUERY: ", query);

    //   var movie = await client.query(query).then(async (result) => {
    //     var id = result.rows[0].add_movie; // movie id to be returned by the called function

    //     // add directors
    //     movieData.directors.forEach(director => {
    //       client.query(
    //         `call add_movie_director_with_director_arg(
    //           ${director}
    //         )`
    //       )
    //     });

    //     // add writers
    //     movieData.writers.forEach(writer => {
    //       client.query(
    //         `call add_movie_writer_with_writer_arg(
    //           ${writer}
    //         )`
    //       )
    //     });

    //     // get added movie details to be displayed in the ui 
    //     var { rows } = await client.query('select * from movie where id=$1', [id]);
    //     var movie = []; // data to be returned
    //     movie = rows[0];
    //     return movie;

    //   });

    //   release();
    //   res.send(err || JSON.stringify(movie));
    // }
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



