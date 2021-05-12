const { crew } = require('./crew');
const { movie } = require('./movie');
const { user } = require('./user');
const { review } = require('./review');

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


  var cloudinary = require('cloudinary');

  cloudinary.config({
    cloud_name: "mubidibi-sp",
    api_key: '385294841727974',
    api_secret: 'ci9a7ntqqXuKt-6vlfpw5qk8Q5E',
  });

  // Call User Routes 
  // user(app);

  // Call Movie Routes
  movie(app, cloudinary);
  // Call Crew Routes
  crew(app, cloudinary);
  // Call User Routes
  user(app, cloudinary);
  // Call Review Routes
  review(app, cloudinary);
}
