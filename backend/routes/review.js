exports.review = app => {

  // Get All Reviews

  app.post('/mubidibi/movie-reviews/', async (req, res) => {
    app.pg.connect(onConnect);

    async function onConnect(err, client, release) {

      const { rows } = await client.query("SELECT review.*, account.first_name, account.middle_name, account.last_name, account.suffix FROM review LEFT JOIN account ON review.account_id = account.id WHERE review.movie_id = $1 ORDER BY review.created_at desc", [parseInt(req.body.movie_id)]);

      // iterate over the reviews and count the numbers of total votes (upvotes and downvotes)
      for (var i = 0; i < rows.length; i++) {
        var rev_id = rows[i].id;
        var upvote_count = await client.query(`select count(*) as upvote_count from review_vote where review_id = $1 and upvote = true`, [rev_id]);

        var downvote_count = await client.query(`select count(*) as downvote_count from review_vote where review_id = $1 and upvote = false`, [rev_id]);


        rows[i]['upvote_count'] = parseInt(upvote_count.rows[0].upvote_count);
        rows[i]['downvote_count'] = parseInt(downvote_count.rows[0].downvote_count);

        // get vote from current user 
        var vote = await client.query(`select upvote from review_vote where account_id = $1 and review_id = $2`, [req.body.account_id, rows[i].id]);
        rows[i]['upvoted'] = vote.rows && vote.rows.length ? vote.rows[0].upvote : null;
      }

      release();
      res.send(err || JSON.stringify(rows));
    }
  });


  // GET ONE Review
  app.post('/mubidibi/review/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        'SELECT review.*, account.first_name, account.middle_name, account.last_name, account.suffix FROM review LEFT JOIN account ON review.account_id = account.id WHERE review.account_id = $1 and review.movie_id = $2', [req.body.account_id, req.body.movie_id],
        function onResult(err, result) {
          release()
          if (result) res.send(JSON.stringify(result.rows[0]));
          else res.send(err);
        }
      )
    }
  });

  // Add Review

  app.post('/mubidibi/add-review/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    // catch apostrophes to avoid errors when inserting data
    var content = req.body.review.replace(/'/g, "''");

    // build query
    var query;

    console.log(req.body);

    if (req.body.review_id == 0) {
      query = `call add_review (
        ${parseInt(req.body.movie_id)},
        '${req.body.account_id}',
        ${req.body.rating == "null" || req.body.rating == 0 ? 0.00 : parseFloat(req.body.rating).toFixed(2)},
        '${content}'
      )`;
    }

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      var reviews;
      if (req.body.review_id == 0) {
        reviews = await client.query(query);
      } else {
        reviews = await client.query(`update review set rating = $1, review = $2 where id = $3`, [req.body.rating == "null" || req.body.rating == 0 ? 0.00 : parseFloat(req.body.rating).toFixed(2), req.body.review, req.body.review_id]);
      }
      release();
      res.send(err || JSON.stringify(reviews));
    }
  });

  // delete review 
  app.delete('/mubidibi/delete-review/:id', async (req, res) => {
    app.pg.connect(onConnect);

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      console.log(req.params);

      await client.query('delete from review where id = $1 returning id', [parseInt(req.params.id)], function onResult(err, result) {
        release();
        res.send(err || JSON.stringify(result.rows[0].id));
      });
    }
  });

  // Vote function
  app.post('/mubidibi/vote/', async (req, res) => {
    app.pg.connect(onConnect); // DB Connection

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      // Vote
      if (req.body.type == 'insert') {
        await client.query(`insert into review_vote (review_id, account_id, upvote) values ($1, $2, $3)`, [parseInt(req.body.review_id), req.body.account_id, req.body.upvote]);
      } else if (req.body.type == "update") {
        await client.query(`update review_vote set upvote = $1 where review_id = $2 and account_id = $3 and upvote = $4`, [req.body.upvote, parseInt(req.body.review_id), req.body.account_id, !req.body.upvote]);
      } else if (req.body.type == "delete") {
        await client.query(`delete from review_vote where review_id = $1 and account_id = $2`, [parseInt(req.body.review_id), req.body.account_id]);
      }

      // fetch reviews again
      const { rows } = await client.query("SELECT review.*, account.first_name, account.middle_name, account.last_name, account.suffix FROM review LEFT JOIN account ON review.account_id = account.id WHERE review.movie_id = $1 ORDER BY review.created_at", [parseInt(req.body.movie_id)]);

      // iterate over the reviews and count the numbers of total votes (upvotes and downvotes)
      for (var i = 0; i < rows.length; i++) {
        var rev_id = rows[i].id;
        var upvote_count = await client.query(`select count(*) as upvote_count from review_vote where review_id = $1 and upvote = true`, [rev_id]);
        var downvote_count = await client.query(`select count(*) as downvote_count from review_vote where review_id = $1 and upvote = false`, [rev_id]);

        rows[i]['upvote_count'] = parseInt(upvote_count.rows[0].upvote_count);
        rows[i]['downvote_count'] = parseInt(downvote_count.rows[0].downvote_count);

        // get vote from current user 
        var vote = await client.query(`select upvote from review_vote where account_id = $1 and review_id = $2`, [req.body.account_id, rows[i].id]);
        rows[i]['upvoted'] = vote.rows && vote.rows.length ? vote.rows[0].upvote : null;

      }
      release();
      res.send(err || JSON.stringify(rows));
    }
  });

  // change review status 
  app.post('/mubidibi/change-status/:id', async (req, res) => {
    app.pg.connect(onConnect);

    async function onConnect(err, client, release) {
      if (err) return res.send(err);

      await client.query('update review set is_approved = $1 where id = $2 returning id', [req.body.status, req.body.id], function onResult(err, result) {
        console.log(result.rows);
        release();
        res.send(err || JSON.stringify(result.rows[0].id));
      });
    }
  });
}