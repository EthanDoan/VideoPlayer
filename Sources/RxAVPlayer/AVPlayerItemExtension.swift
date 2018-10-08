import AVFoundation
import RxSwift

extension AVPlayerItemStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .readyToPlay: return "readyToPlay"
        case .failed: return "failed"
        }
    }
}

extension Reactive where Base: AVPlayerItem {
    var status: Observable<AVPlayerItemStatus> {
        return observe(AVPlayerItemStatus.self, "status").filterNil()
    }

    var seekableTimeRanges: Observable<[NSValue]> {
        return observe([NSValue].self, "seekableTimeRanges").filterNil()
    }

    var timedMetadata: Observable<[AVMetadataItem]> {
        return observe([AVMetadataItem].self, "timedMetadata").filterNil()
    }

    /// `AVPlayerItemStatus.failed`時に発火
    var errorStatus: Observable<PlayerItemError> {
        return status
            .filter { $0 == .failed }
            .map { [weak base] _ -> PlayerItemError in
                let events = base?.errorLog()?.events.map { PlayerItemError(event: $0) }

                if events?.contains(.notFound) == true { return .notFound }
                if events?.contains(.unavailable) == true { return .unavailable }

                return .unknown
            }
    }

    /// `AVPlayerItemStatus.failed` or `NSNotification.Name.AVPlayerItemFailedToPlayToEndTime` or `NSNotification.Name.AVPlayerItemPlaybackStalled` 時に発火
    func asAnyErrorObservable(with notification: NotificationCenter = .default) -> Observable<PlayerItemError> {
        let failedToPlay: Observable<PlayerItemError> = notification.rx.notification(.AVPlayerItemFailedToPlayToEndTime, object: base)
            .map { _ in .failedToPlayToEnd }

        let stalled: Observable<PlayerItemError> = notification.rx.notification(.AVPlayerItemPlaybackStalled, object: base)
            .map { _ in .stalled }

        return Observable.of(errorStatus, failedToPlay, stalled).merge()
    }

    func asEndTimeObervable(with notification: NotificationCenter = .default) -> Observable<Void> {
        return notification.rx.notification(.AVPlayerItemDidPlayToEndTime, object: base).map(void)
    }

    var preferredPeakBitRate: AnyObserver<Double> {
        return AnyObserver { [weak base] e in
            if let bitRate = e.element {
                base?.preferredPeakBitRate = bitRate
            }
        }
    }
}
