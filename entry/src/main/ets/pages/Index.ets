import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct ParkingTimer {
  @State isParking: boolean = false;
  @State startTime: number = 0;
  @State elapsedTime: string = '00:00:00';
  @State reminderMinutes: number = 120;
  private timer: number = -1;

  aboutToDisappear() {
    if (this.timer !== -1) {
      clearInterval(this.timer);
    }
  }

  formatTime(seconds: number): string {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    const hf = h.toString().padStart(2, '0');
    const mf = m.toString().padStart(2, '0');
    const sf = s.toString().padStart(2, '0');
    return `${hf}:${mf}:${sf}`;
  }

  startParking() {
    this.isParking = true;
    this.startTime = Date.now();

    this.timer = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
      this.elapsedTime = this.formatTime(elapsed);
    }, 1000);

    this.setReminder();
  }

  stopParking() {
    this.isParking = false;
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
    this.elapsedTime = '00:00:00';
    notificationManager.cancel(1)
  }

  async setReminder() {
    try {
      this.getPermission(this.getUIContext().getHostContext() as common.UIAbilityContext)
      const notificationRequest: notificationManager.NotificationRequest = {
        id: 1,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Parking Time Over!',
            text: `${this.reminderMinutes} minutes have passed. Check your vehicle.`
          }
        },
        deliveryTime: Date.now() + (this.reminderMinutes * 60 * 1000)
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

  build() {
    Column() {
      Text('Parking Timer')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 12, bottom: 10 })

      Column() {
        Text(this.elapsedTime)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isParking ? '#00CC88' : '#999999')
          .margin({ bottom: 3 })

        Text(this.isParking ? 'Parking Time' : 'Ready')
          .fontSize(11)
          .fontColor('#AAAAAA')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 12 })

      if (!this.isParking) {
        Column() {
          Text('Reminder')
            .fontSize(10)
            .fontColor('#AAAAAA')
            .margin({ bottom: 8 })

          Row() {
            Button('-')
              .width(40)
              .height(40)
              .backgroundColor('#333333')
              .borderRadius(20)
              .onClick(() => {
                if (this.reminderMinutes > 30) {
                  this.reminderMinutes -= 30;
                }
              })

            Text(`${this.reminderMinutes} min`)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ left: 15, right: 15 })
              .width(70)
              .textAlign(TextAlign.Center)

            Button('+')
              .width(40)
              .height(40)
              .backgroundColor('#333333')
              .borderRadius(20)
              .onClick(() => {
                if (this.reminderMinutes < 480) {
                  this.reminderMinutes += 30;
                }
              })
          }
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 15 })
        }
      }

      Button(this.isParking ? 'Stop' : 'Start')
        .width('75%')
        .height(38)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .backgroundColor(this.isParking ? '#FF5555' : '#00CC88')
        .fontColor('#FFFFFF')
        .onClick(() => {
          if (this.isParking) {
            this.stopParking();
          } else {
            this.startParking();
          }
        })
    }
    .width('100%')
    .height('233vp')
    .backgroundColor('#1A1A1A')
    .padding({
      left: 15,
      right: 15,
      top: 10,
      bottom: 10
    })
  }
}