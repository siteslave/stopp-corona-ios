//
//  BatchDownloadScheduler.swift
//  CoronaContact
//

import BackgroundTasks
import Foundation

final class BatchDownloadScheduler {
    struct Timing {
        private let startDate: Date
        private let endDate: Date
        private let dateInterval: DateInterval
        private let datesToSchedule: [Date]

        init() {
            startDate = Calendar.current.date(
                bySettingHour: BatchDownloadConfiguration.Scheduler.startTime.hour,
                minute: BatchDownloadConfiguration.Scheduler.startTime.minute,
                second: 0,
                of: Date()
            )!
            endDate = Calendar.current.date(
                bySettingHour: BatchDownloadConfiguration.Scheduler.endTime.hour,
                minute: BatchDownloadConfiguration.Scheduler.endTime.minute,
                second: 0,
                of: Date()
            )!
            dateInterval = DateInterval(start: startDate, end: endDate)
            datesToSchedule = dateInterval.divide(
                by: .hour,
                value: BatchDownloadConfiguration.Scheduler.intervalInHours
            )
        }

        func unscheduledDates(for taskRequests: [BGTaskRequest]) -> [Date] {
            let scheduledDates = taskRequests.compactMap(\.earliestBeginDate)

            return datesToSchedule.filter { !scheduledDates.contains($0) }
        }

        func nextDateToSchedule(for taskRequests: [BGTaskRequest]) -> Date? {
            let unscheduledDates = self.unscheduledDates(for: taskRequests)
            let now = Date()

            return unscheduledDates.first { $0 > now }
        }
    }

    weak var exposureManager: ExposureManager?

    private let log = ContextLogger(context: .batchDownload)
    private let batchDownloadService = BatchDownloadService()
    private let backgroundTaskIdentifier = Bundle.main.bundleIdentifier! + ".exposure-notification"
    private let backgroundTaskScheduler = BGTaskScheduler.shared
    private let timing = Timing()

    func registerBackgroundTask() {
        backgroundTaskScheduler.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: .main) { task in
            let progress = self.batchDownloadService.startBatchDownload(.all) { result in
                switch result {
                case .success:
                    task.setTaskCompleted(success: true)
                case .failure:
                    task.setTaskCompleted(success: false)
                }
            }

            // Handle running out of time
            task.expirationHandler = {
                progress.cancel()
            }

            // Schedule the next background task
            self.scheduleBackgroundTaskIfNeeded()
        }

        scheduleBackgroundTaskIfNeeded()
    }

    func scheduleBackgroundTaskIfNeeded() {
        guard exposureManager?.authorizationStatus == .authorized else {
            return
        }

        backgroundTaskScheduler.getPendingTaskRequests { pendingRequests in
            guard pendingRequests.count == 0 else {
                return
            }

            if let nextScheduledDate = self.timing.nextDateToSchedule(for: pendingRequests) {
                self.scheduleBackgroundTask(at: nextScheduledDate)
            }
        }
    }

    private func scheduleBackgroundTask(at date: Date) {
        let taskRequest = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        taskRequest.earliestBeginDate = date

        do {
            try backgroundTaskScheduler.submit(taskRequest)
            log.debug("Background task at date \(date) scheduled: \(backgroundTaskIdentifier)")
        } catch {
            log.error("Unable to schedule background task: \(error)")
        }
    }
}

private extension DateInterval {
    func divide(by component: Calendar.Component, value divisor: Int) -> [Date] {
        var dates: [Date] = [start]

        var previousDate = start
        while let nextDate = Calendar.current.date(byAdding: component, value: divisor, to: previousDate),
            contains(nextDate) {
            dates.append(nextDate)
            previousDate = nextDate
        }

        return dates
    }
}
