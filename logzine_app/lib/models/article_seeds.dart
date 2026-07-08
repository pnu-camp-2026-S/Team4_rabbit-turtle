/// 매거진별 아티클 시드 콘텐츠.
/// MagazineService.syncArticles()가 아티클이 없는 매거진에 1편씩 입력한다.
/// key = 매거진 title (kMagazines와 동일해야 매칭됨).
class ArticleSeed {
  const ArticleSeed({
    required this.title,
    required this.pageCount,
    required this.paragraphs,
  });

  final String title;
  final int pageCount;

  /// 문단 → 문장 조각(segment). 리더의 하이라이트 좌표 체계와 1:1.
  final List<List<String>> paragraphs;
}

/// 매거진별 2호 아티클 — syncArticles가 1호에 이어 추가한다.
const Map<String, ArticleSeed> kSecondArticleSeeds = {
  'CEREAL': ArticleSeed(
    title: 'White Space',
    pageCount: 8,
    paragraphs: [
      [
        'A photograph is mostly decisions about what to leave out.',
        'The empty half of the frame is doing the heavy lifting.',
      ],
      [
        'We printed this issue with wider margins than usual.',
        'Notice how the pictures breathe differently.',
      ],
      [
        'White space is not absence.',
        'It is the room a thought needs to finish itself.',
      ],
    ],
  ),
  'KINFOLK': ArticleSeed(
    title: 'The Guest Table',
    pageCount: 8,
    paragraphs: [
      [
        'Hospitality is not a performance of abundance.',
        'One pot, mismatched chairs, and enough time.',
      ],
      [
        'The best dinner parties we attended this year',
        'served one dish and three hours of conversation.',
      ],
      [
        'Set the table like you mean it, then relax completely.',
        'Guests remember warmth, not symmetry.',
      ],
    ],
  ),
  'ROOM NOTE': ArticleSeed(
    title: 'One Lamp, Late Evening',
    pageCount: 8,
    paragraphs: [
      [
        'Overhead light flattens a room into a diagram.',
        'One low lamp turns it back into a place.',
      ],
      [
        'Light the corner, not the ceiling.',
        'Shadows are furniture too.',
      ],
      [
        'The evening room should be dimmer than your phone.',
        'That is the whole trick of rest.',
      ],
    ],
  ),
  'ARK JOURNAL': ArticleSeed(
    title: 'Concrete, Softly',
    pageCount: 8,
    paragraphs: [
      [
        'Concrete has a reputation problem and a light problem.',
        'Solve the second and the first disappears.',
      ],
      [
        'In the Jutland house we visited, morning sun',
        'turns the grey walls the color of warm paper.',
      ],
      [
        'Brutal is a choice, not a material.',
        'Handled gently, concrete is just stone that listened.',
      ],
    ],
  ),
  'apartamento': ArticleSeed(
    title: 'Plants of the Stairwell',
    pageCount: 8,
    paragraphs: [
      [
        'Nobody owns the stairwell monstera, and everybody waters it.',
        'It is the healthiest plant in the building.',
      ],
      [
        'Shared spaces collect quiet agreements like this —',
        'unwritten, unspoken, faithfully kept.',
      ],
      [
        'A building becomes a neighborhood',
        'one communal plant at a time.',
      ],
    ],
  ),
  'Drift': ArticleSeed(
    title: "The Roaster's Notebook",
    pageCount: 8,
    paragraphs: [
      [
        'Every roaster keeps a notebook they show no one.',
        'Temperatures, timings, and small confessions.',
      ],
      [
        'Page 40: the batch that tasted like plum by accident.',
        'Three years chasing that accident since.',
      ],
      [
        'Craft is mostly documentation of luck,',
        'repeated until it stops being luck.',
      ],
    ],
  ),
  'The Gourmand': ArticleSeed(
    title: 'Butter, A Love Letter',
    pageCount: 8,
    paragraphs: [
      [
        'Every cuisine has a fat it trusts with its secrets.',
        'Ours writes them in butter.',
      ],
      [
        'Cold from the fridge it is a brick of patience.',
        'At room temperature, a spreadable apology.',
      ],
      [
        'Margarine was an era, not an ingredient.',
        'We have apologized and moved on.',
      ],
    ],
  ),
  'Fantastic Man': ArticleSeed(
    title: 'The Grey Coat Diaries',
    pageCount: 8,
    paragraphs: [
      [
        'The coat is eleven years old and has outlived four phones.',
        'The elbows are going; the intention is intact.',
      ],
      [
        'Repair is the most personal form of styling.',
        'Every mend is a decision to continue.',
      ],
      [
        'Buy less, choose slower, tailor everything.',
        'A wardrobe should age like a friendship.',
      ],
    ],
  ),
  'Wax Poetics': ArticleSeed(
    title: 'B-Sides Forever',
    pageCount: 8,
    paragraphs: [
      [
        'The A-side is what the label believed in.',
        'The B-side is what the band believed in.',
      ],
      [
        'Flip the record. The hit fades,',
        'and something stranger and truer begins.',
      ],
      [
        'Taste is built on B-sides —',
        'the things you love without being told to.',
      ],
    ],
  ),
  'Openhouse': ArticleSeed(
    title: 'A Studio Visit',
    pageCount: 8,
    paragraphs: [
      [
        "The ceramicist's studio smells like rain that never left.",
        'Shelves of failures she refuses to throw away.',
      ],
      [
        'Ask about the cracked bowl and she smiles:',
        'that one taught the glaze everything.',
      ],
      [
        'Workplaces reveal more than homes.',
        'This is where the choosing happens.',
      ],
    ],
  ),
  'Frieze': ArticleSeed(
    title: 'Notes from the Biennale',
    pageCount: 8,
    paragraphs: [
      [
        'Everyone photographs the mirrored room.',
        'The quiet drawings next door go home unphotographed and unforgotten.',
      ],
      [
        'Art fairs measure attention; art measures return visits.',
        'We went back to the drawings twice.',
      ],
      [
        'The best work this year asked for nothing',
        'and received everything we had left.',
      ],
    ],
  ),
  'SUITCASE': ArticleSeed(
    title: 'Airport Mornings',
    pageCount: 8,
    paragraphs: [
      [
        'The airport at 6am is a city of temporary residents,',
        'every one of them between two versions of themselves.',
      ],
      [
        'Drink the bad coffee. Watch the boards flip.',
        'Nowhere else is waiting this honest.',
      ],
      [
        'Departure lounges are the last shared rooms',
        'where strangers still dream in the same direction.',
      ],
    ],
  ),
};

