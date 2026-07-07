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
