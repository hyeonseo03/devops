# 2주차 - 실습 환경 구축과 버전 관리 기초

## 1. 실습 개요

| 항목 | 내용 |
|---|---|
| 목표 | WSL2 기반 리눅스 실습 환경을 구축하고 Git/GitHub로 버전 관리를 시작한다 |
| 환경 | Windows + WSL2 (Ubuntu 24.04), Git, GitHub CLI |
| 결과물 | 공개 저장소 [hyeonseo03/devops](https://github.com/hyeonseo03/devops) |

## 2. 학습 내용

### 2-1. 서버 운영 방식 비교

서버를 운영하는 방식은 크게 세 가지로 나뉜다.

| 방식 | 특징 | 장점 | 단점 |
|---|---|---|---|
| 베어메탈 | 물리 서버에 OS를 직접 설치한다 | 성능 손실이 없다 | 자원 활용도가 낮다 |
| 하이퍼바이저 (VM) | 하나의 서버에서 게스트 OS를 여러 개 실행한다 | OS 단위로 완전히 격리된다 | 무겁고 부팅이 느리다 |
| 컨테이너 | 호스트 OS의 커널을 공유한다 | 가볍고 실행이 빠르다 | VM보다 격리 수준이 낮다 |

컨테이너는 리눅스의 **네임스페이스(격리)** 와 **cgroups(자원 제어)** 기술로 격리 공간을 만든다.
커널을 공유하기 때문에 VM보다 훨씬 가볍다.

### 2-2. WSL2

WSL2(Windows Subsystem for Linux)는 윈도우 안에서 실제 리눅스 커널을 실행하는 기능이다.
PowerShell에서 Ubuntu를 설치하고, 이후 모든 실습은 Ubuntu 터미널에서 진행하였다.

```powershell
wsl --install -d Ubuntu-24.04   # Ubuntu 설치
wsl -l -v                       # 설치된 배포판과 WSL 버전 확인
```

### 2-3. 리눅스 기본 명령어

| 명령어 | 설명 |
|---|---|
| `pwd` | 현재 작업 경로를 출력한다 |
| `ls -l` / `ls -a` | 상세 정보 / 숨김 파일까지 출력한다 |
| `cd` | 디렉터리를 이동한다 |
| `mkdir` / `rmdir` | 디렉터리를 생성 / 삭제한다 |
| `touch` | 빈 파일을 생성한다 |
| `cp` / `mv` / `rm` | 파일을 복사 / 이동 / 삭제한다 |
| `cat` | 파일 내용을 출력한다 |
| `echo "내용" > 파일` | 파일에 내용을 쓴다 (덮어쓰기) |
| `chmod u+x 파일` | 소유자에게 실행 권한을 부여한다 |

`ls -l` 결과의 `-rw-r--r--`는 소유자 / 그룹 / 기타 사용자의 읽기(r), 쓰기(w), 실행(x) 권한을 의미한다.

### 2-4. Git 버전 관리

Git은 파일의 변경 이력을 버전 단위로 기록하는 버전 관리 시스템이다.

```
작업 디렉터리 ──git add──▶ Staging Area ──git commit──▶ 로컬 저장소 ──git push──▶ GitHub
```

| 명령어 | 설명 |
|---|---|
| `git config --global user.name` | 커밋에 기록될 이름을 설정한다 |
| `git init` | 현재 디렉터리를 Git 저장소로 초기화한다 |
| `git status` | 변경 상태를 확인한다 |
| `git add` | 다음 커밋에 포함할 변경사항을 선택한다 |
| `git commit -m "메시지"` | 선택한 변경사항을 하나의 버전으로 기록한다 |
| `git log --oneline` | 커밋 기록을 한 줄씩 확인한다 |
| `git diff <해시1> <해시2>` | 두 버전의 차이를 비교한다 |

`git add`는 저장이 아니라 **다음 커밋에 넣을 변경사항을 고르는 단계**라는 점을 이해하였다.

### 2-5. 브랜치

브랜치는 특정 커밋을 가리키는 이름으로, `main`을 그대로 둔 채 별도의 공간에서 작업할 수 있게 해준다.

```bash
echo "hello" > hello.txt
git add . && git commit -m "hello"
git switch -c hi                 # hi 브랜치 생성 후 이동
echo "hi" > hello.txt
git add . && git commit -m "hello -> hi"
git switch main && cat hello.txt # hello
git switch hi && cat hello.txt   # hi
git diff main hi                 # 두 브랜치 비교
```

같은 `hello.txt`라도 브랜치에 따라 내용이 다르게 보이는 것을 확인하였다.

### 2-6. GitHub 연결

GitHub CLI(`gh`)로 로그인한 뒤 로컬 저장소를 GitHub에 공개 저장소로 생성하였다.

```bash
sudo apt install gh -y
gh auth login                    # GitHub.com → HTTPS → 웹 브라우저 인증
gh repo create devops --public --source=. --remote=origin --push
gh browse --no-browser           # 저장소 링크 확인
```

| 옵션 | 의미 |
|---|---|
| `--public` | 공개 저장소로 생성한다 |
| `--source=.` | 현재 디렉터리를 원본으로 사용한다 |
| `--remote=origin` | 원격 저장소 이름을 origin으로 지정한다 |
| `--push` | 로컬 커밋을 바로 업로드한다 |

### 2-7. README.md 작성

README.md는 폴더를 열었을 때 화면에 바로 표시되는 문서이다.
`nano`로 작성하고 마크다운 문법으로 주차별 학습 내용을 정리하였다.

| nano 단축키 | 기능 |
|---|---|
| `Ctrl + O` | 저장 |
| `Ctrl + X` | 종료 |
| `Ctrl + K` | 현재 줄 잘라내기 |
| `Ctrl + U` | 붙여넣기 |

## 3. 실습 결과

- WSL2에 Ubuntu 24.04를 설치하고 리눅스 실습 환경을 구축하였다.
- `~/devops`를 Git 저장소로 초기화하고 `week02/` 디렉터리를 생성하였다.
- `text.txt`(Hello, DevOps!)와 `hello.txt`를 작성하여 커밋과 브랜치를 실습하였다.
- GitHub에 공개 저장소 `devops`를 생성하고 실습 결과를 푸시하였다.

```
week02/
├── README.md
├── text.txt     # 커밋 실습 (Hello, DevOps!)
└── hello.txt    # 브랜치 실습 (hello → hi)
```

## 4. 정리

- 컨테이너는 호스트 커널을 공유하기 때문에 VM보다 가볍고 빠르다.
- `git add`는 변경사항을 선택하는 단계이고, `git commit`은 그것을 버전으로 기록하는 단계이다.
- 커밋은 로컬에만 기록되므로 반드시 `git push`를 해야 GitHub에 반영된다.
- 브랜치를 사용하면 `main`을 안전하게 유지한 채 다른 작업을 할 수 있다.
