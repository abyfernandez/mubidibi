const { routes } = require('./routes');
const fastify = require('fastify');
const cors = require('fastify-cors');
const multipart = require('fastify-multipart');


exports.build = async (opts = { logger: false, trustProxy: false }) => {
  // initialize our server using Fastify
  const app = fastify(opts);

  // Connect to the Database
  // Localhost
  // app.register(require('fastify-postgres'), {
  //   connectionString: 'postgres://postgres:abifernandez@localhost/mubidibi'
  // });

  // Hosted DB
  app.register(require('fastify-postgres'), {
    connectionString: "postgres://czumbhipjpfuhk:66b0bc01e8323fa27f654ff6ee3580fb32993d043671166e08df10fe1762f045@ec2-34-193-112-164.compute-1.amazonaws.com:5432/d3nb9k1lnjdk3s",
    ssl: {
      rejectUnauthorized: false
    }
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