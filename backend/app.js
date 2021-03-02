const { routes } = require('./routes');
const fastify = require('fastify');
const cors = require('fastify-cors');

exports.build = async (opts = { logger: false, trustProxy: false }) => {
  // initialize our server using Fastify
  const app = fastify(opts);

  // Connect to the Database
  app.register(require('fastify-postgres'), {
    connectionString: 'postgres://postgres:abifernandez@localhost/mubidibi'
    // TO DO: Create Config file
  });

  app.register(cors, {
    origin: true,
    credentials: true
  });

  // await connect();

  routes(app);

  return app;
};


/**
 * This is the function to call to initialize the server
 *
//  * @param {{ logger: boolean, trustProxy: boolean }} opts
//  * @returns {*}
//  */
// exports.build = async (opts = { logger: true, trustProxy: true }) => {
//   // initialize our server using Fastify
//   const app = fastify(opts);

//   routes(app);

//   return app;
// };