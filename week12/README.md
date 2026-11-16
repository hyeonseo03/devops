# 12주차 - 깃허브 액션 (CI)

지금까지는 코드를 고치면 `docker build` → `docker push` → `kubectl set image`를 내가 직접 쳤다.
이번 주는 이 중 검사, 테스트, 빌드, 푸시를 깃허브 액션에 맡겼다. 코드를 PR로 올리고 머지만 하면 이미지가 GHCR에 알아서 올라간다.
그리고 일부러 코드를 세 번 망가뜨려서 빨간X가 어디서 뜨는지 보고, main 브랜치 보호 규칙까지 걸어 깨진 코드가 아예 main에 못 들어오게 만들었다.

```
git push → PR
   │
   ▼  (깃허브가 빌려주는 ubuntu 서버)
[소스 가져오기] → [Lint: ruff] → [테스트: unittest] → [빌드] → [GHCR 푸시]
                     실패하면 여기서 멈춤 ─────────────┘       └ main에 머지됐을 때만
```

<br>

## 파일 위치

```
devops/
├── .github/workflows/build.yml    # 워크플로 (저장소 루트!)
└── guestbook/
    ├── tests/test_app.py          # /healthz 확인, 글 등록 후 조회 확인
    └── templates/index.html       # 확인용으로 제목 뒤에 new 추가
```

`build.yml`은 무엇을 언제 어디서 돌릴지 적은 지시서이고, `test_app.py`는 앱이 제대로 동작하는지 확인하는 시험 문제다.

<br>

## 1. 푸시 전에 내 컴퓨터에서 먼저 확인

깃허브에 올리기 전에 같은 파이썬 3.12 컨테이너에서 린트랑 테스트를 먼저 돌려봤다.

```bash
cd ~/devops/guestbook
docker run --rm -v "$PWD":/app -w /app -e PYTHONDONTWRITEBYTECODE=1 python:3.12-slim \
  sh -c "pip install -q ruff -r requirements.txt && ruff check . --select=E9,F --no-cache && python -m unittest discover -s tests -v"
```

`All checks passed!`, 테스트 2개 `ok`가 나왔다. `REDIS_HOST`가 없어서 메모리 모드로 테스트한다.

![local test](images/01-local-test.png)

<br>

## 2. 첫 워크플로: PR → 머지 → 이미지 자동 생성

`feature/ci-setup` 브랜치에서 `build.yml`, `test_app.py`를 넣고, 화면 확인용으로 `index.html`의 제목 뒤에 `new`를 붙였다.

```bash
git add .github guestbook/tests guestbook/templates
git commit -m "CI 파이프라인 추가"
git push -u origin feature/ci-setup
gh pr create --fill
gh pr checks --watch
```

PR #5에서 검사가 1분 2초 만에 통과했다. PR에서는 아직 main에 안 합쳐진 코드라서 빌드까지만 하고 이미지는 안 올린다.

![pr checks](images/02-pr-checks.png)

머지하니까 main에 push가 일어나서 워크플로가 한 번 더 돌았다. 요약 화면에 `Triggered via push`, 커밋 `b13f150`, 브랜치 `main`, 총 1분 9초로 나온다.

![run summary](images/03-run-summary.png)

main 실행을 열어보면 단계가 순서대로 다 통과했다. 코드 검사 5초, 테스트 2초로 빨리 끝나는 것부터 하고, 제일 오래 걸리는 빌드 & 푸시(36초)는 마지막이다.
PR 때는 건너뛰었던 `ghcr.io 로그인`이 main에서는 실행됐다.

![actions steps](images/04-actions-steps.png)

<br>

## 3. GHCR에 올라간 이미지 확인

패키지 페이지에 `latest`와 `b13f150` 태그가 한 줄에 붙은 새 버전이 생겼다. `b13f150`은 머지 커밋의 앞 7자리라서 이 이미지가 어떤 코드로 만들어졌는지 바로 알 수 있다.
그 아래 `v2`, `v1`은 6주차에 내가 직접 `docker push`로 올린 것이고, 이번 건 나는 `git push`랑 머지만 했다.

![packages](images/05-packages.png)

`latest`만 쓰면 계속 덮어써져서 어제 latest가 뭐였는지 알 수 없다. 커밋 해시 태그가 있으면 롤백할 때도 정확한 버전을 고를 수 있다.

<br>

## 4. CI가 만든 이미지를 쿠버네티스에 적용

```bash
kubectl set image deployment/guestbook web=ghcr.io/hyeonseo03/guestbook:b13f150
kubectl rollout status deployment/guestbook
```

10주차처럼 Pod가 하나씩 교체됐고, 11주차에 넣은 readiness 프로브를 통과한 다음에 옛 Pod가 내려갔다.

