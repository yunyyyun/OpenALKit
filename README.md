# OpenALKit
在iOS里使用OpenAL播放声音的一种方式，如果你觉得AVAudioPlayer和SystemSound都不好用，辣么OpenAL可能是你的最佳选择。

使用步骤：

* 添加将要播放的音源（mp3格式，其他格式也行，不过需要改代码）
* 修改宏，设置音源个数,添加数组索引：：

```
#define MAX_BUFFER_COUNT        4. //OpenALPlayer.m (11)
```
 
```
gSourceFile = [[NSArray alloc] initWithObjects:
                   @"flyup",@"hit",@"gg",@"start",nil];  // //OpenALPlayer.m (129)
```
* 播放：

```
[[OpenALPlayer shared] doPlayWithTag:tag];
```

demo例子简陋，更多声效设置可见OpenALPlayer.m，谢谢！
