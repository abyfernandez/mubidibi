const { routes } = require('./routes');
const fastify = require('fastify');
const cors = require('fastify-cors');
const multipart = require('fastify-multipart');

// // declare cloudinary
// const cloudinary = require('cloudinary').v2;
// // end of dependencies

exports.build = async (opts = { logger: false, trustProxy: false }) => {
  // initialize our server using Fastify
  const app = fastify(opts);

  // Connect to the Database
  app.register(require('fastify-postgres'), {
    connectionString: 'postgres://postgres:abifernandez@localhost/mubidibi'
  });

  // register multipart
  app.register(multipart, {
  });

  app.register(cors, {
    origin: true,
    credentials: true
  });

  routes(app);

  return app;
};