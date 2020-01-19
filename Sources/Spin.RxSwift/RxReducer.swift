//
//  RxReducer.swift
//  
//
//  Created by Thibault Wittemberg on 2019-12-31.
//

import RxRelay
import RxSwift
import Spin_Swift

public struct RxReducer<State, Event>: Reducer {
    public typealias StateStream = Observable<State>
    public typealias EventStream = Observable<Event>
    public typealias Executer = ImmediateSchedulerType

    public let reducer: (StateStream.Value, EventStream.Value) -> StateStream.Value
    public let executer: Executer

    public init(reducer: @escaping (StateStream.Value, EventStream.Value) -> StateStream.Value,
                on executer: Executer = CurrentThreadScheduler.instance) {
        self.reducer = reducer
        self.executer = executer
    }

    public func apply(on initialState: StateStream.Value,
                      after feedback: @escaping (StateStream) -> EventStream) -> StateStream {
        return Observable<StateStream.Value>.deferred {
            let currentState = ReplaySubject<State>.create(bufferSize: 1)

            return feedback(currentState.asObservable())
                .catchError { _ in return .empty() }
                .observeOn(self.executer)
                .scan(initialState, accumulator: self.reducer)
                .startWith(initialState)
                .do(onNext: { currentState.onNext($0) })
        }
    }

    public func apply(on initialState: StateStream.Value,
                      after feedbacks: [(StateStream) -> EventStream]) -> StateStream {
        let feedback = { stateStream in
            return Observable.merge(feedbacks.map { $0(stateStream) })
        }

        return self.apply(on: initialState, after: feedback)
    }
}
