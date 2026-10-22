# DevOps

인하공업전문대학 컴퓨터정보공학과 · 2026-2 DevOps 실습 기록

리눅스 기초부터 셸 스크립트, Git 협업, Docker, Docker Compose까지 매주 실습한 내용을 주차별 폴더에 정리했다.

## 실습 환경

- Windows + WSL2 (Ubuntu 24.04)
- Git, GitHub CLI
- Ollama + Qwen (`qwen3:0.6b`)
- Docker Desktop

## 주차별 내용

| 주차 | 주제 | 주요 내용 |
|---|---|---|
| 1주차 | 오리엔테이션 | - |
| [2주차](./week02/) | 실습 환경 구축과 버전 관리 기초 | WSL2, 리눅스 명령어, Git 커밋과 브랜치, GitHub 연결 |
| [3주차](./week03/) | 셸 스크립팅 | Ollama 로컬 AI 챗, `start.sh`, 환경 변수 |
| [4주차](./week04/) | 자동화와 협업 / 네트워크 | 백업 스크립트, 브랜치 → PR → Conflict 해결, 포트 충돌 |
| [5주차](./week05/) | Docker | nginx 컨테이너 실행, Issue #3 → PR #4로 실습 관리 |
| [6주차](./week06/) | Dockerfile과 이미지 배포 | 나만의 방명록 `guestbook:v2` 빌드, ghcr.io 배포 |
| [7주차](./week07/) | Docker Compose | web + redis + nginx, healthcheck, `--scale web=3` |


