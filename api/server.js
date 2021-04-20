const express = require('express')
const app = express()
const port = 3000
const fs = require('fs');
const path = require('path');

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.get('/styles.json', (req, res) => {
    console.log('fetching styles')
    fs.readFile(path.join(process.cwd(), './styles.json'), (err, data) => {
        res.send(data);
    });
})

app.get('/tiles/:z/:x/:y', (req, res) => {
    console.log('fetching tile', req.params.z, req.params.x, req.params.y)
    // console.log(req.headers)
    fs.readFile(path.join(process.cwd(), './sample-tile'), (err, data) => {
        // res.set('Cache-control', 'private, max-age=31536000') // one year, invalidate manually
        res.set('Cache-control', 'private, max-age=0') // reduce to nothing to remove variable
        res.send(data);
        // console.log(res.getHeaders())
    });
})

app.listen(port, () => {
  console.log(`listening at http://localhost:${port}`)
})