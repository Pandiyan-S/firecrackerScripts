const http = require('http');

const server = http.createServer(function (req, res) {
  if (req.url === '/shutdown') {
    console.log('Received shutdown request');
    // Gracefully shutdown the server
    server.close(() => {
      console.log('Server has been gracefully shutdown');
      // Exit the process with a success code
      process.exit(0);
    });
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Shutting down server...');
  } else {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello World!');
  }
}).listen(8090);

process.on('SIGTERM', () => {
  console.log('Received SIGTERM signal');
  // Gracefully shutdown the server
  server.close(() => {
    console.log('Server has been gracefully shutdown');
    // Exit the process with a success code
    process.exit(0);
  });
});
