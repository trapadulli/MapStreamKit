const { createServer } = require('node:http');

const port = Number(process.env.PORT || 8080);

const server = createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
    return;
  }

  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(
    JSON.stringify({
      service: 'msk-head-puller',
      message: 'hello from Azure Container App',
      path: req.url,
      method: req.method,
    })
  );
});

server.listen(port, () => {
  console.log(`msk-head listening on :${port}`);
});
