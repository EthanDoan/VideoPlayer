import AVFoundation
import RxCocoa
import RxSwift

extension Reactive where Base: AVPlayer {

    /// - Note: `play()` or `pause()` and `rate = 1.0` or `rate = 0.0` are equivalent.
    /// - Note: But, `play()` end-up with `rate: 1.0` so be careful with that.
    ///     Basically, do not use `play()`.
    var setRate: AnyObserver<Float> {
        return AnyObserver { [weak base] e in
            if let element = e.element {
                base?.rate = element
            }
        }
    }

    var rate: Observable<Float> {
        return base.rx.observe(Float.self, "rate")
            .filterNil()
    }

    /// - Note: via `AVPlayer.addPeriodicTimeObserver`
    func periodicTime(for interval: CMTime, queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<CMTime> {
        return Observable.create { observer in
            let avTimeObserver = self.base.addPeriodicTimeObserver(forInterval: interval, queue: queue) { [observer] time  in
                observer.onNext(time)
            }

            return Disposables.create {
                self.base.removeTimeObserver(avTimeObserver)
            }
        }
    }

    var volume: AnyObserver<Float> {
        return AnyObserver { [weak base] e in
            if let element = e.element {
                base?.volume = element
            }
        }
    }
}