const Map<String, ArticleSeed> kArticleSeeds = {
  'CEREAL': ArticleSeed(
    title: 'The Essential Few',
    pageCount: 12,
    paragraphs: [
      [
        'To travel light is not to carry less,',
        'but to know exactly what you cannot leave behind.',
      ],
      [
        'A single well-made bag, one camera, two rolls of film.',
        'The discipline of few things sharpens the eye for everything else.',
      ],
      [
        'Cities reveal themselves to the unhurried.',
        'The essential few are not objects at all, but hours kept empty on purpose.',
      ],
      [
        'We came home with fewer photographs and better ones.',
        'Less, chosen well, was the whole trip.',
      ],
    ],
  ),
  'KINFOLK': ArticleSeed(
    title: 'A Slower Morning',
    pageCount: 10,
    paragraphs: [
      [
        'The first hour of the day decides the texture of the rest.',
        'We asked five households to describe their mornings in one word.',
      ],
      [
        'Bread warming, a kettle ticking toward boil,',
        'light moving slowly across an unhurried table.',
      ],
      [
        'None of them mentioned their phones.',
        'All of them mentioned a window.',
      ],
      [
        'A slower morning is not found time but made time —',
        'a small ceremony that belongs entirely to you.',
      ],
    ],
  ),
  'ROOM NOTE': ArticleSeed(
    title: 'Things That Stay',
    pageCount: 12,
    paragraphs: [
      [
        'Some objects pass through a home; others settle into it.',
        'The difference is rarely price and almost always care.',
      ],
      [
        'A chair repaired twice keeps the memory of both repairs.',
        'Wood, stone, linen — honest materials age into companions.',
      ],
      [
        'When choosing, ask not "do I want this today"',
        'but "will I still be mending this in ten years."',
      ],
      [
        'A quiet room is built from things that stay.',
        'Everything else is just passing through.',
      ],
    ],
  ),
  'ARK JOURNAL': ArticleSeed(
    title: 'Architecture of the Everyday',
    pageCount: 14,
    paragraphs: [
      [
        'We photograph monuments and live in hallways.',
        'The truest architecture is the one we stop noticing.',
      ],
      [
        'A stair that turns at the right height,',
        'a doorway that frames the garden without meaning to.',
      ],
      [
        'The Danish houses in this issue were not designed to impress.',
        'They were designed to be Tuesday, over and over, beautifully.',
      ],
      [
        'Look again at your own rooms.',
        'The everyday is a building too.',
      ],
    ],
  ),
  'apartamento': ArticleSeed(
    title: 'A Kitchen That Remembers',
    pageCount: 10,
    paragraphs: [
      [
        'No one ever apologizes for the state of a beautiful kitchen.',
        'They apologize for the lived-in ones — which are better.',
      ],
      [
        'Ana has cooked in this four-square-meter kitchen for thirty years.',
        'The dent in the counter is from her daughter learning to juice oranges.',
      ],
      [
        'Interiors magazines photograph kitchens empty.',
        'This one only makes sense full: steam, radio, argument, laughter.',
      ],
      [
        'A home is not a set. It is a recording.',
        'Small spaces simply record more densely.',
      ],
    ],
  ),
  'Drift': ArticleSeed(
    title: 'Coffee at Street Level',
    pageCount: 12,
    paragraphs: [
      [
        'Every city has an official map and a coffee map.',
        'Only one of them tells you where people actually live.',
      ],
      [
        'In Eulji-ro, the best cup hides behind a hardware store,',
        'served by a roaster who used to weld for a living.',
      ],
      [
        'Ask for the same drink three days in a row.',
        'On the third day you are not a tourist anymore.',
      ],
      [
        'Coffee is the cheapest ticket to a neighborhood’s real life.',
        'Drink it standing, at street level.',
      ],
    ],
  ),
  'The Gourmand': ArticleSeed(
    title: 'Still Life, Served',
    pageCount: 12,
    paragraphs: [
      [
        'A dinner table is a painting that eats itself.',
        'The Dutch masters knew: arrange the fruit, then let it rot gloriously.',
      ],
      [
        'This issue we set one table five ways —',
        'brutalist, baroque, borrowed, broke, and breakfast.',
      ],
      [
        'Food styling is honest exactly once per dish:',
        'the moment someone reaches in and ruins the composition.',
      ],
      [
        'Cook for the painting if you like.',
        'Serve for the ruin.',
      ],
    ],
  ),
  'Fantastic Man': ArticleSeed(
    title: 'Notes on a Uniform',
    pageCount: 10,
    paragraphs: [
      [
        'The best-dressed men we know wear the same thing every day.',
        'This is not laziness; it is a settled argument.',
      ],
      [
        'A uniform is a decision made once, beautifully,',
        'so that every morning after is free for better decisions.',
      ],
      [
        'Grey wool, white cotton, one good watch.',
        'The variations happen in millimeters and matter enormously.',
      ],
      [
        'Style is not the search for something new.',
        'It is the refinement of something true.',
      ],
    ],
  ),
  'Wax Poetics': ArticleSeed(
    title: 'Grooves Worth Keeping',
    pageCount: 14,
    paragraphs: [
      [
        'A record collection is autobiography you can play.',
        'The scratches are marginalia.',
      ],
      [
        'We visited a jazz kissa in Kyoto where talking is discouraged',
        'and the amplifier is older than most of the customers.',
      ],
      [
        'Digital music remembers everything and treasures nothing.',
        'Vinyl forces the opposite: you keep only what you return to.',
      ],
      [
        'Play the whole side. Flip it yourself.',
        'The ritual is the point.',
      ],
    ],
  ),
  'Openhouse': ArticleSeed(
    title: 'Doors Left Open',
    pageCount: 10,
    paragraphs: [
      [
        'Twice a year, strangers walk through Marta’s living room.',
        'She calls it an exhibition; her neighbors call it Tuesday.',
      ],
      [
        'A home opened to others changes shape —',
        'the bookshelf becomes a statement, the kitchen a stage.',
      ],
      [
        'But something kinder happens too.',
        'Guests leave, and the house feels larger, not emptier.',
      ],
      [
        'Privacy protects a home.',
        'Hospitality is what makes it one.',
      ],
    ],
  ),
  'Frieze': ArticleSeed(
    title: 'Looking Slowly',
    pageCount: 14,
    paragraphs: [
      [
        'The average museum visitor spends eight seconds per artwork.',
        'This essay asks for eight minutes, once.',
      ],
      [
        'Stand until the painting stops being an image',
        'and starts being a decision someone made, stroke by stroke.',
      ],
      [
        'Contemporary art is not hard to understand.',
        'It is hard to stand still for. Those are different problems.',
      ],
      [
        'Pick one work this month.',
        'Give it the eight minutes. Report back to no one.',
      ],
    ],
  ),
  'SUITCASE': ArticleSeed(
    title: 'Pack Light, Stay Long',
    pageCount: 12,
    paragraphs: [
      [
        'The length of a trip should be measured in routines formed,',
        'not sights collected.',
      ],
      [
        'Stay long enough to have a usual bakery.',
        'Long enough that the barista starts your order on sight.',
      ],
      [
        'One neighborhood, three weeks, no checklist.',
        'You will see less of the city and remember more of it.',
      ],
      [
        'Travel is not an inventory.',
        'It is a temporary residency in someone else’s ordinary.',
      ],
    ],
  ),
};

