//
//  File.swift
//  
//
//  Created by Thibault Wittemberg on 2019-12-31.
//

import Combine
import Spin_Combine
import Spin_Swift
import XCTest

fileprivate enum StringAction {
    case append(String)
}

fileprivate struct SutSpin: SpinDefinition {

    let effectA: (String) -> AnyPublisher<StringAction, Never>
    let effectB: (String) -> AnyPublisher<StringAction, Never>
    let effectC: (String) -> AnyPublisher<StringAction, Never>
    let reducerFunction: (String, StringAction) -> String

    fileprivate var spin: CombineSpin<String> {
        CombineSpin(initialState: "initialState", reducer: DispatchQueueCombineReducer(reducer: reducerFunction)) {
            CombineFeedback(effect: effectA).execute(on: DispatchQueue.main.eraseToAnyScheduler())
            CombineFeedback(effect: effectB).execute(on: DispatchQueue.main.eraseToAnyScheduler())
            CombineFeedback(effect: effectC).execute(on: DispatchQueue.main.eraseToAnyScheduler())
        }
    }
}

final class CombineSpinIntegrationTests: XCTestCase {

    func test_multiple_feedbacks_produces_incremental_states_while_executed_on_default_executer() throws {

        // Given: an initial state, feedbacks and a reducer
        var counterA = 0
        let effectA = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterA += 1
            let counter = counterA
            return Just<StringAction>(.append("_a\(counter)")).eraseToAnyPublisher()
        }

        var counterB = 0
        let effectB = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterB += 1
            let counter = counterB
            return Just<StringAction>(.append("_b\(counter)")).eraseToAnyPublisher()
        }

        var counterC = 0
        let effectC = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterC += 1
            let counter = counterC
            return Just<StringAction>(.append("_c\(counter)")).eraseToAnyPublisher()
        }

        let reducerFunction = { (state: String, action: StringAction) -> String in
            switch action {
            case .append(let suffix):
                return state+suffix
            }
        }

        // When: spinning the feedbacks and the reducer on the default executer
        let recorder = Spinner
            .from(initialState: "initialState")
            .add(feedback: DispatchQueueCombineFeedback(effect: effectA))
            .add(feedback: DispatchQueueCombineFeedback(effect: effectB))
            .add(feedback: DispatchQueueCombineFeedback(effect: effectC))
            .reduce(with: CombineReducer(reducer: reducerFunction))
            .toReactiveStream()
            .output(in: (0...6))
            .record()

        let receivedElements = try wait(for: recorder.elements, timeout: 5)

        // Then: the states is constructed incrementally
        XCTAssertEqual(receivedElements, ["initialState",
                                          "initialState_a1",
                                          "initialState_a1_b1",
                                          "initialState_a1_b1_c1",
                                          "initialState_a1_b1_c1_a2",
                                          "initialState_a1_b1_c1_a2_b2",
                                          "initialState_a1_b1_c1_a2_b2_c2"])
    }

    func test_multiple_feedbacks_produces_incremental_states_while_executed_on_default_executer_using_declarative_syntax() throws {

        // Given: an initial state, feedbacks and a reducer
        var counterA = 0
        let effectA = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterA += 1
            let counter = counterA
            return Just<StringAction>(.append("_a\(counter)")).eraseToAnyPublisher()
        }

        var counterB = 0
        let effectB = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterB += 1
            let counter = counterB
            return Just<StringAction>(.append("_b\(counter)")).eraseToAnyPublisher()
        }

        var counterC = 0
        let effectC = { (state: String) -> AnyPublisher<StringAction, Never> in
            counterC += 1
            let counter = counterC
            return Just<StringAction>(.append("_c\(counter)")).eraseToAnyPublisher()
        }

        let reducerFunction = { (state: String, action: StringAction) -> String in
            switch action {
            case .append(let suffix):
                return state+suffix
            }
        }

        // When: spinning the feedbacks and the reducer on the default executer
        let recorder = SutSpin(effectA: effectA,
                               effectB: effectB,
                               effectC: effectC,
            reducerFunction: reducerFunction)
            .toReactiveStream()
            .output(in: (0...6))
            .record()

        let receivedElements = try wait(for: recorder.elements, timeout: 5)

        // Then: the states is constructed incrementally
        XCTAssertEqual(receivedElements, ["initialState",
                                          "initialState_a1",
                                          "initialState_a1_b1",
                                          "initialState_a1_b1_c1",
                                          "initialState_a1_b1_c1_a2",
                                          "initialState_a1_b1_c1_a2_b2",
                                          "initialState_a1_b1_c1_a2_b2_c2"])
    }
}