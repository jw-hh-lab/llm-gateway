# 협업 규칙

## 브랜치
- main에는 직접 push하지 않는다. 모든 변경은 PR로 합친다.
- 브랜치 이름: `종류/짧은-설명`
  - `feat/` 새 기능 (예: feat/credit-deduct)
  - `fix/` 버그 수정
  - `infra/` Terraform, k8s, CI/CD (예: infra/vpc-module)
  - `chore/` 설정, 문서, 정리

## PR
- 상대방 1명이 리뷰하고 승인하면 합친다.
- 하나의 PR에는 하나의 목적만 담는다.
- 합칠 때는 Squash and merge를 쓴다.
- 합친 브랜치는 삭제한다.

## 커밋 메시지
- 형식: `종류: 무엇을 했는지` (한글 가능)
- 종류: feat, fix, infra, docs, chore, test, refactor
- 예: `feat: 크레딧 차감 API 추가`, `infra: VPC 모듈 추가`

## 절대 올리지 않는 것
- AWS 키, 비밀번호, LLM API 키, `.env`, `*.tfstate`, `*.tfvars`
- 실수로 올렸다면 바로 상대에게 알리고 키를 폐기(재발급)한다.
