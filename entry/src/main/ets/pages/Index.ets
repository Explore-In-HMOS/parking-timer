import { ParkingViewModel } from '../viewmodels/ParkingViewModel'
import { ParkingRecord } from '../models/ParkingRecord'
import { notificationManager } from '@kit.NotificationKit'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

@Entry
@Component
struct Index {
  @State viewModel: ParkingViewModel = new ParkingViewModel()
  @State currentTab: number = 0

  async setReminder() {
    try {
      this.getPermission(this.getUIContext().getHostContext() as common.UIAbilityContext)
      const notificationRequest: notificationManager.NotificationRequest = {
        id: 1,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Parking Time Over!',
            text: `${this.viewModel.selectedHour} minutes have passed. Check your vehicle.`
          }
        },
        deliveryTime: Date.now() + (this.viewModel.selectedHour * 60 * 1000)
      };

      await notificationManager.publish(notificationRequest);
      console.info('Reminder set successfully');
    } catch (err) {
      console.error('Failed to set reminder:', JSON.stringify(err));
    }
  }

  async getPermission(context: common.UIAbilityContext): Promise<void> {

    const TAG: string = '[PublishOperation]';
    const DOMAIN_NUMBER: number = 0xFF00; //
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      if (!data) {
        notificationManager.requestEnableNotification(context).then(() => {
          hilog.info(DOMAIN_NUMBER, TAG, `[ANS] requestEnableNotification success`);
        }).catch((err: BusinessError) => {
          if (1600004 === err.code) {
            hilog.error(DOMAIN_NUMBER, TAG,
              `[ANS] requestEnableNotification refused, code is ${err.code}, message is ${err.message}`);
          } else {
            hilog.error(DOMAIN_NUMBER, TAG,
              `[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
          }
        });
      }
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN_NUMBER, TAG, `isNotificationEnabled fail, code is ${err.code}, message is ${err.message}`);
    });
  }

  aboutToAppear(): void {
    let context = this.getUIContext().getHostContext()
    if (context !== undefined) {
      this.viewModel.initialize(context)
    }
  }

  aboutToDisappear(): void {
    this.viewModel.dispose()
  }

  @State currentIndex: number = 0;

  @Builder
  tabBuilder(title: ResourceStr, targetIndex: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
      Divider()
        .width('87%')
        .height(1)
        .margin(2)
        .color(this.currentIndex === targetIndex ? '#1698CE' : '#6B6B6B')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Scroll() {
      Column() {
        this.TopBar()

        Tabs({ index: this.currentTab }) {
          TabContent() {
            this.TimerTab()
          }
          .tabBar(this.tabBuilder('Timer', 0))

          TabContent() {
            this.HistoryTab()
          }
          .tabBar(this.tabBuilder('History', 1))

          TabContent() {
            this.StatisticsTab()
          }
          .tabBar(this.tabBuilder('Stats', 2))
        }
        .onChange((index: number) => {
          this.currentTab = index
          this.currentIndex = index
        })
        .width('100%')
        .height('100%')
        .backgroundColor('#121212')
      }
    }.width('100%')
    .height('100%')
  }

  @Builder
  TopBar() {
    Column() {
      Text('Parking Timer')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ top: 12 })

      Blank()

      if (this.viewModel.isTimerRunning) {
        Row() {
          Circle({ width: 6, height: 6 })
            .fill(Color.Green)
          Text('Active')
            .fontSize(10)
            .fontColor('#4CAF50')
        }.margin(2)
      }
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#1E1E1E')
    .shadow({ radius: 2, color: '#00000085' })
  }

  @Builder
  TimerTab() {
    Scroll() {
      Column({ space: 6 }) {
        // Messages
        if (this.viewModel.errorMessage) {
          this.MessageBanner(this.viewModel.errorMessage, '#F44336')
        }
        if (this.viewModel.successMessage) {
          this.MessageBanner(this.viewModel.successMessage, '#4CAF50')
        }

        // Timer Display
        this.TimerDisplay()

        // Cost Calculator
        if (!this.viewModel.isTimerRunning) {
          this.CostCalculator()
        }

        // Time Selector
        if (!this.viewModel.isTimerRunning) {
          this.TimeSelector()
        }

        // Control Buttons
        this.ControlButtons()

        // Current Parking Info
        if (this.viewModel.isTimerRunning) {
          this.CurrentParkingInfo()
        }
      }
      .width('100%')
      .padding({ bottom: 16, right: 16, left: 16 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MessageBanner(message: string, color: string) {
    Row() {
      Text(message)
        .fontSize(12)
        .fontColor(Color.White)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(color)
    .borderRadius(8)
    .animation({ duration: 300 })
  }

  @Builder
  TimerDisplay() {
    Column({ space: 6 }) {
      if (this.viewModel.isTimerRunning) {
        Text('Time Remaining')
          .fontSize(14)
          .fontColor('#666666')

        Text(this.viewModel.formatTime(this.viewModel.remainingTime))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2196F3')
          .fontFamily('monospace')

        Progress({
          value: this.viewModel.remainingTime,
          total: (this.viewModel.selectedHour * 60 + this.viewModel.selectedMinute) * 60,
          type: ProgressType.Linear
        })
          .width('100%')
          .color('#2196F3')
      } else {
        Text('Set Parking Duration')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
    }
    .width('100%')
    .padding(12)
    .borderRadius(16)
    .backgroundColor('#1E1E1E')
    .shadow({ radius: 4, color: '#00000010' })
  }

  @Builder
  CostCalculator() {
    Column({ space: 3 }) {
      Text('💰 Cost Calculator')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Row({ space: 4 }) {
        Text('Hourly Rate:')
          .fontSize(12)
          .fontColor('#666666')

        TextInput({ placeholder: '0.00' })
          .type(InputType.Number)
          .fontSize(12)
          .placeholderFont({ size: 12 })
          .borderRadius(8)
          .padding(8)
          .height(30)
          .layoutWeight(1)
          .defaultFocus(false)
          .onChange((value: string) => {
            const rate = parseFloat(value) || 0
            this.viewModel.setHourlyRate(rate)
          })

        Text(this.viewModel.settings?.currency || '₺')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')

      if (this.viewModel.estimatedCost > 0) {
        Divider()
          .color('#EEEEEE')

        Row() {
          Text('Estimated Cost:')
            .fontSize(12)
            .fontColor('#666666')

          Blank()

          Text(this.viewModel.formatCurrency(this.viewModel.estimatedCost))
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor('#1E1E1E')
  }

  @Builder
  TimeSelector() {
    Column({ space: 6 }) {
      Text('⏱️ Duration')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Row({ space: 8 }) {
        Column({ space: 2 }) {
          Text('Hours')
            .fontSize(10)
            .fontColor('#999999')

          Counter() {
            Text(this.viewModel.selectedHour.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
          }
          .onInc(() => {
            if (this.viewModel.selectedHour < 23) {
              this.viewModel.selectedHour++
              this.viewModel.calculateEstimatedCost()
            }
          })
          .onDec(() => {
            if (this.viewModel.selectedHour > 0) {
              this.viewModel.selectedHour--
              this.viewModel.calculateEstimatedCost()
            }
          })
        }
        .layoutWeight(1)

        Column({ space: 2 }) {
          Text('Minutes')
            .fontSize(10)
            .fontColor('#999999')

          Counter() {
            Text(this.viewModel.selectedMinute.toString())
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
          }
          .onInc(() => {
            if (this.viewModel.selectedMinute < 59) {
              this.viewModel.selectedMinute++
              this.viewModel.calculateEstimatedCost()
            }
          })
          .onDec(() => {
            if (this.viewModel.selectedMinute > 0) {
              this.viewModel.selectedMinute--
              this.viewModel.calculateEstimatedCost()
            }
          })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor('#1E1E1E')
  }

  @Builder
  ControlButtons() {
    Row({ space: 6 }) {
      if (this.viewModel.isTimerRunning) {
        Button('Stop Parking')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#F44336')
          .borderRadius(12)
          .width('70%')
          .height(32)
          .onClick(() => {
            this.viewModel.stopTimer()
          })
      } else {
        Button('Start Parking')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#4CAF50')
          .borderRadius(12)
          .height(32)
          .width('70%')
          .onClick(() => {
            this.viewModel.startTimer()
            this.setReminder()
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CurrentParkingInfo() {
    Column({ space: 6 }) {
      Text('Current Session')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      Row() {
        Column({ space: 2 }) {
          Text('Started')
            .fontSize(10)
            .fontColor('#999999')
          Text(this.viewModel.startTime?.toLocaleTimeString() || '-')
            .fontSize(12)
            .fontColor('#333333')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column({ space: 2 }) {
          Text('Ends at')
            .fontSize(10)
            .fontColor('#999999')
          Text(this.viewModel.endTime?.toLocaleTimeString() || '-')
            .fontSize(12)
            .fontColor('#333333')
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      if (this.viewModel.hourlyRate > 0) {
        Divider().color('#EEEEEE')

        Row() {
          Text('Current Cost')
            .fontSize(10)
            .fontColor('#999999')

          Blank()

          Text(this.viewModel.formatCurrency(
            ((this.viewModel.selectedHour * 60 + this.viewModel.selectedMinute - this.viewModel.remainingTime / 60) /
              60) *
            this.viewModel.hourlyRate
          ))
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1E1E1E')
    .borderRadius(12)
  }

  @Builder
  HistoryTab() {
    Column() {
      if (this.viewModel.isLoadingHistory) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('Loading history...')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.viewModel.parkingHistory.length === 0) {
        Column({ space: 6 }) {
          Text('🚗')
            .fontSize(30)
          Text('No parking history yet')
            .fontSize(14)
            .fontColor('#999999')
          Text('Start your first parking session!')
            .fontSize(12)
            .fontColor('#CCCCCC')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 6 }) {
          ForEach(this.viewModel.parkingHistory, (record: ParkingRecord) => {
            ListItem() {
              this.HistoryItem(record)
            }
          }, (record: ParkingRecord) => record.id)
        }
        .width('100%')
        .height('100%')
        .padding({ bottom: 16, right: 16, left: 16, top: 4  })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1E1E1E')
  }

  @Builder
  HistoryItem(record: ParkingRecord) {

    Row() {
      Column({ space: 2 }) {
        Text(record.startTime.toLocaleDateString())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        Text(record.startTime.toLocaleTimeString())
          .fontSize(10)
          .fontColor('#999999')
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Column({ space: 2 }) {
        Text(this.viewModel.formatDuration(record.duration))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2196F3')
        if (record.totalCost) {
          Text(this.viewModel.formatCurrency(record.totalCost))
            .fontSize(10)
            .fontColor('#4CAF50')
        }
      }
      .alignItems(HorizontalAlign.End)

      Blank()

      Button('Delete')
        .fontSize(10)
        .height(30)
        .backgroundColor('#FFEBEE')
        .fontColor('#F44336')
        .borderRadius(20)
        .padding(4)
        .onClick(() => {
          this.viewModel.deleteRecord(record.id)
        })

    }
    .width('100%')
    .padding(10)
    .borderRadius(12)
    .backgroundColor('#cb000000')
  }

  @Builder
  StatisticsTab() {
    if (this.viewModel.statistics && this.viewModel.statistics.totalSessions > 0) {
      Scroll() {
        Column({ space: 8 }) {
          Row({ space: 4 }) {
            this.StatCard('Total Sessions', this.viewModel.statistics.totalSessions.toString(), '🚗')
            this.StatCard('Total Time', this.viewModel.formatDuration(this.viewModel.statistics.totalDuration), '⏱️')
          }
          .width('100%')

          Row({ space: 4 }) {
            this.StatCard('Total Cost', this.viewModel.formatCurrency(this.viewModel.statistics.totalCost), '💰')
            this.StatCard('Avg Duration',
              this.viewModel.formatDuration(Math.floor(this.viewModel.statistics.averageDuration)), '📊')
          }
          .width('100%')
        }
        .width('90%')
        .padding({ bottom: 16, right: 16, left: 16, top: 4 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#1E1E1E')
    } else {
      Column({ space: 6 }) {
        Text('📊')
          .fontSize(26)
        Text('No statistics yet')
          .fontSize(14)
          .fontColor('#999999')
        Text('Park your car to see statistics')
          .fontSize(12)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#1E1E1E')
    }
  }

  @Builder
  StatCard(title: string, value: string, icon: string) {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(20)
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2196F3')
      Text(title)
        .fontSize(8)
        .fontColor('#999999')
    }
    .width('100%')
    .layoutWeight(1)
    .padding(16)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#cb000000')
  }
}