# 4주차 - 자동화와 협업 / 네트워크

## 1. 실습 개요

이번 주에는 셸 스크립트로 로그 검색과 백업을 자동화하고, Git 브랜치와 PR을 이용해 협업 흐름을 실습했다.
네트워크 시간에는 IP, 포트, DNS 개념을 배우고 직접 웹 서버를 띄워 포트 충돌을 확인했다.

## 2. 학습 내용

### 검색과 파이프

`test/server.log`에서 에러 로그만 찾아봤다.

```bash
grep "ERROR" server.log              # ERROR가 있는 줄만 출력
grep -c "ERROR" server.log           # 개수만 출력 → 3
grep -v "INFO" server.log            # INFO가 없는 줄만 출력
cat server.log | grep ERROR | wc -l  # 파이프로 연결
grep ERROR server.log > errors.txt   # 결과를 파일로 저장
```

파이프(`|`)는 앞 명령의 출력을 뒤 명령의 입력으로 넘겨주는 것이다.

### 셸 스크립트 연습

- `var.sh` : 변수와 `$(date +%Y%m%d)`로 날짜가 들어간 파일명을 만든다. 변수에서 `=` 양옆에 공백이 있으면 안 된다.
- `greet.sh` : 인자가 없으면 사용법을 보여주고 `exit 1`로 끝난다. `echo $?`로 확인하면 실패는 1, 성공은 0이 나온다.
- `check.sh` : `-f`로 파일인지, `-d`로 디렉터리인지 검사한다.

### 백업 스크립트

`backup.sh`는 폴더를 `날짜_PID.tar.gz`로 압축해서 `backups/`에 보관한다.
백업 후 압축을 풀어서 `diff -rq`로 비교했을 때 `echo $?`가 0이면 원본과 같다는 뜻이다.

```bash
./backup.sh test
tar -xzf "$ARCHIVE" -C restore-check
diff -rq test restore-check/test
echo $?    # 0
```

백업 결과물은 Git에 올릴 필요가 없어서 `.gitignore`에 `week04/backups/`, `week04/restore-check/`를 추가했다.

### 프로세스

프로그램은 디스크에 있는 코드이고, 프로세스는 실행 중인 프로그램이다.
`ps aux`로 PID를 확인하고 `kill`로 종료했다. `kill`은 정상 종료를 요청하고, `kill -9`는 강제로 종료한다.

### Git 협업

main 브랜치에서 바로 작업하지 않고 브랜치를 만들어 작업한 뒤 PR로 합쳤다.

```bash
git switch -c feature/backup-log
git add week04/backup.sh
git commit -m "feat: 백업 로그 기록 기능 추가"
git push -u origin feature/backup-log
gh pr create --title "백업 로그 기록 기능 추가" --base main
gh pr merge --squash --delete-branch
```

- PR #1 : 백업이 끝나면 `backup.log`에 시간과 파일명을 기록하는 기능을 추가했다.
- PR #2 : main과 `fix/message` 브랜치에서 같은 줄을 다르게 고쳐서 일부러 Conflict를 만들었다.

Conflict가 나면 파일에 아래처럼 표시된다.

```text
<<<<<<< HEAD
echo "[완료] 로그 기록"
=======
echo "로그 기록"
>>>>>>> origin/main
```

`<<<<<<<`, `=======`, `>>>>>>>` 줄을 지우고 남길 내용만 남긴 다음 다시 커밋, 푸시하니 merge가 됐다.
Git이 고장 난 게 아니라 어떤 내용을 남길지 사람이 정하라는 뜻이라는 걸 알게 됐다.

### 네트워크

- IP : 네트워크에서 컴퓨터를 찾는 주소
- 포트 : 한 컴퓨터 안에서 어떤 서비스인지 구분하는 번호 (22 SSH, 80 HTTP, 443 HTTPS)
- DNS : 도메인 이름을 IP 주소로 바꿔주는 것

```bash
hostname -I                   # 내 IP
dig cs.inhatc.ac.kr +short    # 도메인의 IP
curl -I http://localhost:8080 # 응답 코드 확인
ss -tlnp | grep 8080          # 8080 포트를 쓰는 프로세스
```

### 포트 충돌

`python3 -m http.server 8080`을 켜 둔 상태에서 다른 터미널에서 같은 포트로 서버를 띄우면
`OSError: [Errno 98] Address already in use` 에러가 난다.
다른 포트를 쓰거나, `ss -tlnp`로 PID를 찾아서 `kill`하면 해결된다.

## 3. 파일 구성

```
week04/
├── README.md
├── backup.sh        # 백업 로그 기록 (PR #1, #2)
└── test/
    ├── backup.sh    # 백업 스크립트
    ├── server.log   # 실습용 로그
    ├── errors.txt   # ERROR만 저장한 결과
    ├── diary.txt
    ├── var.sh
    ├── greet.sh
    └── check.sh
```

## 4. 느낀 점

스크립트로 한 번 만들어 두면 같은 작업을 반복할 때 편하다는 걸 느꼈다.
Conflict는 처음에 당황했지만, 표시를 보고 직접 고르면 되는 거라서 생각보다 어렵지 않았다.
