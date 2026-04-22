const http = require('http');
const server = http.createServer((req, res) => {
  res.writeHead(200);
  res.end('Hello from ECR + LocalStack!\n');
});
server.listen(3000, () => console.log('Running on port 3000'));
