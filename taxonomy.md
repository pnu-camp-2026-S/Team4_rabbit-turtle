# 취향 키워드 분류 체계

사진에서 추출한 매거진 추천용 키워드의 시작점으로 사용한다. 실제 서비스의 콘텐츠 카테고리에 맞게 라벨은 조정한다.

## 대분류

- `culture_art`: 문화, 예술, 전시, 공연, 건축, 역사.
- `travel_place`: 여행, 로컬 탐방, 랜드마크, 동네, 경치 좋은 장소.
- `lifestyle`: 휴식, 루틴, 공부, 작업, 쇼핑, 웰니스, 개인 의식.
- `food_drink`: 커피, 차, 디저트, 식사, 베이커리, 바.
- `nature_outdoor`: 공원, 산, 바다, 강, 정원, 산책.
- `urban_local`: 도시 거리, 로컬 상점, 시장, 서점, 동네 카페.

## 중분류 키워드

문화와 예술:

- `history_tradition`: 역사/전통
- `architecture_design`: 건축/디자인
- `museum_gallery`: 박물관/갤러리
- `performance_event`: 공연/행사
- `craft_object`: 공예/오브제

여행과 장소:

- `slow_travel`: 느린 여행
- `local_walk`: 로컬 산책
- `tourist_site`: 관광지
- `hidden_place`: 숨은 장소
- `scenic_spot`: 경치 좋은 장소

라이프스타일:

- `quiet_rest`: 조용한 휴식
- `daily_leisure`: 일상 여가
- `study_work`: 공부/작업
- `routine_record`: 루틴 기록
- `aesthetic_collection`: 취향 수집

음식과 음료:

- `coffee`: 커피
- `tea`: 차
- `dessert`: 디저트
- `bakery`: 베이커리
- `casual_dining`: 캐주얼 다이닝

자연과 야외:

- `walk`: 산책
- `park`: 공원
- `waterfront`: 물가
- `forest`: 숲
- `seasonal_view`: 계절 풍경

도시와 로컬:

- `neighborhood`: 동네
- `bookstore`: 서점
- `market`: 시장
- `street_scene`: 거리 풍경
- `local_brand`: 로컬 브랜드

## 예시 매핑

사진: 문화재 배경의 커피

- `object`: 커피
- `place_type`: 문화재, 전통 건축
- `activity`: 커피 브레이크, 문화 산책
- `mood`: 여유로운, 전통적인, 경치 좋은
- `interest`: 역사/전통, 커피, 로컬 산책
- `context`: 문화 외출. 여행은 근거가 있을 때만 사용
- `preference`: 문화+카페, 느린 탐방, 조용한 분위기

사진: 카페의 노트북과 커피

- `object`: 노트북, 커피
- `place_type`: 카페
- `activity`: 공부/작업, 커피 브레이크
- `mood`: 집중되는, 조용한
- `interest`: 커피, 생산적인 공간
- `context`: 일상 루틴 또는 작업/공부
- `preference`: 조용한 카페, 작업하기 좋은 공간

사진: 공원의 책

- `object`: 책
- `place_type`: 공원
- `activity`: 독서, 휴식, 산책
- `mood`: 차분한, 야외적인
- `interest`: 독서, 자연/야외
- `context`: 일상 여가
- `preference`: 야외 휴식, 조용한 독서 공간

## 좋은 라벨의 기준

다음과 같은 라벨을 선호한다.

- 추천에 실제로 도움이 된다.
- 사용자가 이해하기 쉽다.
- 여러 사진에 걸쳐 안정적으로 반복될 수 있다.
- 우연히 찍힌 단일 물체에 지나치게 묶이지 않는다.

다음과 같은 라벨은 피한다.

- 민감한 개인 속성.
- 근거 없는 정확한 위치.
- 한 번 나온 브랜드 추측.
- 순수한 시각적 잡음.
