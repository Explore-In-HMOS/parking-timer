import { ParkingRecord, ParkingStatistics } from '../models/ParkingRecord'
import { StorageService, AppSettings } from '../services/StorageService'

@Observed
export class ParkingViewModel {
  @Track selectedHour: number = 0
  @Track selectedMinute: number = 30
  @Track isTimerRunning: boolean = false
  @Track remainingTime: number = 0
  @Track startTime: Date | null = null
  @Track endTime: Date | null = null
  
  @Track hourlyRate: number = 0
  @Track estimatedCost: number = 0
  
  @Track parkingHistory: ParkingRecord[] = []
  @Track statistics: ParkingStatistics | null = null
  @Track isLoadingHistory: boolean = false
  
  @Track showHistory: boolean = false
  @Track errorMessage: string = ''
  @Track successMessage: string = ''
  
  private storageService: StorageService
  private timerInterval: number = -1
  
  @Track settings: AppSettings = {}

  constructor() {
    this.storageService = StorageService.getInstance()
  }

  async initialize(context: Context): Promise<void> {
    try {
      await this.storageService.initialize(context)
      this.settings = await this.storageService.getSettings()
      
      if (this.settings.defaultHourlyRate) {
        this.hourlyRate = this.settings.defaultHourlyRate
      }
      
      await this.loadParkingHistory()
      console.info('ParkingViewModel initialized')
    } catch (error) {
      console.error('Failed to initialize ViewModel:', error)
      this.setError('Initialization failed')
    }
  }

  async startTimer(): Promise<void> {
    try {
      const totalMinutes = this.selectedHour * 60 + this.selectedMinute
      
      if (totalMinutes <= 0) {
        this.setError('Please select a valid duration')
        return
      }

      this.startTime = new Date()
      this.endTime = new Date(this.startTime.getTime() + totalMinutes * 60000)
      this.remainingTime = totalMinutes * 60 // in seconds
      this.isTimerRunning = true
      this.calculateEstimatedCost()
      
      this.timerInterval = setInterval(() => {
        this.updateTimer()
      }, 1000)

      this.setSuccess('Parking timer started!')
      console.info('Timer started:', { totalMinutes, endTime: this.endTime })
    } catch (error) {
      console.error('Failed to start timer:', error)
      this.setError('Failed to start timer')
    }
  }

  async stopTimer(): Promise<void> {
    try {
      if (!this.isTimerRunning || !this.startTime || !this.endTime) {
        return
      }

      clearInterval(this.timerInterval)

      const endTimestamp = Date.now()
      const startTimestamp = this.startTime.getTime()
      const actualDuration = Math.floor((endTimestamp - startTimestamp) / 60000)

      const record = new ParkingRecord(
        startTimestamp,
        endTimestamp,
        actualDuration,
        this.hourlyRate > 0 ? this.hourlyRate : undefined
      )

      await this.storageService.saveParkingRecord(record)
      await this.loadParkingHistory()

      this.resetTimer()
      this.setSuccess('Parking session saved!')

      console.info('Parking record saved:', record)
    } catch (error) {
      console.error('Failed to stop timer:', error)
      this.setError('Failed to save parking session')
    }
  }

  private updateTimer(): void {
    if (this.remainingTime > 0) {
      this.remainingTime--
    } else {
      this.stopTimer()
    }
  }

  resetTimer(): void {
    clearInterval(this.timerInterval)
    this.isTimerRunning = false
    this.remainingTime = 0
    this.startTime = null
    this.endTime = null
  }

  calculateEstimatedCost(): void {
    if (this.hourlyRate > 0) {
      const totalMinutes = this.selectedHour * 60 + this.selectedMinute
      this.estimatedCost = (totalMinutes / 60) * this.hourlyRate
    } else {
      this.estimatedCost = 0
    }
  }

  setHourlyRate(rate: number): void {
    this.hourlyRate = Math.max(0, rate)
    this.calculateEstimatedCost()
    
    this.settings.defaultHourlyRate = this.hourlyRate
    this.storageService.saveSettings(this.settings)
  }

  async loadParkingHistory(): Promise<void> {
    try {
      this.isLoadingHistory = true
      this.parkingHistory = await this.storageService.getAllRecords()
      this.statistics = ParkingStatistics.calculate(this.parkingHistory)
      console.info('History loaded:', this.parkingHistory.length, 'records')
    } catch (error) {
      console.error('Failed to load history:', error)
      this.setError('Failed to load history')
    } finally {
      this.isLoadingHistory = false
    }
  }

  async deleteRecord(id: string): Promise<void> {
    try {
      const success = await this.storageService.deleteRecord(id)
      if (success) {
        await this.loadParkingHistory()
        this.setSuccess('Record deleted')
      } else {
        this.setError('Failed to delete record')
      }
    } catch (error) {
      console.error('Delete error:', error)
      this.setError('Failed to delete record')
    }
  }

  toggleHistory(): void {
    this.showHistory = !this.showHistory
  }

  formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    const secs = seconds % 60
    
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }

  formatDuration(minutes: number): string {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    
    if (hours > 0) {
      return `${hours}h ${mins}m`
    }
    return `${mins}m`
  }

  formatCurrency(amount: number): string {
    const currency = this.settings.currency || '₺'
    return `${amount.toFixed(2)} ${currency}`
  }

  private setError(message: string): void {
    this.errorMessage = message
    this.successMessage = ''
    setTimeout(() => {
      this.errorMessage = ''
    }, 3000)
  }

  private setSuccess(message: string): void {
    this.successMessage = message
    this.errorMessage = ''
    setTimeout(() => {
      this.successMessage = ''
    }, 3000)
  }

  dispose(): void {
    clearInterval(this.timerInterval)
  }
}
