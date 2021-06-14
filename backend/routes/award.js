exports.award = app => {

  // GET AWARDS FOR AWARDOPTIONS DROPDOWNS AND LIST VIEWS
  app.post('/mubidibi/all-awards/', (req, res) => {
    app.pg.connect(onConnect)

    console.log(req.body);

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      var query = "SELECT id, name, event, to_json(category) as category, description, added_by, created_at, is_deleted from award";

      if (req.body.user != 'admin' || req.body.mode == "form") {
        query = query.concat(" where is_deleted = false");

        if (req.body.mode == "form") query = query.concat(` and category @> array['${req.body.category}']::award_category[]`);
      }

      query = query.concat(` order by name`);

      client.query(
        query,
        async function onResult(err, result) {
          console.log(result.rows);
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

      var query = `SELECT award.id, award.name, to_json(award.category) as category, award.event, award.created_at, award.description, award.added_by, award.is_deleted, m.id as award_id, m.movie_id, to_json(m.type) as type, m.year from award left join movie_award as m on m.award_id = award.id where movie_id = ${req.body.movie_id}`;
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

  // GET AWARDS FOR CREW DETAIL VIEW
  app.post('/mubidibi/crew-awards/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      var query = `SELECT award.id, award.name, to_json(award.category) as category, award.event, award.created_at, award.description, award.added_by, award.is_deleted, to_json(c.type) as type, c.award_id, c.crew_id, c.year from award left join crew_award as c on c.award_id = award.id where crew_id = ${req.body.crew_id}`;
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
    var event = req.body.event.replace(/'/g, "''");
    var description = req.body.description != "" ? req.body.description.replace(/'/g, "''") : null;

    // build query
    var query;

    // add award
    query = `select add_award (
          '${name}', 
          '${event}',
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
      query = query.concat(`]
      `)
      query = query.concat(`::award_category[],`)
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

    async function onConnect(err, client, release) {
      if (err) return res.send(err);
      console.log(query);
      var award = await client.query(query);

      release();
      res.send(err || JSON.stringify(award.rows[0].add_award));
    }
  });

  // UPDATE AWARD
  app.put('/mubidibi/update-award/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    // catch apostrophes to avoid errors when inserting data
    var name = req.body.name.replace(/'/g, "''");
    var event = req.body.event.replace(/'/g, "''");
    var description = req.body.description != "" ? req.body.description.replace(/'/g, "''") : null;

    // build query
    var query = `update award set name = '${name}', event = '${event}', description = `;
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
      query = query.concat(`]::award_category[] `)
    } else {
      query = query.concat(`null `);
    }
    // award id
    query = query.concat(`where id = ${req.body.award_id} returning id`)

    async function onConnect(err, client, release) {
      if (err) return res.send(err);
      var award = await client.query(query);

      release();
      res.send(err || JSON.stringify(award.rows[0].id));
    }
  });

  // DELETE AWARD
  app.get('/mubidibi/delete-award/:id', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    async function onConnect(err, client, release) {
      if (err) return res.send(err);
      var { rows } = await client.query(`update award set is_deleted = true where id = ${parseInt(req.params.id)} returning id`);

      release();
      res.send(err || JSON.stringify(rows[0].id));
    }
  });

  // RESTORE AWARD
  app.get('/mubidibi/restore-award/:id', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    async function onConnect(err, client, release) {
      if (err) return res.send(err);
      var { rows } = await client.query(`update award set is_deleted = false where id = ${parseInt(req.params.id)} returning id`);

      release();
      res.send(err || JSON.stringify(rows[0].id));
    }
  });

}