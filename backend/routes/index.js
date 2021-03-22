const { crew } = require('./crew');
const { movie } = require('./movie');
const { user } = require('./user');

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
  // Call Crew Routes
  crew(app);
  // Call User Routes
  user(app);
}
