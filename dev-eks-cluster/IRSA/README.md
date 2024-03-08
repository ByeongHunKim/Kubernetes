- [reference](https://github.com/users/ByeongHunKim/projects/4?pane=issue&itemId=55648857)

- policy resource 허용 범위
  - 현재는 `*` 로 되어 있지만 `(asm-access-policy.json)`
  - 아래 사진처럼 가야한다
  ![img.png](asm-access-resource-policy.png)
  
- 올바르지 않은 것
  - /dbpasswd/dev
  - /dbpasswd/prod
    - 이렇게 가면 누가 누구건 지 잘 모른다
- 올바른 것
  - /dev/point/dbpasswd

- resource에 `*` 가 아니라 `프로젝트도메인/~~` 으로 권한을 준다