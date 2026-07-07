---
name: logzine-workflow
description: LOGZINE 저장소에서 브랜치·커밋·PR 등 git 작업을 할 때 따르는 협업 규칙. git 작업이면 반드시 이 문서대로 진행한다.
---

# LOGZINE Git 협업 규칙 (요약: CONTRIBUTING.md의 실행 버전)

## 황금률

1. **main에 직접 푸시 금지** — 모든 변경은 브랜치 → PR → 머지
2. **한 브랜치 = 한 가지 작업** (섞이면 브랜치를 나눌 것)
3. **PR은 작게** (~300줄 이하 목표)

## 작업 순서 (그대로 실행)

```bash
git checkout main && git pull origin main     # ① 최신화
git checkout -b feat/작업이름                  # ② 브랜치 (이슈에 적힌 브랜치명 사용)
# ③ 작업 + 작은 단위 커밋
cd logzine_app && flutter analyze && flutter test   # ④ 검증 (둘 다 통과 필수)
git push -u origin feat/작업이름               # ⑤ 푸시 → GitHub에서 PR 생성
```

## 브랜치 이름

`feat/` 새 기능 · `fix/` 버그 · `refactor/` 구조 개선 · `docs/` 문서 · `chore/` 설정/의존성
(소문자+하이픈, 영어. 예: `feat/reader-search`)

## 커밋 메시지

```
<타입>: <무엇을 왜> (한국어 OK, 50자 이내)
```
좋은 예: `feat: 리더 본문 검색 기능 추가` / 나쁜 예: `수정`, `최종`, `asdf`

## PR 본문 형식 (필수 3항목 + 이슈 연결)

```markdown
## 무엇을
(변경 요약)

## 왜
(배경/문제)

## 확인 방법
1. flutter run -d chrome → ...
2. ...확인

Closes #이슈번호
```

- UI 변경이면 스크린샷 첨부 권장
- `Closes #N`을 쓰면 머지 시 이슈 자동 닫힘
- 머지는 **Squash and merge**, 머지 후 브랜치 삭제

## 금지

- `git push --force` (공유 브랜치)
- `build/`, `.dart_tool/` 커밋
- API 키·토큰·시크릿 커밋 (한 번 올라가면 히스토리에 영원히 남음)
- 리뷰 없는 대형 변경

## 참고: 본보기 PR

형식이 헷갈리면 머지된 PR #17, #21~#31을 열어 그대로 따라 할 것.
