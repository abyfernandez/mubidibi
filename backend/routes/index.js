const { user } = require('./movie');
const { movie } = require('./movie');

// Initialize all Routes

exports.routes = app => {

  // access root address - http://localhost/
  app.get('/', {
    /**
     * handles the request for a given route
     */
    handler: async (req) => {
      // this is the response in JSON format
      return { success: true }
    }
  });

  // Call User Routes 
  // user(app);

  // Call Movie Routes
  movie(app);
}