/// 매거진별 3호 이후 아티클 — 데모 대표 매거진부터 채운다.
/// syncArticles가 1·2호에 이어 제목 단위로 멱등 추가한다.
const Map<String, List<ArticleSeed>> kExtraArticleSeeds = {
  'CEREAL': [
    ArticleSeed(
      title: 'Blue Hour',
      pageCount: 10,
      paragraphs: [
        [
          'There are twenty minutes after sunset when every city agrees to be beautiful.',
          'Photographers call it the blue hour; we call it the honest one.',
        ],
        [
          'Streetlights come on one by one, like a rehearsal nobody planned.',
          'Windows turn from mirrors into small theatres.',
        ],
        [
          'We stopped scheduling anything for this hour.',
          'Some appointments should only be kept with the sky.',
        ],
        [
          'You cannot photograph all of it, and that is the point.',
          'The blue hour is practice for letting good things pass.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'Airports, Quietly',
      pageCount: 9,
      paragraphs: [
        [
          'An airport at six in the morning is a library of intentions.',
          'Everyone is halfway between one life and another.',
        ],
        [
          'We like the gates with no announcements yet,',
          'where coffee steam rises past departure boards still deciding.',
        ],
        [
          'Pack the night before; arrive absurdly early; want nothing.',
          'The luxury is not the lounge — it is the unhurried hour.',
        ],
        [
          'Travel begins before the aircraft does.',
          'It begins the moment you stop rehearsing the day ahead.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'A Field Guide to Grey',
      pageCount: 11,
      paragraphs: [
        [
          'Grey is not the absence of colour.',
          'It is colour resting between commitments.',
        ],
        [
          'Concrete after rain, gulls over a winter harbour,',
          'the north wall of a house that never asked to be photographed.',
        ],
        [
          'We counted eleven greys on one street in Copenhagen.',
          'None of them matched, and nothing clashed.',
        ],
        [
          'Learn your greys and the loud colours will organise themselves.',
          'Restraint, practised daily, starts to look like style.',
        ],
      ],
    ),
  ],
  'KINFOLK': [
    ArticleSeed(
      title: 'The Borrowed Recipe',
      pageCount: 10,
      paragraphs: [
        [
          'Every family owns one recipe that was never written down.',
          'It survives by being cooked, not by being kept.',
        ],
        [
          'We asked readers to send us their borrowed dishes.',
          'Half arrived with apologies: it never tastes like hers.',
        ],
        [
          'Of course it does not.',
          'The missing ingredient was the kitchen it came from.',
        ],
        [
          'Cook it anyway, badly and often.',
          'Repetition is how a recipe becomes an inheritance.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'Walking Home the Long Way',
      pageCount: 8,
      paragraphs: [
        [
          'The short way home is a corridor; the long way is a room.',
          'Ten extra minutes can hold an entire season.',
        ],
        [
          'We pass the florist closing up, the dog that owns the corner,',
          'a lit kitchen where someone is always stirring something.',
        ],
        [
          'A neighbourhood is not where you live.',
          'It is what you notice on the way there.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'Winter Table',
      pageCount: 10,
      paragraphs: [
        [
          'In winter the table moves closer to the stove,',
          'and conversation moves closer to the truth.',
        ],
        [
          'Set out what there is: bread, something braised, a candle stub.',
          'Abundance in January is mostly warmth arranged well.',
        ],
        [
          'The guests stay longer when the food stops pretending.',
          'A pot on the table beats a plate from the kitchen.',
        ],
        [
          'Winter hospitality has one rule only:',
          'no one reaches for their coat until the second pot of tea.',
        ],
      ],
    ),
  ],
  'Drift': [
    ArticleSeed(
      title: 'The Corner Counter',
      pageCount: 9,
      paragraphs: [
        [
          'Every good café has one seat that regulars never announce and never surrender.',
          'It is always the corner counter, facing the room at an angle.',
        ],
        [
          'From there you can watch the machine, the door, and the weather —',
          'the three moods that decide a café’s entire day.',
        ],
        [
          'We judge a new city by how long that seat stays warm.',
          'Fast turnover means commuters; slow means neighbours.',
        ],
        [
          'Order the second cup you do not need.',
          'Rent for the best seat in the city is paid in refills.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'Two Cities, One Cup',
      pageCount: 10,
      paragraphs: [
        [
          'In Seoul the café is a study hall; in Lisbon it is a hallway.',
          'Same beans, opposite philosophies of sitting.',
        ],
        [
          'One city perfects the pour and stays for three hours.',
          'The other drinks standing up and argues about football.',
        ],
        [
          'Neither is wrong; both are complete.',
          'Coffee is just the fee a city charges for belonging.',
        ],
        [
          'Drink it their way for a week.',
          'You will learn more at the counter than at the monuments.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'Morning Service',
      pageCount: 8,
      paragraphs: [
        [
          'The first shift at a café is a kind of liturgy:',
          'chairs down, grinder purged, milk fridge counted twice.',
        ],
        [
          'The first customer never says much, and neither should the room.',
          'Six a.m. belongs to people mid-sentence with their own lives.',
        ],
        [
          'By eight the playlist can speak; by ten it can joke.',
          'A good café raises its voice with the sun, never before.',
        ],
      ],
    ),
  ],
  'The Gourmand': [
    ArticleSeed(
      title: 'Sugar, Studied',
      pageCount: 11,
      paragraphs: [
        [
          'Dessert is the only course with no alibi.',
          'Nobody needs it, which is why it tells the truth about a kitchen.',
        ],
        [
          'We watched a pastry chef temper chocolate for an hour.',
          'It looked less like cooking than like negotiation.',
        ],
        [
          'Sweetness is easy; balance is expensive.',
          'The best desserts spend their sugar like a last coin.',
        ],
        [
          'Order dessert first, at least once.',
          'A meal read backwards reveals its author.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'Still Life with Citrus',
      pageCount: 9,
      paragraphs: [
        [
          'Painters kept lemons on the table for three hundred years.',
          'Cooks kept them for the same reason: light you can eat.',
        ],
        [
          'A curl of zest rescues a heavy dish the way a window rescues a room.',
          'Acid is architecture.',
        ],
        [
          'We photographed twelve citrus fruits like portraits.',
          'The blood orange refused to look ordinary from any angle.',
        ],
        [
          'Winter cooking without citrus is a sentence without a verb.',
          'Squeeze generously; apologise never.',
        ],
      ],
    ),
    ArticleSeed(
      title: 'The Last Course',
      pageCount: 10,
      paragraphs: [
        [
          'The meal does not end with dessert.',
          'It ends when someone finally tells the story they came to tell.',
        ],
        [
          'Every great dinner has a last course that is not on the menu:',
          'crumbs, half-glasses, and the candle allowed to burn low.',
        ],
        [
          'Restaurants that rush this hour lose the whole evening.',
          'The bill can wait; the ending cannot be reheated.',
        ],
        [
          'Cook for the conversation, not the compliment.',
          'What people remember is never the plating.',
        ],
      ],
    ),
  ],
};
