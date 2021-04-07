exports.review = app => {

  // Get All Reviews

  app.get('/mubidibi/reviews/:movie_id', async (req, res) => {
    app.pg.connect(onConnect);

    console.log(req.params.movie_id, typeof (req.params.movie_id, parseInt(req.params.movie_id)))

    async function onConnect(err, client, release) {
      const { rows } = await client.query("SELECT movie_review.*, account.prefix, account.first_name, account.middle_name, account.last_name, account.suffix FROM movie_review LEFT JOIN account ON movie_review.account_id = account.id WHERE movie_review.movie_id = $1 ORDER BY movie_review.created_at DESC", [parseInt(req.params.movie_id)]);
      release();
      res.send(err || JSON.stringify(rows));
    }
  });

  // Add Review

  app.post('/mubidibi/add-review/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    // catch apostrophes to avoid errors when inserting data
    var content = req.body.review.replace(/'/g, "''");

    // build query
    var query = `call add_review (
      ${parseInt(req.body.movie_id)},
      '${req.body.account_id}',
      ${req.body.rating == "null" ? 0.00 : parseFloat(req.body.rating).toFixed(2)},
      '${content}'
    )`;

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      var reviews = await client.query(query, function onResult(err, result) {

        // get all reviews and return as list
        // var reviews = await client
        return (result);
      });

      release();
      res.send(err || JSON.stringify(review));
    }
  });
}