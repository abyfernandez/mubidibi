exports.user = app => {

  // GET USERS
  app.post('/mubidibi/users/', (req, res) => {
    app.pg.connect(onConnect)

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      var result = await client.query(
        `SELECT *, concat_ws(' ', first_name, middle_name, last_name, suffix) as name FROM account WHERE id != $1 order by name asc`, [req.body.user_id],
        function onResult(err, result) {
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      );
    }
  });

  // GET USER
  app.get('/mubidibi/user/:id', (req, res) => {
    app.pg.connect(onConnect)

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      var result = await client.query(
        "SELECT * FROM account WHERE id = $1", [req.params.id],
        function onResult(err, result) {
          release()
          res.send(err || JSON.stringify(result.rows[0]));
        }
      );
    }
  });

  // Update Admins
  app.post('/mubidibi/update-admins/', async (req, res) => {
    app.pg.connect(onConnect);

    var users = req.body.users;
    var changed = req.body.changed;

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      changed.forEach(i => {
        client.query(`UPDATE account SET is_admin = $1 WHERE id = $2`, [users[i].is_admin, users[i].id], function onResult(err, result) {
          if (err) res.send(err);
        });
      });
      release();
      res.code(200).send();
    }
  })

  // Add Account

  app.post('/mubidibi/sign-up/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    // catch apostrophes to avoid errors when inserting data
    var first_name = req.body.firstName.replace(/'/g, "''");
    var middle_name = req.body.middleName != null || req.body.middleName != "" ? req.body.middleName.replace(/'/g, "''") : '';
    var last_name = req.body.lastName.replace(/'/g, "''");
    var suffix = req.body.suffix != null || req.body.suffix != "" ? req.body.suffix.replace(/'/g, "''") : '';

    // build query
    var query = `call add_account (
    '${req.body.userId}',
    '${first_name}',
    `;

    // if birthday is not required
    if (req.body.birthday != null) {
      query = query.concat(`'${req.body.birthday}', `);
    } else {
      query = query.concat(`null, `);
    }

    // query = query.concat(`'${req.body.birthday}',
    // `);  // if birthday is required

    query = query.concat(`_middle_name => `);

    if (middle_name != '') {
      query = query.concat(`'${middle_name}',
      `);
    } else {
      query = query.concat(`null,
      `);
    }

    query = query.concat(`_last_name => '${last_name}', 
    _suffix => `);

    if (suffix != '') {
      query = query.concat(`'${suffix}'
      )`);
    } else {
      query = query.concat(`null
      )`);
    }

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      var result = await client.query(query, function onResult(err, result) {

        return (err || result);
      });

      release();
      res.send(err || JSON.stringify(result));
    }
  });
}


