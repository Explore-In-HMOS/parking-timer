interface ParkingRecordData {
  id: string
  startTime: string
  endTime: string
  duration: number
  hourlyRate?: number
  totalCost?: number
  notes?: string
  photoPath?: string
}

export class ParkingRecord {
  id: string
  startTime: Date
  endTime: Date
  duration: number
  hourlyRate?: number
  totalCost?: number
  notes?: string
  photoPath?: string

  constructor(
    startTime: Date | number,
    endTime: Date | number,
    duration: number,
    hourlyRate?: number,
    notes?: string,
    photoPath?: string
  ) {
    this.id = `${Date.now()}`
    this.startTime = typeof startTime === 'number' ? new Date(startTime) : startTime
    this.endTime = typeof endTime === 'number' ? new Date(endTime) : endTime

    this.duration = duration
    this.hourlyRate = hourlyRate
    this.totalCost = hourlyRate ? this.calculateCost(duration, hourlyRate) : undefined
    this.notes = notes
    this.photoPath = photoPath
  }

  private calculateCost(duration: number, hourlyRate: number): number {
    return (duration / 60) * hourlyRate
  }

  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      startTime: this.startTime.toISOString(),
      endTime: this.endTime.toISOString(),
      duration: this.duration,
      hourlyRate: this.hourlyRate,
      totalCost: this.totalCost,
      notes: this.notes,
      photoPath: this.photoPath
    })
  }

  static fromJSON(json: string): ParkingRecord {
    const data = JSON.parse(json) as ParkingRecordData

    const record = new ParkingRecord(
      new Date(data.startTime),
      new Date(data.endTime),
      data.duration,
      data.hourlyRate,
      data.notes,
      data.photoPath
    )
    record.id = data.id
    return record
  }
}

export class ParkingStatistics {
  totalSessions: number = 0
  totalDuration: number = 0
  totalCost: number = 0
  averageDuration: number = 0
  averageCost: number = 0

  static calculate(records: ParkingRecord[]): ParkingStatistics {
    const stats = new ParkingStatistics()

    if (records.length === 0) {
      return stats
    }

    stats.totalSessions = records.length

    records.forEach(record => {
      stats.totalDuration += record.duration
      if (record.totalCost) {
        stats.totalCost += record.totalCost
      }
    })

    stats.averageDuration = stats.totalDuration / stats.totalSessions
    const recordsWithCost = records.filter(r => r.totalCost !== undefined)
    stats.averageCost = recordsWithCost.length > 0
      ? stats.totalCost / recordsWithCost.length
      : 0

    return stats
  }
}
