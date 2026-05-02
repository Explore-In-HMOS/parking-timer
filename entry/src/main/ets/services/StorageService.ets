import preferences from '@ohos.data.preferences'
import { ParkingRecord } from '../models/ParkingRecord'

export class StorageService {
  private static instance: StorageService
  private preferencesStore: preferences.Preferences | null = null
  private readonly STORE_NAME = 'parking_timer_db'
  private readonly KEY_RECORDS = 'parking_records'
  private readonly KEY_SETTINGS = 'app_settings'

  private constructor() {}

  static getInstance(): StorageService {
    if (!StorageService.instance) {
      StorageService.instance = new StorageService()
    }
    return StorageService.instance
  }

  async initialize(context: Context) {
    try {
      this.preferencesStore = await preferences.getPreferences(context, this.STORE_NAME)
      console.info('StorageService initialized successfully')
    } catch (error) {
      console.error('Failed to initialize storage:', error)
    }
  }

  async saveParkingRecord(record: ParkingRecord): Promise<boolean> {
    try {
      const records = await this.getAllRecords()
      records.push(record)

      const recordsJson = records.map(r => r.toJSON())
      await this.preferencesStore?.put(this.KEY_RECORDS, JSON.stringify(recordsJson))
      await this.preferencesStore?.flush()

      console.info('Parking record saved:', record.id)
      return true
    } catch (error) {
      console.error('Failed to save parking record:', error)
      return false
    }
  }

  async getAllRecords(): Promise<ParkingRecord[]> {
    try {
      const recordsStr = await this.preferencesStore?.get(this.KEY_RECORDS, '[]') as string
      const recordsJson = JSON.parse(recordsStr) as string[]

      return recordsJson.map(jsonStr => ParkingRecord.fromJSON(jsonStr))
    } catch (error) {
      console.error('Failed to get records:', error)
      return []
    }
  }

  async getRecords(limit: number = 50, offset: number = 0): Promise<ParkingRecord[]> {
    try {
      const allRecords = await this.getAllRecords()
      allRecords.sort((a, b) => b.startTime.getTime() - a.startTime.getTime())
      return allRecords.slice(offset, offset + limit)
    } catch (error) {
      console.error('Failed to get paginated records:', error)
      return []
    }
  }

  async getRecordById(id: string): Promise<ParkingRecord | null> {
    try {
      const records = await this.getAllRecords()
      return records.find(r => r.id === id) || null
    } catch (error) {
      console.error('Failed to get record by ID:', error)
      return null
    }
  }

  async updateRecord(record: ParkingRecord): Promise<boolean> {
    try {
      const records = await this.getAllRecords()
      const index = records.findIndex(r => r.id === record.id)

      if (index === -1) {
        console.error('Record not found:', record.id)
        return false
      }

      records[index] = record
      const recordsJson = records.map(r => r.toJSON())
      await this.preferencesStore?.put(this.KEY_RECORDS, JSON.stringify(recordsJson))
      await this.preferencesStore?.flush()

      return true
    } catch (error) {
      console.error('Failed to update record:', error)
      return false
    }
  }

  async deleteRecord(id: string): Promise<boolean> {
    try {
      const records = await this.getAllRecords()
      const filteredRecords = records.filter(r => r.id !== id)

      const recordsJson = filteredRecords.map(r => r.toJSON())
      await this.preferencesStore?.put(this.KEY_RECORDS, JSON.stringify(recordsJson))
      await this.preferencesStore?.flush()

      return true
    } catch (error) {
      console.error('Failed to delete record:', error)
      return false
    }
  }

  async getRecordsByDateRange(startDate: Date, endDate: Date): Promise<ParkingRecord[]> {
    try {
      const allRecords = await this.getAllRecords()
      return allRecords.filter(record =>
      record.startTime >= startDate && record.startTime <= endDate
      ).sort((a, b) => b.startTime.getTime() - a.startTime.getTime())
    } catch (error) {
      console.error('Failed to search records:', error)
      return []
    }
  }

  async saveSettings(settings: AppSettings): Promise<boolean> {
    try {
      await this.preferencesStore?.put(this.KEY_SETTINGS, JSON.stringify(settings))
      await this.preferencesStore?.flush()
      return true
    } catch (error) {
      console.error('Failed to save settings:', error)
      return false
    }
  }

  async getSettings(): Promise<AppSettings> {
    try {
      const settingsStr = await this.preferencesStore?.get(this.KEY_SETTINGS, '{}') as string
      const settings = JSON.parse(settingsStr) as AppSettings

      return {
        defaultHourlyRate: settings.defaultHourlyRate || 0,
        notificationMinutesBefore: settings.notificationMinutesBefore || 5,
        currency: settings.currency || '₺'
      }
    } catch (error) {
      console.error('Failed to get settings:', error)
      return {
        defaultHourlyRate: 0,
        notificationMinutesBefore: 5,
        currency: '₺'
      }
    }
  }

  async clearAllData(): Promise<boolean> {
    try {
      await this.preferencesStore?.clear()
      await this.preferencesStore?.flush()
      return true
    } catch (error) {
      console.error('Failed to clear data:', error)
      return false
    }
  }
}

export interface AppSettings {
  defaultHourlyRate?: number
  notificationMinutesBefore?: number
  currency?: string
}
