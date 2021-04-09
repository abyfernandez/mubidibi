exports.crew = app => {

  // GET CREW
  app.get('/mubidibi/crew/', (req, res) => {
    app.pg.connect(onConnect)

    function onConnect(err, client, release) {
      if (err) return res.send(err)

      client.query(
        'SELECT * FROM crew',
        function onResult(err, result) {
          release()
          res.send(err || JSON.stringify(result.rows));
        }
      )
    }
  });

  // GET CREW BY MOVIE ID
  app.get('/mubidibi/crew/:id', (req, res) => {
    app.pg.connect(onConnect);

    async function onConnect(err, client, release) {
      if (err) return res.send(err)

      var crew = [];

      // DIRECTORS
      var director = await client.query(
        "SELECT * from crew where id in (SELECT director_id FROM movie_director where movie_id = $1)", [parseInt(req.params.id)]
      );

      var writer = await client.query(
        "SELECT * from crew where id in (SELECT writer_id FROM movie_writer where movie_id = $1)", [parseInt(req.params.id)]
      );

      var actor = await client.query(
        "SELECT crew.*, movie_actor.role from crew left join movie_actor on crew.id = movie_actor.actor_id where id in (SELECT actor_id FROM movie_actor where movie_id = $1)", [parseInt(req.params.id)]
      );

      crew.push(director.rows);
      crew.push(writer.rows);
      crew.push(actor.rows);

      release();
      res.send(err || JSON.stringify(crew));
      // res.send(err || crew);
    }
  });
}


