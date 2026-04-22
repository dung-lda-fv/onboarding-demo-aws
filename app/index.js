const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200);
  res.end('v3 from GitHub Actions!\n');
});
server.listen(3000, () => console.log('Running on port 3000'));
