const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Sample initial data
let things = [
  { id: 1, name: 'Learn Docker', completed: false },
  { id: 2, name: 'Build a UI', completed: false },
  { id: 3, name: 'Deploy app', completed: false }
];

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Set view engine
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// Routes
app.get('/', (req, res) => {
  res.render('index', { things });
});

app.post('/things', (req, res) => {
  const newThing = {
    id: things.length + 1,
    name: req.body.name,
    completed: false
  };
  things.push(newThing);
  res.redirect('/');
});

app.post('/things/:id/complete', (req, res) => {
  const id = parseInt(req.params.id);
  const thing = things.find(t => t.id === id);
  if (thing) {
    thing.completed = !thing.completed;
  }
  res.redirect('/');
});

app.post('/things/:id/delete', (req, res) => {
  const id = parseInt(req.params.id);
  things = things.filter(t => t.id !== id);
  res.redirect('/');
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});


