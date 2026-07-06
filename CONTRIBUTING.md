# 🐰🐢 Team4 협업 가이드

> 우리 팀의 브랜치 · 커밋 · PR 규칙입니다. 5분만 읽으면 충돌 없이 협업할 수 있어요.

---

## 0. 처음 시작하기 (최초 1회)

```bash
git clone https://github.com/pnu-camp-2026-S/Team4_rabbit-turtle.git
cd Team4_rabbit-turtle/logzine_app
flutter pub get
flutter run          # 실행 방법·에뮬레이터 주의사항은 logzine_app/README.md 참고
```

> ⚠️ 에뮬레이터가 켜자마자 죽으면 `logzine_app/README.md`의 **트러블슈팅** 표를 먼저 보세요 (GPU 소프트웨어 렌더링 필요).

---

## 1. 황금률 세 가지

1. **`main`에 직접 푸시하지 않는다.** 모든 변경은 브랜치 → PR → 머지.
2. **한 브랜치 = 한 가지 작업.** "리더 검색 기능"과 "홈 버그 수정"을 한 브랜치에 섞지 않기.
3. **PR은 작게.** 리뷰하는 사람이 10분 안에 읽을 수 있는 크기(대략 300줄 이하)가 이상적.

---

## 2. 작업 흐름 (매번 이 순서대로)

```bash
# ① 시작 전: main 최신화
git checkout main
git pull origin main

# ② 작업 브랜치 생성
git checkout -b feat/reader-search

# ③ 개발하면서 작은 단위로 커밋 (아래 커밋 규칙 참고)
git add lib/pages/reader_page.dart
git commit -m "feat: 리더 본문 검색 기능 추가"

# ④ 푸시 전 검증 (둘 다 통과해야 함)
flutter analyze
flutter test

# ⑤ 브랜치 푸시 → GitHub에서 Pull Request 생성
git push origin feat/reader-search
```

PR이 승인되어 머지되면 브랜치는 삭제합니다 (GitHub 머지 버튼 옆 "Delete branch").

---

## 3. 브랜치 이름 규칙

| 접두어 | 용도 | 예시 |
|---|---|---|
| `feat/` | 새 기능·화면 | `feat/saved-tab`, `feat/login-validation` |
| `fix/` | 버그 수정 | `fix/reader-overflow` |
| `refactor/` | 동작 변화 없는 구조 개선 | `refactor/extract-models` |
| `docs/` | 문서·README·랜딩페이지 | `docs/update-roadmap` |
| `chore/` | 설정·의존성·빌드 | `chore/add-riverpod` |

소문자 + 하이픈, 영어로. 무엇을 하는 브랜치인지 이름만 보고 알 수 있게.

---

## 4. 커밋 메시지 규칙

```
<타입>: <무엇을 왜> (한국어 OK, 50자 이내)
```

- `feat: 온보딩 태그 선택 상태를 전역으로 공유`
- `fix: 하이라이트 패널 3px 오버플로 수정`
- `docs: 실행 트러블슈팅에 프록시 이슈 추가`
- `refactor: 상단 바 위젯 공용화`

**나쁜 예**: `수정`, `update`, `asdf`, `최종`, `진짜최종` ❌
커밋 하나에는 한 가지 변경만. "이것저것 고침"이 되는 순간 쪼개세요.

---

## 5. Pull Request 규칙

PR 설명에 아래 세 가지를 씁니다:

```markdown
## 무엇을
리더 화면에 본문 검색 기능 추가

## 왜
상단 검색 아이콘이 스텁 상태였음 (README 로드맵 8번)

## 확인 방법
1. 리더 진입 → 우상단 돋보기 탭
2. "materials" 입력 → 해당 문장 하이라이트되는지 확인
```

- **UI 변경이면 스크린샷/GIF 필수** — 에뮬레이터 캡처: `adb exec-out screencap -p > shot.png`
- `flutter analyze` / `flutter test` 통과 상태로만 PR 올리기
- 리뷰어 1명 이상 승인 후 머지 (급하면 팀 채팅에서 합의 후 셀프 머지)
- 머지 방식은 **Squash and merge** 권장 — main 히스토리가 PR 단위로 깔끔해짐

---

## 6. 충돌(Conflict) 났을 때

```bash
git checkout main && git pull origin main   # 최신 main 받기
git checkout feat/my-branch
git merge main                              # 내 브랜치에 main 합치기
# 충돌 파일 열어서 <<<<<<< ======= >>>>>>> 부분 정리
git add . && git commit                     # 충돌 해결 커밋
git push
```

- 충돌 정리가 애매하면 **혼자 고민하지 말고 그 코드를 쓴 사람에게 물어보기**
- 같은 파일을 두 명이 동시에 만지는 게 예정되어 있으면 미리 채팅으로 조율

---

## 7. 하지 말 것 ❌

| 금지 | 이유 |
|---|---|
| `main`에 직접 push | 리뷰 없이 팀 전체 코드가 바뀜 |
| `git push --force` (공유 브랜치에) | 팀원의 커밋이 증발함 |
| `build/`, `.dart_tool/` 커밋 | .gitignore가 막아주지만, 강제로 add 하지 말 것 |
| 거대 PR (파일 수십 개) | 리뷰 불가능 → 버그 통과 |
| 시크릿/토큰/API 키 커밋 | 한 번 올라가면 히스토리에 영원히 남음 |

---

## 8. 프로젝트 문서 지도

| 문서 | 내용 |
|---|---|
| [README.md](README.md) | 서비스 소개 + 화면 플로우 + 디자인 시스템 + 로드맵 |
| [logzine_app/README.md](logzine_app/README.md) | 앱 실행 방법 · 트러블슈팅 · 새 화면 추가 체크리스트 |
| [docs/index.html](docs/index.html) | 랜딩페이지 → https://pnu-camp-2026-s.github.io/Team4_rabbit-turtle/ |
| 이 문서 | 협업 규칙 |

**다음에 뭘 개발할지 고를 때**: README의 "다음 구현 로드맵" 섹션에서 골라 이슈로 등록하고 브랜치를 파세요.
