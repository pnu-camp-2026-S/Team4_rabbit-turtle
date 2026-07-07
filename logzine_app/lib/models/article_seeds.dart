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
