exports.award = app => {

  // GET AWARDS FOR AWARDOPTIONS DROPDOWNS AND LIST VIEWS
  app.post('/mubidibi/all-awards/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      var query = "SELECT id, name, to_json(category), description, added_by, created_at, is_deleted from award where";

      if (req.body.user != 'admin' || req.body.mode == "form") {
        query = query.concat(" is_deleted = false");

        if (req.body.mode == "form") query = query.concat(` and '${req.body.category}' = ANY(category)`);
      } else {
        if (req.body.mode == "form") query = query.concat(` '${req.body.category}' = ANY(category)`);
      }

      console.log(query);

      client.query(
        query,
        async function onResult(err, result) {
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      )
    }
  });

  // GET AWARDS FOR MOVIE DETAIL VIEW
  app.post('/mubidibi/awards/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      var query = `SELECT award.id, award.name, to_json(award.category), award.created_at, award.description, award.added_by, award.is_deleted, m.type, m.year from award left join movie_award as m on m.award_id = award.id where movie_id = ${req.body.movie_id}`;
      if (req.body.user != "admin") query = query.concat(` and award.is_deleted = false`);

      client.query(
        query,
        async function onResult(err, result) {
          console.log(result);
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      )
    }
  });

  // GET AWARDS FOR CREW DETAIL VIEW
  app.post('/mubidibi/crew-awards/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      var query = `SELECT award.*, c.type, c.year from award left join crew_award as c on c.award_id = award.id where crew_id = ${req.body.crew_id}`;
      if (req.body.user != "admin") query = query.concat(` and award.is_deleted = false`);

      client.query(
        query,
        async function onResult(err, result) {
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      )
    }
  });

  // GET ONE AWARD
  app.post('/mubidibi/award/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        'SELECT * from award where id = $1', [req.body.award_id],
        function onResult(err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows[0]));
          else res.send(err);
        }
      )
    }
  });

  // ADD AWARD
  app.post('/mubidibi/add-award/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    // catch apostrophes to avoid errors when inserting data
    var name = req.body.name.replace(/'/g, "''");
    var description = req.body.description != "" ? req.body.description.replace(/'/g, "''") : null;

    // build query
    var query;

    // add award
    if (req.body.award_id == 0) {
      query = `select add_award (
          '${name}', 
          `;
      // check first if category array is empty or not
      if (req.body.category.length && req.body.category != null) {
        query = query.concat(`array [`)
        req.body.category.forEach(cat => {
          query = query.concat(`'`, cat == 'Pelikula' ? 'movie' : 'crew', `'`)
          if (cat != req.body.category[req.body.category.length - 1]) {
            query = query.concat(',')
          }
        });
        query = query.concat(`], 
      `)
      } else {
        query = query.concat(`null, 
      `);
      }

      // added_by
      query = query.concat(`'${req.body.added_by}',
      `);
      // description
      if (description != null) query = query.concat(`'${description}')
      `);
      else query = query.concat(`null 
      )`);
    } else {
      // update award
      query = `update award set name = '${name}', description = `;
      // description
      if (description != null) query = query.concat(`'${description}', `);
      else query = query.concat(`null, `);
      query = query.concat(`category = `)
      // check first if category array is empty or not
      if (req.body.category.length && req.body.category != null) {
        query = query.concat(`array [`)
        req.body.category.forEach(cat => {
          query = query.concat(`'`, cat == 'Pelikula' ? 'movie' : 'crew', `'`)
          if (cat != req.body.category[req.body.category.length - 1]) {
            query = query.concat(',')
          }
        });
        query = query.concat(`] `)
      } else {
        query = query.concat(`null `);
      }
      // award id
      query = query.concat(`where id = ${req.body.award_id} returning id as add_award`)
    }

    async function onConnect(err, client, release) {
      if (err) return res.send(err);
      var award = await client.query(query);

      release();
      res.send(err || JSON.stringify(award.rows[0].add_award));
    }
  });
}