exports.user = app => {

  // GET USER
  app.get('/mubidibi/user/:id', (req, res) => {
    app.pg.connect(onConnect)
  
    function onConnect (err, client, release) {
      if (err) return res.send(err)
  
      client.query(
        "SELECT * FROM account WHERE id = $1", [req.params.id],
        function onResult (err, result) {
          release()
          res.send(err || JSON.stringify(result.rows[0]));
        }
      )
    }
  });

  // // ADD USER
  // app.post('/mubidibi/sign-up/', (res, res) => {
  //   app.pg.connect(onConnect);

  //   // var query = `call add_account(
      
  //   // )`
  // });
}