![set image](images/06-set-image.png)

브라우저에서 제목이 "현서의 방명록 v2 (k8s) new"로 바뀌었다.
앞부분이랑 주황색은 ConfigMap 값 그대로고, 뒤에 붙은 `new`만 이번에 CI가 빌드한 이미지에서 온 것이다. 저장소도 계속 Redis다.

![browser new](images/07-browser-new.png)

이 마지막 `set image`는 아직 내가 손으로 쳤다. 다음 주에 ArgoCD를 쓰면 이 부분도 자동이 된다고 한다.

<br>

## 5. 빨간X 세 번 → 초록✓

`feature/ci-errors` 브랜치로 PR #6을 열고 같은 브랜치에서 세 가지를 차례로 망가뜨렸다.

### (1) 문법 오류

```bash
echo "def broken(:" >> guestbook/app.py
```

코드 검사(Lint) 단계에서 바로 멈췄다. 로그를 아래에서부터 보면 `exit code 1` → `Found 2 errors` → `app.py:137:12` → `invalid-syntax` 순서로 원인이 나온다.
검사에서 멈췄기 때문에 테스트, 빌드, 푸시는 실행되지 않았다. 깨진 이미지가 만들어지지 않은 것이다.

![syntax error](images/08-syntax-error.png)

마지막 줄을 지우고 다시 push하니 초록✓로 돌아왔다.

![syntax fixed](images/09-syntax-fixed.png)

### (2) 오타 (린트)

`index()` 함수 안에 `print(APP_TITL)`을 넣었다. `APP_TITLE`에서 E 하나를 뺀 오타다.
`python3 -m compileall`로 문법 검사를 해보면 `0`(통과)이 나온다. 파이썬 문법으로는 아무 문제가 없다.
그런데 ruff는 `F821 Undefined name 'APP_TITL'`, `app.py:89:11`로 정확히 그 글자를 짚었다.

![lint error](images/10-lint-error.png)

이대로 배포됐다면 첫 화면에 들어가는 순간 500 에러가 났을 것이다. 린트는 코드를 실행하지 않고도 이걸 찾았다.

### (3) 테스트 실패

`git revert HEAD`로 오타를 되돌리고, 이번엔 `/healthz`가 200 대신 500을 돌려주게 바꿨다.
문법도 맞고 오타도 없어서 코드 검사는 통과했는데, 앱 동작 테스트에서 `AssertionError: 500 != 200`으로 걸렸다.

![test error](images/11-test-error.png)

이게 그대로 배포됐으면 11주차에 건 liveness 프로브가 `/healthz`를 보고 계속 실패해서 Pod가 무한 재시작했을 것이다.
다시 revert하고 초록✓가 된 뒤에 PR #6을 머지했다.

![all fixed](images/12-all-fixed.png)

| 실험 | 넣은 코드 | 걸린 단계 | 메시지 |
|---|---|---|---|
| 문법 오류 | `def broken(:` | 코드 검사 | `invalid-syntax` |
| 오타 | `print(APP_TITL)` | 코드 검사 | `F821 Undefined name` |
| 동작 오류 | `/healthz` → 500 | 앱 동작 테스트 | `500 != 200` |

뒤로 갈수록 실제로 실행해봐야 알 수 있는 문제라서 앞 단계는 통과하고 뒤에서 걸린다.

<br>

## 6. main 브랜치 보호 (룰세트)

Settings → Rules → Rulesets에서 `main-protect` 룰세트를 만들었다.

- 대상: 기본 브랜치(main)
- Require a pull request before merging (승인 수 0, 혼자라서)
- Require status checks to pass → `build`

![ruleset](images/13-ruleset.png)

```bash
gh api "repos/hyeonseo03/devops/rules/branches/main" --jq '.[].type'
# deletion / non_fast_forward / pull_request / required_status_checks
```

삭제 금지, 강제 push 금지, PR 필수, `build` 검사 필수 네 가지가 걸려 있다.

![rules check](images/14-rules-check.png)

확인하려고 main에서 `t.txt`를 커밋해서 바로 push해 봤더니 거부됐다.
`Changes must be made through a pull request`, `Required status check "build" is expected` 두 가지 이유가 나왔다. 저장소 주인인 나도 예외가 없다.

![push rejected](images/15-push-rejected.png)

테스트 커밋은 `git reset --hard origin/main`으로 지웠다.

<br>

## 7. 깨진 코드로 PR → 머지 버튼 잠김

`feature/broken-test` 브랜치에 `def broken2(:`를 넣고 PR #7을 열었다.
검사가 9초 만에 실패했고, 검사 옆에 `Required`가 붙어 있으면서 Squash and merge 버튼이 회색으로 잠겼다.

