## 현재 문제 
- k get pod <loki-grafana-pod-이름> -n loki -o yaml
  - 이걸로 봤는데 
```bash
  - name: storage
    persistentVolumeClaim:
      claimName: grafana-pvc
      
   # 이미 이렇게 설정이 되어있는데 해당 파드에 접속해서 로그가 잘 쌓이는 지 보려고 했는데 못 찾았다
```
