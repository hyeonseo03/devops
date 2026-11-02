#!/bin/bash
# web 컨테이너를 항상 3개로 유지하는 스크립트
cd "$(dirname "$0")" || exit 1

DESIRED=3
P="label=com.docker.compose.project=guestbook"
S="label=com.docker.compose.service=web"

while true; do
  # 1) 실행 중인 web 개수 세기
  COUNT=$(docker ps -q --filter "$P" --filter "$S" \
          --filter "status=running" | wc -l)

  # 2) 떠 있지만 응답 없는 web은 재시작
  BAD=$(docker ps -q --filter "$P" --filter "$S" \
        --filter "health=unhealthy")
  if [ -n "$BAD" ]; then docker restart $BAD; fi

  # 3) 모자라면 다시 3개로 맞추기
  if [ "$COUNT" -lt "$DESIRED" ]; then
    echo "$(date '+%H:%M:%S') web ${COUNT}개 -> ${DESIRED}개로 복구"
    docker compose up -d --scale web=$DESIRED
  fi
  sleep 5
done
