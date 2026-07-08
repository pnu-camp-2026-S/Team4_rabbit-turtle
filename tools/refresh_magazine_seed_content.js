const fs = require("fs");
const path = require("path");

const seedPath = path.join(__dirname, "firestore_magazine_seed.json");
const seed = JSON.parse(fs.readFileSync(seedPath, "utf8"));

const coverUrls = {
  "demo-cereal":
    "https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80",
  "demo-kindred-rooms":
    "https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=900&q=80",
  "demo-room-note":
    "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80",
  "demo-ark-journal":
    "https://images.unsplash.com/photo-1511818966892-d7d671e672a2?auto=format&fit=crop&w=900&q=80",
  "demo-drift":
    "https://images.unsplash.com/photo-1442512595331-e89e73853f31?auto=format&fit=crop&w=900&q=80",
  "demo-the-gourmand":
    "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=900&q=80",
  "demo-fantastic-man":
    "https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=900&q=80",
  "demo-wax-poetics":
    "https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=900&q=80",
  "demo-openhouse":
    "https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=901&q=80",
  "demo-frieze":
    "https://images.unsplash.com/photo-1531058020387-3be344556be6?auto=format&fit=crop&w=900&q=80",
  "demo-suitcase":
    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80",
  "demo-hanok-life":
    "https://images.unsplash.com/photo-1538485399081-7c8edb4f45e3?auto=format&fit=crop&w=900&q=80",
  "demo-stadium-field":
    "https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?auto=format&fit=crop&w=900&q=80",
  "demo-run-log":
    "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=900&q=80",
  "demo-craft-index":
    "https://images.unsplash.com/photo-1452860606245-08befc0ff44b?auto=format&fit=crop&w=900&q=80",
  "demo-garden-edit":
    "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?auto=format&fit=crop&w=900&q=80",
  "demo-bookshop-map":
    "https://images.unsplash.com/photo-1526243741027-444d633d7365?auto=format&fit=crop&w=900&q=80",
  "demo-vinyl-night":
    "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=900&q=80",
  "demo-bakery-letters":
    "https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=80",
  "demo-local-table":
    "https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=900&q=80",
  "demo-hotel-note":
    "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=900&q=80",
  "demo-city-walks":
    "https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=900&q=80",
  "demo-artfair-week":
    "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=900&q=80",
  "demo-yoga-paper":
    "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=900&q=80",
};