![merge blocked](images/16-merge-blocked.png)

마지막 줄을 지우고 push한 뒤 검사가 통과하니까 머지가 됐다. `git log`에 `깨진 코드로 PR (#7)`, `문법 오류 확인 (#6)`, `CI 파이프라인 추가 (#5)`가 순서대로 쌓였다.

![merge ok](images/17-merge-ok.png)

CI만 있으면 빨간X가 떠도 누가 무시하고 머지하면 그만인데, 보호 규칙까지 걸어야 진짜로 main이 지켜진다.
빌드를 자동으로 해주는 것보다 이게 CI를 쓰는 더 큰 이유인 것 같다.

<br>

## 내 말로 정리하면

- CI: 코드를 합칠 때마다 로봇이 검사 → 테스트 → 빌드를 대신 해주고, 하나라도 실패하면 거기서 멈춘다.
- workflow는 `.github/workflows/`의 yml 파일 하나, job은 깨끗한 새 서버에서 도는 작업 묶음, step은 그 안의 한 줄 한 줄이다.
- 성공/실패는 화면에 뭐가 찍히든 상관없이 종료 코드(0이면 ✓, 아니면 X)로만 판단한다.
- `GITHUB_TOKEN`은 깃허브가 실행할 때마다 만들어주는 임시 열쇠라서 GHCR 비밀번호를 따로 넣을 필요가 없었다. 대신 패키지 쪽에서 이 저장소에 Write 권한은 줘야 했다.

<br>

## 막혔던 것

**1. `.github` 폴더를 `.git` 폴더로 착각함**
탐색기로 `build.yml`을 넣으려다가 `.git` 폴더를 열었다. `.git`은 커밋 기록이 들어 있는 곳이라 건드리면 안 되고, 워크플로는 `.github/workflows/`에 넣어야 한다.
헷갈려서 `mkdir -p .github/workflows`로 만들고 `cp`로 옮겼다.

**2. 워크플로 파일 push 권한**
워크플로 파일은 GitHub CLI 토큰에 `workflow` 권한이 있어야 올라간다고 해서 `gh auth refresh -s workflow`로 브라우저에서 승인했다. 처음에 코드를 복사하다 Ctrl+C를 눌러서 한 번 다시 했다.

**3. GHCR 403 대비**
6주차에 CLI로 만든 패키지라서 이 저장소랑 연결이 안 돼 있었다. 패키지 설정의 Manage Actions access에서 `devops`를 Write로 추가했더니 처음부터 푸시가 됐다.

**4. 교안 명령이 내 파일이랑 안 맞음**
- `sed 's/{{ title }} v2/...'`는 내 `index.html`에 `v2`가 없어서 안 바뀌었다. `<h1>{{ title }}</h1>`을 찾아서 바꿨다.
- `kubectl apply -f guestbook/k8s`로 폴더째 적용하면 `secret.yaml.example`(CHANGE_ME)까지 들어가서 Redis 비밀번호가 바뀌었을 것이다. 파일을 하나씩 지정해서 적용했다.

**5. PR 실행 이름이 전부 "문법 오류 확인"**
`gh run view --log-failed` 목록에서 오타 실험도, 테스트 실험도 이름이 다 "문법 오류 확인"이라 헷갈렸다. PR 실행은 커밋 메시지가 아니라 PR 제목으로 표시돼서 그렇다. 시간(몇 초 전)으로 구분했다.

**6. 검사가 끝나기 전에 머지했다가 거부됨**
PR #7을 고치고 push하자마자 `gh pr merge`를 쳤더니 `the base branch policy prohibits the merge`가 떴다. 검사가 아직 도는 중이었다. `gh pr checks 7 --watch`로 초록✓를 확인하고 다시 머지했다.
안내에 `--admin`을 쓰라고 나오는데, 그러면 규칙을 무시하는 거라 안 썼다.

<br>

## 느낀 점

처음엔 `git push`만 했는데 이미지가 생긴 게 신기했다. 하지만 정확히는 push만으로 되는 게 아니라 검사, 테스트, 빌드를 다 통과하고 main일 때만 이미지가 올라간다.
문법 오류, 오타, 동작 오류를 일부러 넣어보니 각각 다른 단계에서 걸리는 게 눈에 보여서 린트랑 테스트가 왜 따로 있는지 이해됐다.
다만 테스트는 내가 쓴 것만 확인해 준다. 지금은 테스트가 2개뿐이라 다른 기능이 고장 나면 못 잡을 것 같아서, 기능을 추가하면 테스트도 같이 늘려야겠다.
