# BugreportAnalyzer

Android bugreport automatic analysis. Android bugreport自动化分析

# Usage

Automatically extract and parse bugreport.zip to obtain key information such as WakeLock, Job, Alarm, runtime, and power consumption rate, and output a summary report. Based on the testcase, output the test results. 自动解压bugreport.zip并解析，取得关键的WakeLock、Job、Alarm、运行时间、耗电速度，输出简报，基于testcase输出测试结果

```
./bugreportanalyzer PATH_TO_BUGREPORT.zip
```

# testcase

- reporter/default.testcase: Define the criteria for a test to pass. 定义测试通过的标准

If the corresponding analysis result (left of the colon) is greater than the value (right of the colon), the test result is FAILED. Otherwise, it is PASS.
对应的分析结果（冒号左边）大于值（冒号右边）时，测试结果为FAILED，否则为PASS

```
BATTERY_TOTALPARTIAL_ELAPSEDPCT:20
BATTERY_RUNNINGPCT:20
BATTERY_DRAINRATE:0.3
```
# Sample

```
cat example/example_output_1.txt
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
ANALYZER_PATH_BUGREPORT         = /mnt/tmp/bugreport.zip
ANALYZER_PATH_DUMPFILE          = output/_mnt_tmp_bugreport/bugreport-V1-QP1A.190711.020-2023-06-06-09-27-11.txt
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
Test Result: [FAILED]
        Failed item(s):
                Item                            Target/Current
                BATTERY_TOTALPARTIAL_ELAPSEDPCT  20/98[failed]
                BATTERY_RUNNINGPCT               20/100[failed]
                BATTERY_DRAINRATE                0.3/3.80[failed]
        Test case:
                Item                            Target
                BATTERY_TOTALPARTIAL_ELAPSEDPCT <= 20
                BATTERY_RUNNINGPCT              <= 20
                BATTERY_DRAINRATE               <= 0.3
^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
[  App Alarm history:
        Package                                         UID     Total
        com.android.providers.calendar                  10040   13h5m4s472ms
        com.sohu.inputmethod.sogouoem                   10097   9h28m18s985ms
        com.tencent.android.qqdownloader                10116   3s291ms
        com.baidu.netdisk                               10117   14m52s124ms
]
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
BATTERY_DISCHARGEDCOUNT         = 46
BATTERY_ELAPSEDTIME_FORMATTED   = 12h6m2s742ms
BATTERY_ELAPSEDTIME             = 43562
BATTERY_UPTIME_FORMATTED        = 12h6m2s739ms
BATTERY_UPTIME                  = 43562
BATTERY_TOTALPARTIAL_FORMATTED  = 11h58m0s620ms
BATTERY_TOTALPARTIAL            = 43080
BATTERY_TOTALPARTIAL_ELAPSEDPCT = 98
BATTERY_TOTALPARTIAL_UPTIMEPCT  = 98
BATTERY_RUNNINGPCT              = 100
BATTERY_DRAINRATE               = 3.80
[  Total Wake:
        Package                                         UID     Total
        android                                         1000    3m20s260ms
        com.tencent.android.qqdownloader                u0a116  11h58m0s174ms
        com.baidu.netdisk                               u0a117  1s229ms
        com.alibaba.android.rimet                       u0a119  20m52s971ms
        com.tencent.wemeet.app                          u0a121  1s696ms
]
[  Battery Alarm History:
        Name                                                                                    Seconds     Time        Counts
         com.tencent.android.qqdownloader.action.SCHEDULE_JOB_IN_DAEMON                         1271        21m11s      1
         com.android.server.action.NETWORK_STATS_POLL                                            32626       9h3m46s     48
         com.android.server.action.NETWORK_STATS_POLL                                            32626       9h3m46s     48
         com.baidu.action.SOFIRE.VIEW                                                            25457       7h4m17s     24
         com.baidu.action.SOFIRE.VIEW                                                            25457       7h4m17s     24
         com.tencent.android.qqdownloader.action.SCHEDULE_JOB_IN_DAEMON                          186         3m6s        1
         com.tencent.android.qqdownloader.action.SCHEDULE_JOB                                    186         3m6s        1
         DeviceIdleController.light                                                             315151      3d15h32m31s 78
         DeviceIdleController.light                                                             315151      3d15h32m31s 78
         com.tencent.halley.action.HEART_BEAT                                                   5932        1h38m52s    1
         com.baidu.techain.x18.al.alv.act                                                        100390      1d3h53m10s  22
         com.baidu.techain.x18.al.alv.act                                                        100390      1d3h53m10s  22
         TIME_TICK                                                                               86552       1d2m32s     126
         WifiConnectivityManagerSchedulePeriodicScanTimer                                       0           0           60
         ScheduleConditionProvider.EVALUATE                                                     0           0           4
         JSidleness                                                                             0           0           2
         *job.deadline*                                                                         0           0           2
         HEART_BEAT                                                                             0           0           2
         DhcpClient.wlan0.RENEW                                                                 0           0           2
         com.baidu.netdisk.action.updata_statistics                                             0           0           4
         AlarmTaskSchedule.com.shusheng.JoJoRead                                                0           0           8
         sogou.action.statisticsdata.onedayup                                                    -1          0           2
         GraphicsStatsService                                                                    0           0           2
         com.baidu.techain.x18.ACTION_HEARTBEAT                                                  -3          0           72
         com.baidu.netdisk.action.MATCH_CONTACTS                                                 -1          0           2
         com.baidu.action.Techain.VIEW                                                           0           0           2
         android.intent.action.DATE_CHANGED                                                      -1          0           2
]
[  Battery Job History:
        Name                                                                                    Seconds     Time        Counts
         android/com.android.server.net.watchlist.ReportWatchlistJobService                              0           0           4
         android/com.android.server.pm.DynamicCodeLoggingService                                         -1          0           2
         android/com.android.server.PruneInstantAppsJobService                                           0           0           2
         com.alibaba.android.rimet.syncadapter.provider/com.alibaba.android.rimet/dingtalk android       -1261       0           42
         com.baidu.netdisk/.service.NetdiskJobService                                                    -1          0           12
]
+ + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + + +
x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x
analyzer_exit
Unlinking output/_mnt_tmp_bugreport/bugreport-V1-QP1A.190711.020-2023-06-06-09-27-11.txt
x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x
```

