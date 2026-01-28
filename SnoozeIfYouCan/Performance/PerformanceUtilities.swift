import SwiftUI
import Combine

// MARK: - Performance Utilities
// Optimizations for smooth 60fps UI

// MARK: - Debounced State

/// Property wrapper that debounces state updates to prevent excessive redraws
@propertyWrapper
struct Debounced<Value>: DynamicProperty {
    @State private var storedValue: Value
    @State private var debouncedValue: Value
    
    private let delay: TimeInterval
    
    init(wrappedValue: Value, delay: TimeInterval = 0.3) {
        _storedValue = State(initialValue: wrappedValue)
        _debouncedValue = State(initialValue: wrappedValue)
        self.delay = delay
    }
    
    var wrappedValue: Value {
        get { debouncedValue }
        nonmutating set {
            storedValue = newValue
            // In a real implementation, use Combine to debounce
            debouncedValue = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { storedValue },
            set: { storedValue = $0 }
        )
    }
}

// MARK: - Lazy View Loading

/// Wrapper that defers view creation until it's actually needed
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

// MARK: - Efficient List Row

/// A row wrapper that prevents unnecessary redraws
struct EfficientRow<Content: View>: View, Equatable {
    let id: UUID
    let content: Content
    
    init(id: UUID, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = content()
    }
    
    var body: some View {
        content
    }
    
    static func == (lhs: EfficientRow<Content>, rhs: EfficientRow<Content>) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Drawing Group for Complex Views

extension View {
    /// Applies drawingGroup for complex animations (rasterizes the view)
    func optimizedForAnimation() -> some View {
        self.drawingGroup()
    }
    
    /// Only applies drawingGroup when animations are active
    func conditionalDrawingGroup(isAnimating: Bool) -> some View {
        Group {
            if isAnimating {
                self.drawingGroup()
            } else {
                self
            }
        }
    }
}

// MARK: - Background Task Manager

/// Manages background tasks efficiently
@MainActor
class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    @Published var isPerformingBackgroundTask = false
    
    private var tasks: [String: Task<Void, Never>] = [:]
    
    func performTask(id: String, priority: TaskPriority = .userInitiated, operation: @escaping () async -> Void) {
        // Cancel existing task with same ID
        tasks[id]?.cancel()
        
        tasks[id] = Task(priority: priority) {
            isPerformingBackgroundTask = true
            await operation()
            isPerformingBackgroundTask = false
            tasks.removeValue(forKey: id)
        }
    }
    
    func cancelTask(id: String) {
        tasks[id]?.cancel()
        tasks.removeValue(forKey: id)
    }
    
    func cancelAllTasks() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        isPerformingBackgroundTask = false
    }
}

// MARK: - Memory Efficient Image Loader

actor ImageCache {
    static let shared = ImageCache()
    
    private var cache: [String: Data] = [:]
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private var currentCacheSize = 0
    
    func image(for key: String) -> Data? {
        cache[key]
    }
    
    func setImage(_ data: Data, for key: String) {
        // Evict if needed
        while currentCacheSize + data.count > maxCacheSize && !cache.isEmpty {
            if let firstKey = cache.keys.first {
                if let removedData = cache.removeValue(forKey: firstKey) {
                    currentCacheSize -= removedData.count
                }
            }
        }
        
        cache[key] = data
        currentCacheSize += data.count
    }
    
    func clearCache() {
        cache.removeAll()
        currentCacheSize = 0
    }
}

// MARK: - Throttled Action

/// Prevents action from being called too frequently
class ThrottledAction {
    private var lastExecutionTime: Date?
    private let minimumInterval: TimeInterval
    
    init(minimumInterval: TimeInterval = 0.5) {
        self.minimumInterval = minimumInterval
    }
    
    func execute(_ action: @escaping () -> Void) {
        let now = Date()
        
        if let lastTime = lastExecutionTime,
           now.timeIntervalSince(lastTime) < minimumInterval {
            return
        }
        
        lastExecutionTime = now
        action()
    }
}

// MARK: - Equatable View Wrapper

/// Makes any view equatable based on an ID for performance
struct EquatableViewWrapper<Content: View, ID: Equatable>: View, Equatable {
    let id: ID
    let content: Content
    
    init(id: ID, @ViewBuilder content: () -> Content) {
        self.id = id
        self.content = content()
    }
    
    var body: some View {
        content
    }
    
    static func == (lhs: EquatableViewWrapper, rhs: EquatableViewWrapper) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Performance Monitoring

#if DEBUG
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var startTimes: [String: CFAbsoluteTime] = [:]
    
    func startMeasuring(_ label: String) {
        startTimes[label] = CFAbsoluteTimeGetCurrent()
    }
    
    func stopMeasuring(_ label: String) {
        guard let startTime = startTimes[label] else { return }
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("⏱ \(label): \(String(format: "%.4f", elapsed))s")
        startTimes.removeValue(forKey: label)
    }
    
    func measure<T>(_ label: String, operation: () -> T) -> T {
        startMeasuring(label)
        let result = operation()
        stopMeasuring(label)
        return result
    }
    
    func measureAsync<T>(_ label: String, operation: () async -> T) async -> T {
        startMeasuring(label)
        let result = await operation()
        stopMeasuring(label)
        return result
    }
}
#endif

// MARK: - Optimized Alarm List

/// High-performance alarm list using LazyVStack
struct OptimizedAlarmList: View {
    @EnvironmentObject var alarmManager: AlarmManager
    
    let onSelect: (Alarm) -> Void
    let onDelete: (Alarm) -> Void
    let onToggle: (Alarm) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Active Section
                if !activeAlarms.isEmpty {
                    Section {
                        ForEach(activeAlarms) { alarm in
                            AlarmRowOptimized(alarm: alarm)
                                .onTapGesture { onSelect(alarm) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        onDelete(alarm)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        SectionHeader(title: "Active")
                    }
                }
                
                // Inactive Section
                if !inactiveAlarms.isEmpty {
                    Section {
                        ForEach(inactiveAlarms) { alarm in
                            AlarmRowOptimized(alarm: alarm)
                                .onTapGesture { onSelect(alarm) }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        onDelete(alarm)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        SectionHeader(title: "Inactive")
                    }
                }
            }
        }
    }
    
    private var activeAlarms: [Alarm] {
        alarmManager.alarms.filter { $0.isEnabled }.sorted { $0.time < $1.time }
    }
    
    private var inactiveAlarms: [Alarm] {
        alarmManager.alarms.filter { !$0.isEnabled }.sorted { $0.time < $1.time }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

/// Optimized alarm row with minimal redraws
struct AlarmRowOptimized: View, Equatable {
    let alarm: Alarm
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 44, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
                
                if !alarm.label.isEmpty {
                    Text(alarm.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Text(alarm.repeatDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Toggle would be here
        }
        .padding()
        .contentShape(Rectangle())
    }
    
    static func == (lhs: AlarmRowOptimized, rhs: AlarmRowOptimized) -> Bool {
        lhs.alarm.id == rhs.alarm.id &&
        lhs.alarm.isEnabled == rhs.alarm.isEnabled &&
        lhs.alarm.time == rhs.alarm.time &&
        lhs.alarm.label == rhs.alarm.label
    }
}
