# ☸️ Week 09 — 내 노트북 위의 쿠버네티스

> **한 줄 요약**: `docker compose`는 컴퓨터 1대까지, 쿠버네티스는 "몇 개가 떠 있어야 하는지"만 말해 두면 알아서 맞춰 준다.

| 항목 | 내용 |
|---|---|
| 작업 환경 | WSL (Ubuntu) · 호스트명 `jhs` |
| 클러스터 도구 | **minikube** (driver=docker) |
| 배포한 이미지 | `ghcr.io/hyeonseo03/guestbook:v1` |
| 핵심 키워드 | 선언형 · 조정 루프 · Pod · Deployment · 자가 치유 |

---

## 🧭 오늘의 흐름

```
① 설치          ② 첫 Pod           ③ 자가 치유              ④ 내 이미지
kubectl    →   kubectl run    →   create deployment   →   guestbook:v1
minikube       (지우면 끝)         (지워도 다시 생김)        port-forward 8080:5000
```

---

## 1️⃣ 클러스터 준비 완료 — `kubectl get nodes`

minikube로 노드 1대짜리 클러스터를 만들고, `STATUS`가 **Ready**인 것을 확인했다.

![get nodes](images/01-get-nodes.png)

- kubectl = 리모컨, minikube = TV → 둘 다 있어야 화면이 나온다
- `kubectl config current-context` 결과가 `minikube`인지 먼저 확인하는 습관

---

## 2️⃣ 지워도 다시 태어나는 Pod — `kubectl get pods -w`

`--replicas=3`으로 Deployment를 만든 뒤, 한 Pod를 직접 삭제했다.
"살려라"라는 명령은 하지 않았는데 **새 이름의 Pod**가 `Pending → ContainerCreating → Running` 으로 올라왔다.

![self healing](images/02-self-healing.png)

| 비교 | `kubectl run` | `kubectl create deployment` |
|---|---|---|
| Pod 삭제 시 | 그대로 사라짐 | 새 Pod 생성 |
| 개수 유지 | ❌ | ✅ (ReplicaSet이 감시) |

> 💡 새 Pod는 "되살린" 게 아니라 "새로 만든" 것 → 이름 끝 5글자가 다르다.
> 그래서 Pod 안에 저장한 데이터는 함께 사라진다.

---

## 3️⃣ 내 방명록, 쿠버네티스 위에서 실행

6주차에 GHCR에 올린 이미지를 그대로 Deployment로 띄우고 `port-forward`로 접속했다.

```bash
kubectl create deployment guestbook --image=ghcr.io/hyeonseo03/guestbook:v1
kubectl port-forward deployment/guestbook 8080:5000
```

![guestbook on k8s](images/03-guestbook.png)

- 화면의 **Pod/Host** 배지 = 실제로 응답한 Pod 이름 (`kubectl get pods` 결과와 일치)
- Pod를 지우면 Pod는 다시 생기지만 **port-forward 연결과 메모리 데이터는 복구되지 않음** → 다음 주 Service에서 해결

---

## 🗣️ 선언형, 내 말로 정리

> "**어떻게** 하라고 하나하나 시키는 게 아니라 **어떤 상태**여야 하는지만 정해 두면, 시스템이 계속 확인하면서 맞춰 주는 방식.
> 보일러를 23도에 맞춰 두면 내가 껐다 켰다 안 해도 알아서 온도를 유지하는 것과 같다."

---

## 🧯 막혔던 점 & 해결

| 증상 | 원인 | 해결 |
|---|---|---|
| _(겪은 내용 작성)_ | _(원인)_ | _(해결 방법)_ |

> 문제가 생기면 `get pods` → `describe pod` (맨 아래 Events) → `logs` 순서로 확인

---

## 🧹 정리 명령

```bash
kubectl delete deployment guestbook
minikube stop   # 다음 주에 minikube start
```
