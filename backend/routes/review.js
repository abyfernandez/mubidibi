exports.review = app => {

  // Add Review

  app.post('/mubidibi/add-review/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    // catch apostrophes to avoid errors when inserting data
    var content = req.body.review.replace(/'/g, "''");

    console.log(req.body);

    // build query
    var query = `call add_review (
      ${parseInt(req.body.movie_id)},
      '${req.body.account_id}',
      ${req.body.rating == "null" ? 0.0 : parseFloat(req.body.rating)},
      '${content}'
    )`;

    console.log(query);

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      var review = await client.query(query, function onResult(err, result) {
        return (result);
      });

      release();
      res.send(err || JSON.stringify(review));
    }
  });
}