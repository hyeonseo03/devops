# 3주차 - 셸 스크립팅

## 1. 실습 개요

| 항목 | 내용 |
|---|---|
| 목표 | 반복 명령을 셸 스크립트로 작성하고, 환경 변수와 조건문으로 실행 환경을 다룬다 |
| 실습 | Ollama + Qwen 기반 로컬 AI 웹 챗을 셸 스크립트로 실행한다 |
| 환경 | WSL2 (Ubuntu 24.04), Python 3, Ollama, `qwen3:0.6b` |
| 결과물 | `week03/qwen-web/` (start.sh 외 2개 스크립트) |

## 2. 학습 내용

### 2-1. 셸 스크립트가 필요한 이유

매일 10분씩 걸리는 반복 작업을 손으로 하면 1년에 약 61시간이 든다.
또한 사람은 오타, 순서 바뀜, 단계 생략 같은 실수를 반드시 한다.
반면 제대로 작성된 스크립트는 몇 번을 실행해도 같은 절차로 동작한다.
이것이 자동화의 출발점이다.

### 2-2. 로컬 AI 서비스 구조

| 구성 요소 | 역할 | 주소 |
|---|---|---|
| 브라우저 | 질문 전송, 답변 표시 | `http://localhost:8000` |
| `chat.py` | 질문을 Ollama API로 전달하는 파이썬 웹 앱 | `127.0.0.1:8000` |
| Ollama 서버 | 로컬에서 LLM을 실행하는 서버 | `127.0.0.1:11434` |
| `qwen3:0.6b` | 답변을 만드는 모델 (약 522MB) | |

```
브라우저 ──▶ chat.py (8000) ──▶ Ollama 서버 (11434) ──▶ qwen3:0.6b
```

- **Qwen**: 알리바바 클라우드에서 개발한 대형 언어 모델이다.
- **Ollama**: 로컬 환경에서 LLM을 설치하고 실행할 수 있게 해주는 오픈소스 플랫폼이다.
- 모델 이름의 `0.6b`는 파라미터 개수(약 6억 개)를 의미한다. 클수록 성능은 좋아지지만 더 느리고 메모리를 많이 쓴다.
- 모델 파일은 Ollama가 따로 보관하므로 저장소에 복사하거나 푸시하지 않는다.

### 2-3. Ollama 설치 및 모델 준비

```bash
sudo apt update
sudo apt install -y python3 curl zstd
curl -fsSL https://ollama.com/install.sh | sh    # Ubuntu 터미널에서 설치

ollama --version                                 # 설치 확인
curl -fsS http://127.0.0.1:11434/api/tags        # JSON이 나오면 서버 응답 정상
ollama pull qwen3:0.6b                           # 모델 다운로드
ollama list                                      # 받은 모델 확인
```

서버가 응답하지 않으면 `ollama serve`로 직접 실행한다.

### 2-4. 셸 스크립트 기본

| 요소 | 의미 |
|---|---|
| `#!/bin/bash` | 셔뱅(shebang). 이 파일을 bash로 실행하라고 OS에 알려주는 첫 줄이다 |
| `chmod u+x 파일` | 실행 권한을 부여한다. 없으면 `Permission denied`가 발생한다 |
| `./start.sh` | 현재 폴더의 스크립트를 실행한다. `start.sh`만 쓰면 PATH에서 찾기 때문에 실행되지 않는다 |
| `cd "$(dirname "$0")"` | 스크립트가 있는 폴더로 이동한다. 어디서 실행해도 같은 위치 기준으로 동작한다 |
| `\|\| exit 1` | 앞 명령이 실패하면 종료 코드 1로 스크립트를 끝낸다 |
| `exec` | 현재 셸을 다른 프로그램으로 교체하여 실행한다 |

`cd "$(dirname "$0")"`를 구성하는 요소는 다음과 같다.

| 기호 | 의미 |
|---|---|
| `$0` | 실행한 스크립트의 경로 |
| `dirname` | 경로에서 파일 이름을 빼고 디렉터리 부분만 출력 |
| `$( ... )` | 명령어 치환. 괄호 안 명령의 출력을 그 자리에 넣는다 |
| `"..."` | 경로에 공백이 있어도 하나로 처리하기 위한 따옴표 |

### 2-5. 인자와 종료 상태

| 기호 | 의미 |
|---|---|
| `$1`, `$2` | 첫 번째, 두 번째 인자 |
| `$#` | 전달받은 인자의 개수 |
| `$@` | 전달받은 모든 인자 |
| `$?` | 직전 명령의 종료 상태 (0 = 성공, 그 외 = 실패) |

### 2-6. 환경 변수

`chat.py`는 실행 시 환경 변수를 읽고, 값이 없으면 기본값을 사용한다.

| 환경 변수 | 기본값 | 의미 |
|---|---|---|
| `MODEL` | `qwen3:1.7b` | 사용할 모델 |
| `WEB_PORT` | `8000` | 웹 서버 포트 |
| `APP_NAME` | `Qwen Web` | 화면 제목 |

`export`로 지정한 값은 자식 프로세스(`chat.py`)까지 전달된다.
따라서 코드를 고치지 않고 실행 방법만 바꿔서 설정을 변경할 수 있다.

### 2-7. 조건문으로 실행 환경 점검

```bash
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3를 먼저 설치하세요." >&2
    exit 1
fi
```

| 코드 | 의미 |
|---|---|
| `command -v python3` | python3가 설치되어 있으면 경로를 출력하고 성공한다 |
| `!` | 결과를 반전한다 (설치되어 있지 않다면) |
| `>/dev/null 2>&1` | 표준 출력과 표준 오류를 모두 버린다 |
| `>&2` | 메시지를 표준 오류로 출력한다 |
| `exit 1` | 실패 상태로 종료한다 |

## 3. 실습 결과

### 3-1. 작성한 스크립트

**start.sh** : 기본 실행 스크립트

```bash
#!/bin/bash
cd "$(dirname "$0")" || exit 1

if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3를 먼저 설치하세요." >&2
    exit 1
fi

exec python3 chat.py
```

**start_with_export.sh** : 모델을 지정하여 실행

```bash
#!/bin/bash
cd "$(dirname "$0")" || exit 1
export MODEL="qwen3:0.6b"
exec ./start.sh
```

**start_with_export_2.sh** : 포트를 바꿔서 실행

```bash
#!/bin/bash
cd "$(dirname "$0")" || exit 1
export WEB_PORT="8080"
exec ./start.sh
```

### 3-2. 실행

```bash
cd ~/devops/week03/qwen-web
chmod u+x start.sh start_with_export.sh start_with_export_2.sh
./start.sh                  # http://localhost:8000
./start_with_export_2.sh    # http://localhost:8080
```

- `./start.sh` 실행 후 브라우저에서 질문을 보내 모델의 답변이 표시되는 것을 확인하였다.
- `./start_with_export_2.sh`로 실행하면 코드 수정 없이 8080 포트로 접속되는 것을 확인하였다.
- `Ctrl + C`로 웹 앱을 종료해도 Ollama 서버(11434)는 계속 실행되는 것을 확인하였다.

### 3-3. 파일 구성

```
week03/
├── README.md
└── qwen-web/
    ├── chat.py                  # 웹 챗 (LMS 제공, 파이썬
