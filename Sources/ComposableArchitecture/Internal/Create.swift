#if canImport(Combine)
import Foundation
import Combine
import Darwin

extension AnyPublisher {

    private init(_ callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable) {
        self = Publishers.Create(callback: callback).eraseToAnyPublisher()
    }
    
    static func create(
        _ factory: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable
    ) -> AnyPublisher<Output, Failure> {
        AnyPublisher(factory)
    }
}

extension Publishers {
    fileprivate class Create<Output, Failure: Swift.Error>: Publisher {
        
        private let callback: (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable
        
        init(callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable) {
            self.callback = callback
        }
        
        func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
            subscriber.receive(subscription: Subscription(callback: callback, downstream: subscriber))
        }
    }
}

extension Publishers.Create {
    
    fileprivate class Subscription<Downstream: Subscriber>: Combine.Subscription
    where Output == Downstream.Input, Failure == Downstream.Failure {
        private let buffer: DemandBuffer<Downstream>
        private var cancellable: Cancellable?
        
        init(
            callback: @escaping (AnyPublisher<Output, Failure>.Subscriber) -> Cancellable,
            downstream: Downstream
        ) {
            self.buffer = DemandBuffer(subscriber: downstream)
            let cancellable = callback(
                .init(
                    send: { [weak self] in _ = self?.buffer.buffer(value: $0) },
                    complete: { [weak self] in self?.buffer.complete(completion: $0) }
                )
            )
            self.cancellable = cancellable
        }
        
        func request(_ demand: Subscribers.Demand) {
            _ = self.buffer.demand(demand)
        }
        
        func cancel() {
            self.cancellable?.cancel()
        }
    }
}

extension Publishers.Create.Subscription: CustomStringConvertible {
    var description: String {
        return "Create.Subscription<\(Output.self), \(Failure.self)>"
    }
}

extension AnyPublisher {
    public struct Subscriber {
        private let _send: (Output) -> Void
        private let _complete: (Subscribers.Completion<Failure>) -> Void
        
        init(
            send: @escaping (Output) -> Void,
            complete: @escaping (Subscribers.Completion<Failure>) -> Void
        ) {
            self._send = send
            self._complete = complete
        }
        
        public func send(_ value: Output) {
            self._send(value)
        }
        
        public func send(completion: Subscribers.Completion<Failure>) {
            self._complete(completion)
        }
    }
}
#endif
