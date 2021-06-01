exports.crew = app => {

  // GET CREW
  app.post('/mubidibi/crew/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      var query = `SELECT *, concat_ws(' ', first_name, middle_name, last_name, suffix) as name FROM crew`;

      if (req.body.user != "admin" || req.body.mode == "form") query = query.concat(' where is_deleted = false');

      query = query.concat(` order by name asc `);

      client.query(
        query,
        async function onResult(err, result) {
          var crew = result.rows;

          for (var i = 0; i < crew.length; i++) {
            var type = [];

            var director = await client.query(`select exists(select 1 from movie_director where director_id=$1)`, [(crew[i].id)]);
            var writer = await client.query(`select exists(select 1 from movie_writer where writer_id=$1)`, [(crew[i].id)]);
            var actor = await client.query(`select exists(select 1 from movie_actor where actor_id=$1)`, [(crew[i].id)]);

            if (director.rows[0].exists) type.push("Direktor");
            if (writer.rows[0].exists) type.push("Manunulat");
            if (actor.rows[0].exists) type.push("Aktor");

            crew[i]['type'] = type;
          }
          release()
          res.send(err || JSON.stringify(crew));
        }
      )
    }
  });

  // GET CREW BY MOVIE ID -- MOVIE VIEW
  app.post('/mubidibi/crew-for-movie/', (req, res) => {
    app.pg.connect(onConnect);

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      var crew = [];

      // DIRECTORS
      var directorQuery = `SELECT * from crew where id in (SELECT director_id FROM movie_director where movie_id = ${req.body.movie_id})`;
      if (req.body.user != "admin") directorQuery = directorQuery.concat(` and is_deleted = false`)
      var director = await client.query(directorQuery);

      // WRITERS
      var writerQuery = `SELECT * from crew where id in (SELECT writer_id FROM movie_writer where movie_id = ${req.body.movie_id})`;
      if (req.body.user != "admin") writerQuery = writerQuery.concat(` and is_deleted = false`)
      var writer = await client.query(writerQuery);

      // ACTORS
      var actorQuery = `SELECT crew.*, movie_actor.role from crew left join movie_actor on crew.id = movie_actor.actor_id where id in (SELECT actor_id FROM movie_actor where movie_id = ${req.body.movie_id}) and movie_actor.movie_id = ${req.body.movie_id}`;
      if (req.body.user != "admin") actorQuery = actorQuery.concat(` and is_deleted = false`)
      var actor = await client.query(actorQuery);

      crew.push(director.rows);
      crew.push(writer.rows);
      crew.push(actor.rows);

      release();
      res.send(err || JSON.stringify(crew));
    }
  });

  // GET ONE CREW FOR A CERTAIN MOVIE -- CREW VIEW
  app.get('/mubidibi/one-crew/:id', (req, res) => {
    app.pg.connect(onConnect)

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        `SELECT *, concat_ws(' ', first_name, middle_name, last_name, suffix) as name FROM crew where id = $1`, [parseInt(req.params.id)],
        async function onResult(err, result) {
          var crew = result.rows[0];
          var type = [];
          var movies = [];

          var director = await client.query(`select exists(select 1 from movie_director where director_id=$1)`, [parseInt(req.params.id)]);
          var writer = await client.query(`select exists(select 1 from movie_writer where writer_id=$1)`, [parseInt(req.params.id)]);
          var actor = await client.query(`select exists(select 1 from movie_actor where actor_id=$1)`, [parseInt(req.params.id)]);

          if (director.rows[0].exists) type.push("Direktor");
          if (writer.rows[0].exists) type.push("Manunulat");
          if (actor.rows[0].exists) type.push("Aktor");

          crew['type'] = type;

          // get the movies associated to this crew according to crew type
          var movies_directed = await client.query(`select movie.* from movie left join movie_director as md on movie.id = md.movie_id where md.director_id = $1`, [parseInt(req.params.id)]);
          var movies_written = await client.query(`select movie.* from movie left join movie_writer as mw on movie.id = mw.movie_id where mw.writer_id = $1`, [parseInt(req.params.id)]);
          var movies_acted = await client.query(`select movie.* from movie left join movie_actor as ma on movie.id = ma.movie_id where ma.actor_id = $1`, [parseInt(req.params.id)]);

          movies.push(movies_directed.rows);
          movies.push(movies_written.rows);
          movies.push(movies_acted.rows);

          crew['movies'] = movies;

          release()
          if (result) res.send(JSON.stringify(crew));
          else res.send(err);
        }
      )
    }
  });

  // ADD CREW
  app.post('/mubidibi/add-crew/', async (req, res) => {
    // call function add_crew

    // upload image to cloudinary 
    // TO DO: create centralized cloudinary (for both mobile and web use)
    var cloudinary = require('cloudinary');

    cloudinary.config({
      cloud_name: "mubidibi-sp",
      api_key: '385294841727974',
      api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
    });

    // CREW PHOTOS AND DISPLAY PIC UPLOAD   -- displayPic first element in the array

    var images = [];
    var crewData = [];    // crew data sent from the frontend
    const pics = await req.parts();

    if (pics != null) {
      for await (const pic of pics) {

        if (!pic.file && crewData.length == 0) {
          crewData = JSON.parse(pic.fields.crew.value); // crew data sent from the frontend
        } else {
          // TO DO: Fix ---> this currently only works if there is a displayPic added. However if displayPic is not provided, this might crash --> (?)
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
    var first_name = crewData.first_name.replace(/'/g, "''");
    var middle_name = crewData.middle_name.replace(/'/g, "''");
    var last_name = crewData.last_name.replace(/'/g, "''");
    var suffix = crewData.suffix.replace(/'/g, "''");
    var birthplace = crewData.birthplace.replace(/'/g, "''");
    var description = crewData.description.replace(/'/g, "''");

    var query = `select add_crew (
    _first_name => '${first_name}',
    `;

    if (last_name != "" && last_name != null) {
      query = query.concat(`_last_name => '${last_name}', 
      `);
    }

    if (middle_name != "" && middle_name != null) {
      query = query.concat(`_middle_name => '${middle_name}', 
      `);
    }

    if (suffix != "" && suffix != null) {
      query = query.concat(`_suffix => '${suffix}', 
      `);
    }

    if (crewData.birthday != "" && crewData.birthday != null) {
      query = query.concat(`_birthday => '${crewData.birthday}', 
      `);
    }

    if (birthplace != "" && birthplace != null) {
      query = query.concat(`_birthplace => '${birthplace}', 
      `);
    }

    if (description != "" && description != null) {
      query = query.concat(`_description => '${description}', 
      `);
    }

    if (crewData.is_alive != null) {
      query = query.concat(`_is_alive => ${crewData.is_alive}, 
      `);
    }

    if (crewData.deathdate != "" && crewData.deathdate != null) {
      query = query.concat(`_deathdate => '${crewData.deathdate}', 
      `);
    }

    // append displayPic if provided by user 
    if (crewData.displayPic == true && images.length != 0) {
      query = query.concat(`_display_pic => '${images[0]}', 
      `)
    }

    // append photos if provided by user 
    if (images.length > 1 && crewData.displayPic == true) {  // both displayPic and photos exist
      query = query.concat(`_photos => array [`)
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
    } else if (images.length > 0 && crewData.displayPic == false) {  // only photos were provided
      query = query.concat(`_photos => array [`)
      images.forEach(pic => {
        query = query.concat(`'`, pic, `'`)
        if (pic != images[images.length - 1]) {
          query = query.concat(',')
        }
      });
      query = query.concat(`], 
      `)
    }

    query = query.concat(`_added_by => '${crewData.added_by}'
    );`
    );

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      console.log(query);

      var result = await client.query(query).then((result) => {
        const id = result.rows[0].add_crew

        // add movies as director
        if (crewData.director.length != 0) {
          crewData.director.forEach((d) => {
            client.query(`call add_movie_director (
              ${d},
              ${id}
            )`);
          });
        }

        // add movies as writer
        if (crewData.writer.length != 0) {
          crewData.writer.forEach((w) => {
            client.query(`call add_movie_writer (
              ${w},
              ${id}
            )`)
          });
        }

        // add actors
        if (crewData.actor.length != 0) {
          crewData.actor.forEach((a, index) => {
            var actorQuery = `call add_movie_actor (
              ${a.id},
              ${id},
              `;

            if (a.role.length) {
              actorQuery = actorQuery.concat(`array [`);
              a.role.forEach(role => {
                actorQuery = actorQuery.concat(`'`, role, `'`)
                if (role != a.role[a.role.length - 1]) {
                  actorQuery = actorQuery.concat(',')
                }
              });
              actorQuery = actorQuery.concat(`])`)
            } else {
              actorQuery = actorQuery.concat(`null)`);
            }

            console.log("ACTORS => ", index, ": ", actorQuery);
            client.query(actorQuery);
          });
        }

        // awards
        if (crewData.awards.length != 0) {
          crewData.awards.forEach((award, index) => {
            var awardQuery = `insert into crew_award (crew_id, award_id, year, type) values (${id}, ${award.id}, ${award.year}, '${award.type}')`;

            console.log("AWARDS => ", index, ": ", awardQuery);
            client.query(awardQuery);
          });
        }
        return result;

      });
      release();
      res.send(err || JSON.stringify(result.rows[0].add_crew));
    }
  });

  // DELETE CREW
  app.get('/mubidibi/delete-crew/:id', (req, res) => {
    app.pg.connect(onConnect);

    function onConnect(err, client, release) {
      if (err) return res.send(err);

      // soft-delete only, sets the is_deleted field to true
      client.query('UPDATE crew SET is_deleted = true where id = $1 RETURNING id', [parseInt(req.params.id)],
        function onResult(err, result) {
          console.log(result, result.rows[0].id);
          release();
          res.send(err || JSON.stringify(result.rows[0].id));
        }
      );
    }
  });

  // RESTORE CREW
  app.post('/mubidibi/crew/restore/', (req, res) => {
    app.pg.connect(onConnect);

    function onConnect(err, client, release) {
      if (err) return res.send(err);

      // restore Crew: sets the is_deleted field to false;
      client.query('UPDATE crew SET is_deleted = false where id = $1 RETURNING id', [parseInt(req.body.id)],
        function onResult(err, result) {
          release();
          res.send(err || JSON.stringify(result.rows[0].id));
        }
      );
    }
  });
}