const angles = {
  "demo-cereal": {
    place: "a narrow studio apartment above a quiet shopping street",
    object: "a pale desk, a travel notebook, and a camera with the strap still twisted from the morning",
    rhythm: "edited, bright, and deliberately slow",
    question: "how little a place needs before it begins to feel complete",
  },
  "demo-kindred-rooms": {
    place: "a lived-in room where the curtain moves before anyone speaks",
    object: "linen cushions, a low shelf, and a cup left near a sun patch",
    rhythm: "soft, domestic, and unhurried",
    question: "what makes an ordinary room generous",
  },
  "demo-room-note": {
    place: "a small furniture workshop at the back of an old building",
    object: "oak dust, paper patterns, and a chair waiting for its final coat of oil",
    rhythm: "tactile, patient, and close to the hand",
    question: "why some objects feel like they have already learned us",
  },
  "demo-ark-journal": {
    place: "a concrete house where the stairwell catches afternoon light",
    object: "a brass handle, a stone threshold, and the long shadow of a window frame",
    rhythm: "architectural, restrained, and spacious",
    question: "how buildings teach the body to pause",
  },
  "demo-drift": {
    place: "a cafe corner in a city that wakes slowly",
    object: "a ceramic cup, a receipt folded into a bookmark, and steam on the glass",
    rhythm: "observant, caffeinated, and lightly urban",
    question: "how a cup can become a map of a neighborhood",
  },
  "demo-the-gourmand": {
    place: "a lunch table arranged like a small exhibition",
    object: "cream, citrus peel, a fork mark, and a napkin folded with unnecessary care",
    rhythm: "sensory, witty, and slightly theatrical",
    question: "where appetite ends and looking begins",
  },
  "demo-fantastic-man": {
    place: "a morning wardrobe edited down to confident essentials",
    object: "a navy coat, a clean sneaker, and a shirt that looks better after movement",
    rhythm: "sharp, plainspoken, and quietly stylish",
    question: "how clothes can say less and still say enough",
  },
  "demo-wax-poetics": {
    place: "a basement listening room where the lamp is lower than the turntable",
    object: "a purple sleeve, a needle brush, and records filed by memory rather than alphabet",
    rhythm: "warm, analog, and nocturnal",
    question: "why returning to a record feels different from replaying a file",
  },
  "demo-openhouse": {
    place: "a cultural room with books near the door and chairs placed for lingering",
    object: "a gallery bench, a shelf label, and a postcard pinned behind the counter",
    rhythm: "public, welcoming, and quietly curated",
    question: "how a space becomes an invitation",
  },
  "demo-frieze": {
    place: "a white room where the crowd becomes part of the exhibition",
    object: "wall text, polished concrete, and the pause before someone photographs a painting",
    rhythm: "critical, visual, and alert",
    question: "what remains after the artwork leaves the wall",
  },
  "demo-suitcase": {
    place: "a hotel window above a street that refuses to become familiar too quickly",
    object: "a room key, a folded map, and shoes carrying dust from three neighborhoods",
    rhythm: "curious, light-packed, and open-ended",
    question: "how travel changes when the schedule loosens",
  },
  "demo-hanok-life": {
    place: "a wooden room where paper doors hold the afternoon softly",
    object: "a tea tray, a low cushion, and the line where shadow meets the floor",
    rhythm: "traditional, quiet, and deeply paced",
    question: "how old materials can make the present gentler",
  },
  "demo-stadium-field": {
    place: "a stadium concourse just before the first chant gathers",
    object: "green turf, a scarf, and a paper cup balanced on a concrete ledge",
    rhythm: "collective, bright, and full of anticipation",
    question: "where the match begins before the whistle",
  },
  "demo-run-log": {
    place: "a riverside path before the city decides to be loud",
    object: "watch data, worn soles, and a bottle sweating in the first sun",
    rhythm: "measured, bodily, and clean",
    question: "how movement turns a route into memory",
  },
  "demo-craft-index": {
    place: "a market table where handmade things keep their small irregularities",
    object: "glaze, woven thread, and price tags written with a careful pen",
    rhythm: "collected, tactile, and warmly imperfect",
    question: "why the hand still matters in an object",
  },
  "demo-garden-edit": {
    place: "a garden path where leaves make the room instead of walls",
    object: "wet soil, pruning shears, and a bench placed exactly where shade arrives",
    rhythm: "green, restorative, and weather-aware",
    question: "how rest changes when it is grown rather than designed",
  },
  "demo-bookshop-map": {
    place: "a neighborhood bookshop with a bell that sounds smaller than the room",
    object: "paperbacks, a handwritten shelf card, and a tote bag waiting by the counter",
    rhythm: "bookish, local, and quietly sociable",
    question: "how a shop can become a map for attention",
  },
  "demo-vinyl-night": {
    place: "a listening bar where the first track changes the size of the evening",
    object: "black vinyl, a blue lamp, and glasses set down between bass lines",
    rhythm: "intimate, rhythmic, and late",
    question: "what makes a room listen together",
  },
  "demo-bakery-letters": {
    place: "a bakery counter where the morning is written in butter",
    object: "flour on an apron, a tray of croissants, and boxes tied for people not yet awake",
    rhythm: "warm, fragrant, and tender",
    question: "why sweetness often feels like a reason to stop",
  },
  "demo-local-table": {
    place: "a small restaurant where the second visit already feels recognized",
    object: "metal chopsticks, handwritten specials, and a dish placed down without performance",
    rhythm: "local, generous, and appetite-led",
    question: "how a table can explain a street",
  },
  "demo-hotel-note": {
    place: "a quiet hotel room where the first act is putting the bag down",
    object: "linen, a reading lamp, and a curtain heavy enough to change the hour",
    rhythm: "composed, restful, and well-held",
    question: "what makes a stay feel like permission",
  },
  "demo-city-walks": {
    place: "a side street where the city becomes legible in fragments",
    object: "signboards, crosswalk light, and a bakery window reflected in a bus stop",
    rhythm: "wandering, observant, and lightly cinematic",
    question: "why the best route is often the one that was not planned",
  },
  "demo-artfair-week": {
    place: "a temporary booth where collectors, students, and tired gallerists share the same light",
    object: "catalogues, tape marks on the floor, and a sculpture that changes with each angle",
    rhythm: "busy, visual, and full of quick decisions",
    question: "how taste appears before explanation",
  },
  "demo-yoga-paper": {
    place: "a calm studio where mats line up like a private calendar",
    object: "a cork block, a folded towel, and breath fogging the edge of the mirror",
    rhythm: "steady, quiet, and embodied",
    question: "how repetition becomes a form of care",
  },
};

function expandedParagraphs(magazine) {
  const article = magazine.articles[0];
  const tags = magazine.tags;
  const angle = angles[magazine.id];
  if (!angle) return article.paragraphs;

  const intro = article.paragraphs.slice(0, 3);
  return [
    ...intro,
    [
      `The story begins in ${angle.place}.`,
      `Its mood is ${angle.rhythm}, shaped less by spectacle than by attention.`,
    ],
    [
      `We kept returning to ${angle.object}.`,
      `Those details made ${article.title} feel specific to ${magazine.title}, not interchangeable with any other issue.`,
    ],
    [
      `${tags[0]} is the first signal, but it is not the whole subject.`,
      `${tags.slice(1).join(" and ")} give the article its second and third doors.`,
    ],
    [
      `There is a practical pleasure in the piece: it notices scale, timing, and texture before it reaches for a conclusion.`,
      `The writing stays close enough to the scene that the reader can almost arrange the objects again.`,
    ],
    [
      `Halfway through, the issue asks ${angle.question}.`,
      `The answer is not declared; it accumulates through small choices, one paragraph at a time.`,
    ],
    [
      `By the end, ${magazine.title} feels like a recommendation you can use rather than a mood you only admire.`,
      `It leaves behind a clear desire: to look longer, choose better, and make room for the kind of taste that lasts.`,
    ],
  ];
}

for (const magazine of seed.magazines) {
  if (coverUrls[magazine.id]) magazine.coverUrl = coverUrls[magazine.id];
  if (magazine.articles?.[0]) {
    magazine.articles[0].paragraphs = expandedParagraphs(magazine);
    magazine.articles[0].pageCount = Math.max(16, magazine.articles[0].paragraphs.length + 8);
  }
}

fs.writeFileSync(seedPath, `${JSON.stringify(seed, null, 2)}\n`, "utf8");

const covers = new Set(seed.magazines.map((magazine) => magazine.coverUrl));
console.log(`updated magazines=${seed.magazines.length}`);
console.log(`unique covers=${covers.size}`);
console.log(`paragraphs=${seed.magazines.map((m) => m.articles[0].paragraphs.length).join(",")}`);
