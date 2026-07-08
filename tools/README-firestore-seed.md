# Firestore Magazine Seed

LOGZINE 데모용 매거진 카탈로그를 Firestore `magazines` 컬렉션에 넣는 관리자 시드 도구입니다.

## 포함 내용

- `firestore_magazine_seed.json`: 매거진 24개와 각 매거진의 첫 아티클 1개
- `seed_firestore_magazines.ps1`: Firebase Admin 서비스 계정으로 Firestore REST API에 업로드

각 매거진은 앱 커버 카드 구조에 맞춰 아래 필드를 가집니다.

- `title`
- `tagline`
- `issue`
- `coverUrl`
- `tags`
- `order`

`tags`는 `docs/ui_keyword_vocabulary.md`에 있는 UI 키워드만 사용합니다.

## 준비

Firebase Console에서 서비스 계정 JSON을 내려받습니다.

경로:

`Project settings > Service accounts > Generate new private key`

다운로드한 파일을 아래 위치에 저장합니다.

```powershell
tools\serviceAccountKey.json
```

이 파일은 `.gitignore` 대상이므로 커밋하지 않습니다.

## 실행

repo 루트에서:

```powershell
.\tools\seed_firestore_magazines.ps1
```

다른 위치의 서비스 계정 파일을 쓰려면:

```powershell
.\tools\seed_firestore_magazines.ps1 -ServiceAccountPath "C:\path\serviceAccountKey.json"
```

실제로 쓰기 전에 대상 목록만 확인하려면:

```powershell
.\tools\seed_firestore_magazines.ps1 -DryRun
```

## 주의

현재 Firestore rules는 `magazines/**` 쓰기를 막고 있습니다.
이 스크립트는 클라이언트 권한이 아니라 Firebase Admin 서비스 계정으로 실행합니다.
