worked after moving the `.app` to the Applications folder and running it once. Then running:
```shell
qlmanage -r cache
qlmanage -r
killall -9 Finder
killall -9 mdworker_shared
```
