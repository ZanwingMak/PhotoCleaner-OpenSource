<p align="center">
  <img src="docs/icon.png" width="128" alt="PhotoCleaner 아이콘" />
</p>

<h1 align="center">PhotoCleaner</h1>

<p align="center"><a href="README.md">English</a> · <a href="README.zh.md">中文</a> · <a href="README.ja.md">日本語</a> · <b>한국어</b></p>

> Slidebox 스타일의 iOS 사진 정리 도구. 네이티브 SwiftUI, iOS 26 리퀴드 글래스.

![iOS](https://img.shields.io/badge/iOS-17%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)
![Version](https://img.shields.io/badge/version-1.1.6-success)

## 기능

- 📷 시스템 사진 라이브러리 읽기, 스마트 앨범 + 메타데이터로 분류
- 👉 **스와이프로 검토**: 왼쪽 = 다음 / 오른쪽 = 이전 / 위 = 삭제 대기에 추가
- 🗑 **삭제 대기 목록** 일괄 확인 + iOS 시스템 삭제 대화상자
- ⏪ 한 단계 되돌리기
- 🖼 **사진 브라우저**: 전체 화면, 줌, 좌우 페이지 전환, 즐겨찾기 / 공유 / 사진 앱으로 이동
- 📊 **메타데이터 시트**: 크기, 파일 크기, 종류, 위치, 재생시간
- 💡 **스마트 추천**: 6가지 정리 진입점 (오래된 스크린샷 / 용량 차지 / 동영상 / 라이브 사진 / 셀카 / 소셜 미디어). 홈 가로 카드 + 「더보기」 시트에서 전체 목록 확인
- 🌗 **5가지 테마**: 시스템 / 다크 / 라이트 / 카라멜 / 쿨
- 🌐 **4개 언어**: 中文 / English / 日本語 / 한국어
- ⬆️ **새 버전 감지**: 설정 진입 시 GitHub Releases 를 백그라운드에서 조용히 조회, 새 버전이 있으면 「정보」 섹션에 강조 표시
- ✨ iOS 26 리퀴드 글래스 + 전용 AppIcon
- 🔒 100% 기기 내 처리, 업로드 없음

## 스크린샷

<p align="center">
  <img src="docs/screenshots/01-home.png" width="240" alt="홈 — 스마트 추천, Time Lens, Bento 카테고리" />
  <img src="docs/screenshots/02-albums.png" width="240" alt="앨범 — 스마트 앨범과 추론된 정리 카테고리" />
  <img src="docs/screenshots/03-settings.png" width="240" alt="설정 — 테마, 언어, 경험 토글" />
</p>

> 왼쪽부터 오른쪽: 스마트 추천과 Time Lens가 있는 홈 · 스마트 앨범과 정리 카테고리가 있는 앨범 · 테마, 언어, 경험 토글이 있는 설정.

## 프로젝트 구조

[English README](README.md#project-structure) 참조 (동일).

## 시뮬레이터에서 실행

```bash
# Xcode 26+ 와 iOS Simulator runtime 필요
open PhotoCleaner.xcodeproj
# Xcode 에서 ⌘R
```

## 미서명 IPA 빌드

```bash
bash scripts/build-ipa.sh
# 결과물: build/PhotoCleaner-v<VERSION>.ipa
```

## 실기기에 설치 (개발자 계정 없이)

IPA 는 미서명. 다음 중 하나로 무료 Apple ID 로 자체 서명 (인증서 7일 유효):

### 방법 A: Sideloadly (가장 간단)
1. https://sideloadly.io 다운로드
2. `build/PhotoCleaner-v<VERSION>.ipa` 끌어다 놓기
3. 무료 Apple ID 입력
4. iPhone: 설정 → 일반 → VPN 및 기기 관리 → 인증서 신뢰

### 방법 B: AltStore (자동 갱신)
AltServer 를 백그라운드에서 실행하여 7일 인증서 자동 갱신

### 방법 C: Xcode 직접 서명
Xcode 에서 프로젝트 열고 Signing → Team 에 무료 Apple ID 선택, ⌘R 로 실기기에 실행

## 개인정보

- 모든 처리는 기기 내. **업로드 전혀 없음**
- `NSPhotoLibraryUsageDescription` 만 요청
- 삭제 시 iOS 시스템 대화상자가 표시되며, 앱은 이를 우회할 수 없음
- 버전 확인은 `api.github.com` 에 단일 GET 요청만 보내며, 표준 User-Agent 외에 개인 정보를 전송하지 않습니다

## 링크

- [변경 사항 CHANGELOG.md](CHANGELOG.md)
- [기능 명세 FEATURES.md](FEATURES.md)
- [테스트 계획 TEST_PLAN.md](TEST_PLAN.md)
- [Releases](https://github.com/ZanwingMak/PhotoCleaner/releases)

## 라이선스

GPL-3.0-only
